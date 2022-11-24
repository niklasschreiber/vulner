# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    KEY_PREFIX_FOGLIA = 'a'.freeze
    KEY_PREFIX_CONTENITORE = 'c'.freeze

    #
    class TipoAttivita < Model(:tipi_attivita) # rubocop:disable Metrics/ClassLength
      unrestrict_primary_key
      plugin :timestamps, update_on_create: true
      validates_constant :stato
      plugin :single_table_inheritance, :kind

      # Rimuove tutte le attivita collegate ad attivita schedulate che hanno tipo_attivita_id uguale a quello del TipoAttivita
      # e data di creazione minore di obsolete_date
      def rimuovi_attivita_obsolete(obsolete_date, &_block)
        n = 0
        Attivita.where(pid: nil, attivita_schedulata_id: AttivitaSchedulata.where(tipo_attivita_id: id).select_map(:id)).each do |att_root|
          next unless att_root.created_at < obsolete_date
          yield(att_root) if block_given?
          att_root.destroy
          n += 1
        end
        n
      end

      # -- Utility -----------------
      def self.omc_fisico?
        @omc_fisico ? true : false
      end

      def self.foglia_last_index(res)
        a = [0]
        (res || []).each do |xxx|
          key = (xxx || {})['key']
          a << key[KEY_PREFIX_FOGLIA.size..-1].to_i if key.start_with?(KEY_PREFIX_FOGLIA)
        end
        a.max
      end

      # lista_sistemi_obj e' un array di array, dove il primo elemento di ogni subarray e' un oggetto
      # che risponde al metodo 'id'
      # [[S1],[S2],[S3],...[Sn]] oppure [[S1,x,...],[S2,x,...],[S3,x,...],...[Sn,x,...]], dove Sj e' un oggetto con metodo 'id'

      # ritorna [S1.id.to_s, S2.id.to_s,...,Sn.id.to_s]
      def self.lista_id_da_lista_sistemi(lista_sistemi_obj)
        lista_sistemi_obj.map { |el| el[0].id.to_s }
      end

      # ritorna lo stesso array con gli oggetti sostituiti dall'id
      def self.lista_obj_to_id(lista_sistemi_obj)
        res = []
        lista_sistemi_obj.each do |el|
          x = el
          x[0] = el[0].id
          res << x if x[0]
        end
        res
      end

      # lista_sistemi_id e' un array di array, dove il primo elemento di ogni subarray e' un intero
      # che corrisponde ad un id di un model di tipo 'classe'
      # ritorna lo stesso array con ogni id sostituito dal relativo oggetto se esiste
      def self.lista_id_to_obj(lista_id, classe)
        res = []
        (lista_id || []).each do |el|
          x = el
          obj = classe.where(id: el[0].to_i)
          if obj
            x[0] = obj.first
            res << x
            # else
            # log... TODO: tracciare il fatto che non ho trovato un id non corrisponde a nessun oggetto
          end
          res
        end
      end

      def self.lista_sistemi_id_to_obj(lista_id)
        lista_id_to_obj(lista_id, omc_fisico? ? Irma::Db::OmcFisico : Irma::Db::Sistema)
      end

      def self.competenze_lista_obj(lista_sistemi)
        tipo_comp = lista_sistemi.first[0].tipo_competenza
        comp = lista_id_da_lista_sistemi(lista_sistemi)
        { tipo_comp => comp }
      end

      def self.lista_progetti_irma_id_to_obj(lista_id)
        lista_id_to_obj(lista_id, Irma::Db::ProgettoIrma)
      end

      def self.competenze_lista_progetti_irma(lista_pi)
        res = {}
        lista_pi.each do |pi_a|
          pi = pi_a[0]
          (res[pi.tipo_competenza] ||= []) << (pi.sistema_id || pi.omc_fisico_id).to_s
        end
        res
      end

      def self.competenze_lista_report_comparativi(lista_rc)
        res = {}
        lista_rc.each do |rc_a|
          rc = rc_a[0]
          (res[rc.tipo_competenza] ||= []) << (rc.sistema_id || rc.omc_fisico_id).to_s
        end
        res.each { |k, v| res[k] = v.uniq } # tolgo i doppioni
        res
      end

      def self.lista_report_comparativi_id_to_obj(lista_id)
        lista_id_to_obj(lista_id, Irma::Db::ReportComparativo)
      end

      #-----------------------------------------------------
      # foglie

      def self.get_info_comando(comando, parametri_comando: {}, info: {})  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        res = []
        bad_command_opts = []
        comm = Command.commands[comando]
        command_opts = comm.options.keys.map(&:to_s)
        res << comm.name
        parametri_comando.each do |k, v|
          if command_opts.include?(k.to_s)
            res << "--#{k}"
            res << v
          else
            bad_command_opts += [k.to_s, v]
          end
        end
        unless bad_command_opts.empty?
          # ATTENZIONE: il seguente evento verra' creato due volte a causa dell'invocazione del metodo crea_foglia_info_attivita
          #             sia nel metodo AttivitaSchedulata.aggiorna_competenze (al momento della creazione dell'attivita' schedulata)
          #             che AttivitaSchedulata.crea_gerarchia_attivita (al momento dell'esecuzione da parte dello scheduler)
          msg = "Attivita #{info['label']}, opzioni non supportate dal comando #{comando}: #{bad_command_opts.inspect}"
          Db::Evento.crea(TIPO_EVENTO_ATTIVITA_OPZIONI_NON_SUPPORTATE_DAL_COMANDO, descr: msg)
        end
        res
      end

      def self.crea_foglia_info_attivita(key, comando, parametri_comando:, info:)
        foglia = {}
        ic = Constant.info(:comando, comando)
        foglia['key'] = key
        foglia['label'] = info['label'] || format_msg(ic[:msg_attivita], info.symbolize_keys)
        foglia['pid'] = info['key_pid'] || ATTIVITA_ROOT_KEY
        foglia['dipende_da'] = info['dipende_da'] || []
        %w(expire_sec artifacts competenze account_id utente_id profilo_id).each do |k|
          foglia[k] = info[k] if info[k]
        end
        foglia['info_comando'] = get_info_comando(ic[:command], parametri_comando: parametri_comando, info: foglia)
        foglia
      end
      #-----------------------------------------------------
      # contenitore

      def self._crea_contenitore_info_attivita(key, label, opts = {})
        contenitore = { 'key' => key, 'label' => label }
        contenitore['pid'] = opts['key_pid'] if opts['key_pid']
        %w(expire_sec artifacts competenze account_id utente_id profilo_id).each do |k|
          contenitore[k] = opts[k] if opts[k]
        end
        contenitore
      end
      #-----------------------------------------------------
      # root

      def self.crea_root_info_attivita(opts = {})
        _crea_contenitore_info_attivita(ATTIVITA_ROOT_KEY, opts['label'] || format_msg(self::LABEL_ROOT), opts)
      end

      def self.crea_contenitore_info_attivita(key = ATTIVITA_ROOT_KEY, label = nil, opts = {})
        key ||= ATTIVITA_ROOT_KEY
        (key == ATTIVITA_ROOT_KEY) ? crea_root_info_attivita(opts.merge('label' => label)) : _crea_contenitore_info_attivita(key, label, { 'key_pid' => ATTIVITA_ROOT_KEY }.merge(opts))
      end

      def self.cerca_contenitore(res:, key: ATTIVITA_ROOT_KEY)
        res.find { |x| x['key'] == key }
      end

      #-----------------------------------------------------
      # info_attivita

      def self.info_attivita(_opts)
        raise NotImplementedError, "info_attivita non implementata per la classe #{self}"
      end

      def self.get_info_attivita(val, opts = {})
        ia = []
        begin
          classe = Db.class_eval(Constant.info(:tipo_attivita, val)[:kind])
        rescue => e
          raise "Classe TipoAttivita' con id #{val} non esiste (#{e})"
        end
        begin
          ia = classe.send(:info_attivita, opts)
        rescue => e
          raise "Errore nella chiamata del metodo #{classe}.info_attivita: #{e}, #{e.backtrace}"
        end
        ia
      end

      #-----------------------------------------------------
      # attivita schedulata da info_attivita

      def self.crea_attivita_schedulata(tipo_attivita, opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        options = opts.stringify_keys
        options.delete('info_attivita')
        # ia ||= get_info_attivita(tipo_attivita, options || {})
        ta = tipo_attivita.is_a?(self) ? tipo_attivita : get_by_pk(tipo_attivita)

        # competenze, account_id, utente_id, profilo_id, info_attivita, periodo, inizio_validita, fine_validita
        account_opts = {}
        if options['no_account']
          options.delete('account_id')
        else
          raise 'Account id non specificato per l\'attivita\' schedulata' unless options['account_id']
          account = Account.first(id: options['account_id'])
          raise 'Richiesta creazione di attivita schedulata con account non esistente' unless account
          account_opts = { 'account_id' => account.id, 'utente_id' => account.utente_id, 'profilo_id' => account.profilo_id, 'ambiente' => account.ambiente }
        end

        AttivitaSchedulata.transaction do
          as = AttivitaSchedulata.create(account_opts.merge(
            'id'                 => options['attivita_schedulata_id'] || AttivitaSchedulata.next_id,
            'tipo_attivita_id'   => ta.id,
            'periodo'            => '',
            'opts_info_attivita' => options,
            'inizio_validita'    => Time.now,
            'descr'              => ta.nome
          ).merge(options.select { |k, _v| AttivitaSchedulata.columns.include?(k.to_sym) }))
          as.aggiorna_competenze(options)
          as
        end
      end

      def self.aggiungi_opzioni_per_account(opts:, profilo: nil)
        unless opts['account_id'] && opts['account_id'] != -1
          profilo ||= opts[:ambiente] == AMBIENTE_QUAL ? PROFILO_RQ : PROFILO_RPN
          account = Db::Account.qualsiasi(profilo: profilo)
          raise "Nessun account con profilo #{profilo} e competenza su tutti i sistemi" unless account
          opts['account_id'] = account.id
          opts['utente_id']  = account.utente_id
          opts['profilo_id'] = account.profilo_id
        end
        opts
      end

      def self.seleziona_opzioni_per_account(opts)
        opts.select { |k, _v| %w(account_id utente_id profilo_id).include?(k) }
      end
    end
  end
end

Dir[File.join(__dir__, 'tipo_attivita/*.rb')].each { |f| require f }

# == Schema Information
#
# Tabella: tipi_attivita
#
#  broadcast  :boolean         non nullo, default(false)
#  created_at :datetime
#  descr      :string          default('')
#  id         :integer         non nullo, chiave primaria
#  kind       :string
#  nome       :string(128)     non nullo
#  singleton  :boolean         non nullo, default(false)
#  stato      :string(32)      default('attivo')
#  updated_at :datetime
#
# Indici:
#
#  uidx_tipo_attivita_kind  (kind) UNIQUE
#
