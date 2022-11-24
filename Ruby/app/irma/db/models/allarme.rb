# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    #
    class Allarme < Model(:allarmi) # rubocop:disable Metrics/ClassLength
      plugin :timestamps, update_on_create: true

      many_to_one :tipo_allarme, class: full_class_for_model(:TipoAllarme)

      class InvalidEventId < IrmaException; end
      class TipoAllarmeNonValido < IrmaException; end

      attr_accessor :original_in_carico, :original_contatore

      validates_constant :gravita
      validates_constant :in_carico

      MANDATORY_ATTRIBUTES = %i(categoria nome gravita id_risorsa tipo_allarme_id).freeze

      def before_update
        # do not allow change for the categoria,nome,gravita,id_risorsa
        old_alarm = self.class.first(id: id)
        MANDATORY_ATTRIBUTES.each do |k|
          raise "No change allowed for alarm key attribute :#{k} on alarm with id #{id}" if send(k) != old_alarm.send(k)
        end
        super
      end

      def self.get(id)
        al = first(id: id)
        al.update_original_flags unless al.nil?
        al
      end

      # Ritorna un'istanza di allarme cercata in base agli attributi
      #
      # == Eccezioni
      # * TipoAllarmeNonValido
      # * vedi TipoAllarme.build_id_risorsa
      #
      def self.find_by_tipo_allarme(ta, h = {}, ctx = {}, &block) # rubocop:disable Metrics/AbcSize
        attr = {}
        h.each { |k, v| attr[k.to_sym] = v if columns.member?(k.to_sym) }

        # always remove :id_risorsa attribute
        ta = ta.is_a?(TipoAllarme) ? ta : TipoAllarme.get_by_pk(ta)
        raise TipoAllarmeNonValido, "Tipo allarme con id '#{ta.inspect}' non definito nel db" if ta.nil?
        attr.update(categoria: ta.categoria, nome: ta.nome, gravita: ta.gravita, tipo_allarme_id: ta.id)

        attr[:id_risorsa] ||= ta.build_id_risorsa(attr.merge(ctx))

        al = first(['tipo_allarme_id = ? AND id_risorsa = ?', attr[:tipo_allarme_id], attr[:id_risorsa]])
        al.original_in_carico = al.in_carico if al
        al = yield(ta, al, attr) if block
        al
      end

      # Crea un nuovo allarme di tipo +ta+ utilizzando gli attributi definiti nell'hash +h+
      # Se l'allarme che deve essere creato (rispetto alla terna categoria,nome,id_risorsa) esiste gia'
      # allora viene aggiornato incremantanto l'attributo contatore.
      def self.apri(ta, h = {}, ctx = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        transaction do
          find_by_tipo_allarme(ta, h, ctx) do |_ta, al, attr|
            if al.nil?
              # NOT yet open, create it
              al = new(attr.merge(in_carico: ALLARME_IN_CARICO_NO))
              al.save
              logger.info("Nuovo allarme con id #{al.id}, #{al.categoria}:#{al.nome} per la risorsa #{al.id_risorsa}")
            else
              # yet open, update it
              update_attr = { contatore: al.contatore + 1 }
              update_attr[:descr] = attr[:descr] unless attr[:descr].nil?
              al.update(update_attr)
              logger.info("Aggiornato allarme con id #{al.id}, #{al.categoria}:#{al.nome} per la risorsa #{al.id_risorsa}, contatore #{al.contatore}, data creazione #{al.created_at}")
            end
            al.update_original_flags
            al
          end
        end
      end

      # Chiude un allarme, se l'allarme non e' aperto non fa nulla.
      def self.chiudi(ta, h = {}, ctx = {})
        closed_alarm = nil
        transaction do
          find_by_tipo_allarme(ta, h, ctx) { |_ta, al, _attr| closed_alarm = al.chiudi(h[:note_chiusura] || ctx[:note_chiusura]) unless al.nil? }
          closed_alarm
        end
      end

      # Esegue il codice del blocco +block+ e in base al risultato determina se aprire/aggiornare oppure chiudere l'eventuale
      # allarme di tipo +tipo_allarme+ utilizzando le opzioni +opzioni_allarme+.
      # Ritorna l'oggetto allarme aperto/aggiornato/chiuso.
      def self.valuta(tipo_allarme, opzioni_allarme = {})
        res = yield(opzioni_allarme)
        send((res ? :apri : :chiudi), tipo_allarme, opzioni_allarme, opzioni_allarme.dup)
      end

      # Prende in carico un allarme, aggiornando i vari attributi.
      def prendi_in_carico(h = {})
        options = { note_in_carico: nil, utente_in_carico: nil }.merge(h)
        # HACK: force update of in_carico to set status in :ack
        self.in_carico = nil
        update_original_flags
        # now, do the right update
        self.in_carico = ALLARME_IN_CARICO_SI
        self.note_in_carico = options[:note_in_carico] unless options[:note_in_carico].nil?
        self.utente_in_carico = options[:utente_in_carico] unless options[:utente_in_carico].nil?
        self.data_in_carico = Time.now
        save
        update_original_flags
        self
      end

      # Chiude un allarme, ritornando l'istanza dell'allarme chiuso (AllarmeChiuso) o nil se l'allarme non esiste.
      def chiudi(note_chiusura = nil) # rubocop:disable Metrics/AbcSize
        closed_alarm = nil
        transaction do
          logger.info("Chiusura allarme con id #{id}, #{categoria}:#{nome} per la risorsa #{id_risorsa}, contatore #{contatore}, data di creazione #{created_at}")
          begin
            closed_alarm = AllarmeChiuso.crea(attributes.merge(note_chiusura: prepara_note_di_chiusura(note_chiusura)))
            delete
          rescue => e
            logger.warn("Chiusura allarme con id #{id} fallita: #{e}")
            raise e if closed_alarm
          end
        end
        closed_alarm
      end

      # Rilascia un allarme aggiornando gli attributi corrispondenti. Se l'allarme non e' preso in carico non fa nulla.
      def rilascia(h = {})
        options = { note_in_carico: nil }.merge(h)
        if in_carico == ALLARME_IN_CARICO_SI
          self.in_carico = ALLARME_IN_CARICO_NO
          self.note_in_carico = options[:note_in_carico]
          self.data_in_carico = nil
          self.utente_in_carico = nil
          save
          update_original_flags
        end
        self
      end

      def update_original_flags
        @original_in_carico = in_carico
        @original_contatore = contatore
        self
      end

      def periodo_chiusura_automatica
        @periodo_chiusura_automatica ||= TipoAllarme.get_by_pk(tipo_allarme_id).chiusura_automatica
      end

      def scaduto?
        (periodo_chiusura_automatica > 0) && (Time.now > updated_at + periodo_chiusura_automatica)
      end

      def prepara_note_di_chiusura(note_chiusura)
        scaduto? ? format('Chiusura per scadenza periodo di chiusura automatica di %d secondi', periodo_chiusura_automatica) : note_chiusura
      end

      def self.chiusura_allarmi_scaduti(_hash = {}) # rubocop:disable Metrics/AbcSize
        res = { allarmi_chiusi: 0 }
        chiusura_automatica_ta = {}
        Irma::Constant.constants(:tipo_allarme).each { |c| chiusura_automatica_ta[c.value] = c.info[:chiusura_automatica] if (c.info[:chiusura_automatica] || 0) > 0 }
        unless chiusura_automatica_ta.keys.empty?
          where(tipo_allarme_id: chiusura_automatica_ta.keys).each do |al|
            if al.updated_at + chiusura_automatica_ta[al.tipo_allarme_id] <= Time.now
              al.chiudi('Chiuso automaticamente da attività di controllo periodica')
              res[:allarmi_chiusi] += 1
            end
          end
        end
        res
      end
    end
  end
end

# == Schema Information
#
# Tabella: allarmi
#
#  categoria        :string(64)      non nullo
#  contatore        :integer         non nullo, default(1)
#  created_at       :datetime
#  data_in_carico   :datetime
#  data_notifica    :datetime
#  descr            :string
#  gravita          :integer         non nullo
#  id               :bigint          non nullo, default(nextval('allarmi_id_seq')), chiave primaria
#  id_evento        :integer
#  id_risorsa       :string(64)      non nullo
#  in_carico        :integer         non nullo, default(0)
#  nome             :string(64)      non nullo
#  note_in_carico   :string
#  pid              :integer
#  tipo_allarme_id  :integer         riferimento a tipi_allarmi.id
#  updated_at       :datetime
#  user_fullname    :string(64)
#  user_funz        :string(32)
#  user_name        :string(32)
#  user_type        :string(1)       default('')
#  utente_in_carico :string(64)
#
# Indici:
#
#  uidx_allarmi_tipo_al_ris  (id_risorsa,tipo_allarme_id) UNIQUE
#
