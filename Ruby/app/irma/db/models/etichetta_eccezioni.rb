# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20181001
#

module Irma
  module Db
    #
    class EtichettaEccezioni < Model(:etichette_eccezioni) # rubocop:disable Metrics/ClassLength
      attr_accessor :cancellazione_da_cleanup
      plugin :timestamps, update_on_create: true
      configure_retention 7, use_orm_for_cleanup: true
      validates_constant :tipo

      def before_create
        self.nome = nome.strip
        super
        populate_info_creatore
        add_info_to_attributes
      end

      def before_update
        super
        add_info_to_attributes
      end

      def before_destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # TODO: vedere se possibile generare tutti i lock prima e non in cascata per evitare problemi con eventuali import
        Irma.lock(key: LOCK_KEY_ETICHETTA_ECCEZIONI, mode: LOCK_MODE_WRITE) do
          unless cancellazione_da_cleanup
            Sistema.each do |sistema|
              Sistema.transaction do
                (entita_label = sistema.entita(archivio: ARCHIVIO_LABEL).first).con_lock do
                  sistema.entita(archivio: ARCHIVIO_ECCEZIONI).first.con_lock do
                    entita_label.dataset.where(label: nome).update(label: LABEL_NC_DB)
                  end
                end
              end
            end
          end
          begin
            EtichettaEccezioniEliminata.create(attributes.merge(ended_at: Time.now))
          rescue => e
            logger.error("Unexpected error in creazione Etichetta Eccezioni Eliminata: #{e}")
          end
        end
        true
      end

      def add_info_to_attributes
        populate_info_autore
        populate_variazioni
      end

      def populate_info_creatore
        utente = Utente.get_by_pk(Account.first(id: account_id).utente_id)
        self.utente_creatore_descr = utente.fullname
        self.matricola_creatore = utente.matricola
      end

      def populate_info_autore
        account = Account.first(id: account_id)
        self.profilo = Profilo.get_by_pk(account.profilo_id).nome
        utente_obj = Utente.get_by_pk(account.utente_id)
        self.utente_descr = utente_obj.fullname
        self.matricola = utente_obj.matricola
      end

      def populate_variazioni
        self.variazioni ||= []
        self.variazioni << { updated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S'), **without_attributes(hash: variations, keys: [:updated_at, :variazioni]) }
      end

      def variations
        variations = {}
        changed_columns.each { |col| variations[col] = self[col] }
        variations
      end

      def without_attributes(hash:, keys:)
        new_hash = (hash || {}).dup
        keys.each { |k| new_hash.delete(k) if new_hash.include?(k) }
        new_hash
      end

      def self.label_utilizzate(un_sistema = nil)
        label_utilizzate = []
        (un_sistema.nil? ? Sistema : Sistema.where(id: un_sistema.id)).each do |sistema|
          label_utilizzate |= sistema.entita(archivio: ARCHIVIO_LABEL).first.dataset.distinct.select_map(:label)
        end
        label_utilizzate
      end

      def self.remove_records(limit_date, hash = {})
        super(limit_date, hash.merge(date_field: :data_ultimo_import, rebuild_indexes: true, label_utilizzate: label_utilizzate, extra_date_field: :updated_at))
      end

      def self.remove_obsolete_record(limit_date:, col:, **opts) # rubocop:disable Metrics/AbcSize
        query = where((Sequel[col] < limit_date) | (Sequel.or(col => nil) & (Sequel[opts[:extra_date_field]] < limit_date))).exclude(nome: opts[:label_utilizzate].compact)
        query.map do |record|
          record.cancellazione_da_cleanup = true
          record.destroy
        end.size
      end

      def self.labels_eccezioni_nette
        where(eccezioni_nette: true).select_map(:nome)
      end

      def self.load_hash_labels_nette
        res = {}
        labels_eccezioni_nette.each { |lll| res[lll] = true }
        res
      end

      def self.etichette_da_considerare(sistema: nil, filtro_etichette: nil, flag_nette: FILTRO_LABELS_TUTTE)
        labels_ecc_nette = labels_eccezioni_nette + [LABEL_NC_DB] # LABEL_NC_DB per 'senza_label'
        etichette = (filtro_etichette || []).empty? ? label_utilizzate(sistema) : filtro_etichette
        if flag_nette == FILTRO_LABELS_NETTE
          etichette & labels_ecc_nette
        elsif flag_nette == FILTRO_LABELS_NON_NETTE
          etichette - labels_ecc_nette
        else
          etichette
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: etichette_eccezioni
#
#  account_id            :integer         non nullo
#  created_at            :datetime
#  data_ultimo_import    :datetime
#  descr                 :string
#  eccezioni_nette       :boolean         non nullo, default(false)
#  ended_at              :datetime
#  id                    :bigint          non nullo, default(nextval('etichette_eccezioni_id_seq')), chiave primaria
#  matricola             :string(32)
#  matricola_creatore    :string(32)
#  nome                  :string(128)     non nullo
#  profilo               :string(32)
#  tipo                  :integer         non nullo
#  updated_at            :datetime
#  utente_creatore_descr :string(32)
#  utente_descr          :string(32)
#  variazioni            :json
#
# Indici:
#
#  uidx_etich_eccez_nome  (nome) UNIQUE
#
