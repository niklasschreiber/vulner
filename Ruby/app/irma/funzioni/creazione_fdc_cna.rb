# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20180725
#

require_relative 'segnalazioni_per_funzione'

#
module Irma
  module Funzioni
    class CreazioneFdcCna # rubocop:disable Metrics/ClassLength
      include SegnalazioniPerFunzione

      NULL_VAL = 'NULL'.freeze
      CNA_MO_PARAM_SEP = '__'.freeze

      Constant.define(:fdc_cna_prefix,
                      cell:  { value: 1, nome: 'CELL' },
                      ucell: { value: 2, nome: 'UCELL' },
                      fcell: { value: 3, nome: 'FCELL' }
                     )

      STATI_MO = [STATO_MO_INIT = 'init'.freeze, STATO_MO_FINAL = 'final'.freeze].freeze

      class ManagedObjectFdcCna < OpenStruct
        attr_reader :tipo_file
        attr_accessor :stato
        def initialize(me_header:, tipo_file:, init_dist_name: '', parametri: {})
          raise 'Intestazione non valida' if me_header.to_s == '' || me_header.empty?
          @me_header = me_header
          s = {}
          @me_header.each { |field| s[field] = NULL_VAL }
          super(s)
          add_elements(dn: init_dist_name, parametri: parametri)
          @tipo_file = tipo_file
          @stato = STATO_MO_INIT
        end

        def dist_name(meta_entita: nil)
          return NULL_VAL if meta_entita && !self[meta_entita]
          res = []
          @me_header.each do |me|
            res << "#{me}#{DIST_NAME_VALUE_SEP}#{self[me]}" unless self[me] == NULL_VAL
            break if me == meta_entita
          end
          res.join(DIST_NAME_SEP)
        end

        def add_elements(dn: '', parametri: {})
          (dn || '').split(DIST_NAME_SEP).each do |me_val|
            me, val = me_val.split(DIST_NAME_VALUE_SEP)
            self[me] = val if self[me] == NULL_VAL
          end
          return self if dn.empty?
          last_me = dn.split(DIST_NAME_SEP).last.split(DIST_NAME_VALUE_SEP).first
          (parametri || {}).each  { |k, v| self["#{last_me}#{CNA_MO_PARAM_SEP}#{k}"] = v unless @me_header.include?(k) } # TODO: da verificare con i parametri dell'header
          self
        end

        def get_parametri_entita(me: '', lista_mp: [])
          param_ret = {}
          return param_ret if me.empty? || lista_mp.empty?
          lista_mp.each do |meta_param|
            mp_key = "#{me}#{CNA_MO_PARAM_SEP}#{meta_param}"
            param_ret[meta_param] = self[mp_key] if self[mp_key]
          end
          param_ret
        end

        def riga_dati(header)
          actu_me = ''
          header.map do |meta_obj|
            if @me_header.include?(meta_obj)
              # caso entita
              actu_me = meta_obj
              self[meta_obj] || NULL_VAL
            else
              # caso parametri
              self["#{actu_me}#{CNA_MO_PARAM_SEP}#{meta_obj}"] || NULL_VAL
            end
          end
        end
      end # class ManagedObjectFdcCna

      class WriterFdcCna
        attr_reader :out_dir, :logger, :log_prefix,  :file, :create_time
        attr_reader :stat

        def initialize(**opts)
          @out_dir = opts[:out_dir]
          raise "#{self} inizialize: output directory '#{out_dir}' non esistente" unless File.directory?(out_dir)
          @modo_creazione  = opts[:modo_creazione]
          @formato         = opts[:formato]

          suffix = 'txt'
          @nomi_file = stabilisci_nomi_file(label: opts[:label_nome_file], suffix: suffix)
          #
          @writers = {}
          #
          @logger = opts[:logger] || Irma.logger
          @log_prefix = opts[:log_prefix]
        end

        def stabilisci_nomi_file(label:, suffix:)
          fixed = "#{label}.#{suffix}"
          nf = {}
          [FDC_CNA_PREFIX_FCELL, FDC_CNA_PREFIX_UCELL, FDC_CNA_PREFIX_CELL].each do |tipo|
            nf[tipo] = "#{Constant.info(:fdc_cna_prefix, tipo)[:nome]}_#{fixed}"
          end
          nf
        end

        def open(opts = {}, &_block)
          @writers = {}
          @nomi_file.each do |tipo, nome_file|
            file = File.join(out_dir, nome_file)
            @writers[tipo] = {
              fd:           File.open(file, 'w'),
              file:         file,
              create_time:  opts[:create_time] || Time.now,
              num_records:  0
            }
          end
          self
        rescue => e
          raise "WriterFdcCna error opening files: #{e}"
        end

        def close(_opts = {})
          @writers.keys.each do |k|
            begin
              v = @writers[k]
              next unless v && v[:fd]
              v[:fd].flush
              v[:fd].close
              v[:fd] = nil
            rescue => e
              e # ignore exception
            ensure
              @writers[k] = nil
            end
          end
        end

        def scrivi_riga(header:, mo:)
          @writers[mo.tipo_file][:fd].puts mo.riga_dati(header).join(TEXT_DATA_ROW_SEP)
          @writers[mo.tipo_file][:num_records] += 1
        end

        CNA_HEAD_SEP = '-'.freeze

        def scrivi_header(header:, tipo:)
          @writers[tipo][:fd].puts header.join(TEXT_DATA_ROW_SEP)
          @writers[tipo][:fd].puts CNA_HEAD_SEP * 50
          @writers[tipo][:num_records] += 2
        end
      end # class WriterFdcCna

      attr_accessor :actual_mo
      attr_reader :logger, :me_header, :header_file

      def initialize(sistema_ambiente_archivio:, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @saa                = sistema_ambiente_archivio
        @vendor_instance    = opts[:vendor_instance] || Vendor::EricssonGsm.new
        @writer_opts        = {
          out_dir:         opts[:out_dir],
          label_nome_file: opts[:label_nome_file] || Time.now.strftime('%Y%m%d-%H%M'),
          modo_creazione:  opts[:modo_creazione_fdc],
          formato:         opts[:formato_fdc]
        }
        @metamodello       = opts[:metamodello]
        @logger            = opts[:logger] || Irma.logger
        @log_prefix        = opts[:log_prefix] || "Creazione FdC CNA (#{@saa.full_descr})"
        @actual_mo         = nil
        @me_header         = { FDC_CNA_PREFIX_CELL => [], FDC_CNA_PREFIX_FCELL => [], FDC_CNA_PREFIX_UCELL => [] }
        @header_file       = { FDC_CNA_PREFIX_CELL => [], FDC_CNA_PREFIX_FCELL => [], FDC_CNA_PREFIX_UCELL => [] }
      end

      def con_writer
        cna_writer = nil
        cna_writer = WriterFdcCna.new(**@writer_opts)
        cna_writer.open
        yield cna_writer
      ensure
        cna_writer.close if cna_writer
      end

      META_ENTITA_HEADER_FDC = begin
                                 res = {
                                   FDC_CNA_PREFIX_UCELL => Vendor::EricssonGsm.meta_entita_adiacenza[RETE_UMTS].last.split(NAMING_PATH_SEP),
                                   FDC_CNA_PREFIX_FCELL => Vendor::EricssonGsm.meta_entita_adiacenza[RETE_GSM].first.split(NAMING_PATH_SEP),
                                   FDC_CNA_PREFIX_CELL => %w(NW MSC BSC PP SITE TG CELL ol_cell ch_group_0 ch_group_1 ch_group_2)
                                 }
                                 n_cell_list = []
                                 un_cell_list = []
                                 (0..63).each do |idx|
                                   n_cell_list << "n_cell_#{idx}"
                                   un_cell_list << "un_cell_#{idx}"
                                 end
                                 res[FDC_CNA_PREFIX_CELL] += n_cell_list + un_cell_list
                                 res
                               end.freeze

      def meta_entita_header_fdc(tipo)
        META_ENTITA_HEADER_FDC[tipo]
      end

      def istanzia_header(tipo) # rubocop:disable Metrics/AbcSize
        # 1. trovo np presenti nel PI master
        me_tot = meta_entita_header_fdc(tipo) & @metamodello.meta_entita.map { |_np, me_obj| me_obj.nome }
        me_pi = {}
        @saa.dataset(use_pi: true).where(meta_entita: me_tot).select(:naming_path, :meta_entita).distinct.each { |r| me_pi[r[:meta_entita]] = r[:naming_path] }
        me_intestazione = sistema_intestazione(me_tot & me_pi.keys, me_tot)
        # 2. ciclo su header ordinato delle me
        me_intestazione.each do |me|
          @header_file[tipo] << me
          next unless me_pi.keys.include?(me)
          @me_header[tipo] << me
          next unless @metamodello.meta_parametri_fdc[me_pi[me]]
          # 3. trovo i meta_parametri presenti sul PI master
          mp_pi = @saa.dataset(use_pi: true).with_sql("select distinct json_object_keys(parametri) as key from #{@saa.pi.entita.table_name} A where meta_entita = '#{me}'").map { |k| k[:key] }
          lista_mp = (@metamodello.meta_parametri_fdc[me_pi[me]][:is_to_export] || {}).keys & mp_pi
          # aggiungo all'header_file i meta_parametri del metamodello intersecati con quelli presenti nel pi per quella me
          @header_file[tipo].concat(sistema_intestazione(lista_mp, (@metamodello.meta_parametri_fdc[me_pi[me]][:is_to_export] || {}).keys, to_sort: true)) unless lista_mp.empty?
        end
      end

      REGEXP_MO_INTESTAZIONE = Regexp.new('^(.+?\\_)[0-9]+$')
      def sistema_intestazione(lista_obj, lista_obj_tot, to_sort: false) # rubocop:disable Metrics/AbcSize
        ret = []
        # data lista_obj di meta_entita o meta_parametri presenti nel PI, la devo completeare con le eventuali meta_entita array per le numerazioni non presenti nel PI
        # es: se nel PI ho solo ch_group_0, nell'header devo mettere anche ch_group_1, ch_group 2
        lista_obj.each do |m_obj|
          next if ret.include?(m_obj)
          ret << m_obj
          next unless m_obj =~ REGEXP_MO_INTESTAZIONE
          obj_prefix = m_obj[0..m_obj.rindex('_')]
          ret += lista_obj_tot.select { |eee| eee.start_with?(obj_prefix) }
        end
        ret.sort_by! { |x| x.split('_').map { |el| el.to_i.to_s == el ? format('%010d', el) : el } } if to_sort
        ret.uniq
      end

      def aggiorna_mo(dist_name:, parametri: {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # se il dist_name in input identifica una nuova riga, scrivo la riga e istanzion un nuovo mo, altrimenti aggiungo gli elementi all'mo presente
        # il dist_name in input non identifica una nuova riga se:
        # - e' un figlio dell'attuale mo
        # - non e' figlio dell'attuale mo ma e' comunuque figlio dell'oggetto CELL
        # puts "actual_mo.dist_name: #{@actual_mo.dist_name}"
        [nil, Vendor::Ericsson.meta_entita_cella(RETE_GSM)].each do |me|
          next unless dist_name.start_with?(dn = @actual_mo.dist_name(meta_entita: me))
          @actual_mo.add_elements(dn: dist_name[(dn.length + 1)..-1], parametri: parametri)
          return 0
        end
        # se arrivo qui significa che il dist_name non e' figlio dell'actual_mo, lo posso quindi scrivere su file e inizializzare un nuovo mo
        @actual_mo.stato = STATO_MO_FINAL
        yield @actual_mo
        # per istanziare il nuovo mo prendo il tipo_file e i parametri dei padri comuni dal precedente mo
        tipo = @actual_mo.tipo_file
        dn_padre_arr = @actual_mo.dist_name.split(DIST_NAME_SEP) & dist_name.split(DIST_NAME_SEP)
        new_mo = ManagedObjectFdcCna.new(me_header: @me_header[tipo], tipo_file: tipo, init_dist_name: CNA_ROOT)
        np = ''
        dn_padre_arr.each do |ent|
          me = ent.split(DIST_NAME_VALUE_SEP).first
          if ent == CNA_ROOT # la root non ha parametri
            np = me
            next
          end
          np += "#{NAMING_PATH_SEP}#{me}"
          new_mo.add_elements(dn: ent, parametri: @actual_mo.get_parametri_entita(me: me, lista_mp: (@metamodello.meta_parametri_fdc[np][:is_to_export] || {}).keys))
        end
        # aggiungo ora la parte nuova
        new_mo.add_elements(dn: dist_name, parametri: parametri)
        @actual_mo = new_mo
        1
      end

      def scrivi_riga(mo:, writer: nil)
        if writer
          writer.scrivi_riga(header: @header_file[mo.tipo_file], mo: mo)
        else
          mo.riga_dati(@header_file[mo.tipo_file])
        end
      end

      def gestisci_entita(tipo:, writer:, res:, info_progresso: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        ret = {}
        idx = 0
        # dato il tipo, esegue la query sul PI per estarre le entita secondo i nomi legati al tipo, escludendo la root
        me_list_for_query = meta_entita_header_fdc(tipo).map { |xx| "'#{xx}'" }.join(',')
        # me_for_header = @saa.dataset(use_pi: true).select(:meta_entita).distinct.map { |r| r[:meta_entita] }
        query = "select dist_name, parametri from #{@saa.pi.entita.table_name} where meta_entita in (#{me_list_for_query}) and livello > 1 order by dist_name"

        logger.info("#{@log_prefix}. Inizio elaborazione dati per file #{Constant.info(:fdc_cna_prefix, tipo)[:nome]}")
        begin
          @saa.dataset(use_pi: true).db.transaction do
            @saa.dataset(use_pi: true).db[query].select([:dist_name, :parametri]).each do |row|
              aggiorna_mo(dist_name: row[:dist_name], parametri: row[:parametri]) do |mo|
                ret[idx += 1] = scrivi_riga(mo: mo, writer: writer)
                info_progresso.incr if info_progresso
              end
            end
          end
        rescue => e
          res[:eccezione] = "#{e}: #{e.message} - db.transaction su #{@saa.pi.entita.table_name}"
          logger.error("#{@log_prefix} catturata eccezione (#{res})")
          raise
        end
        # scrivo l'ultima riga
        ret[idx += 1] = scrivi_riga(mo: @actual_mo, writer: writer) if @actual_mo
        info_progresso.incr if info_progresso
        ret
      end

      def con_lock(**opts, &block)
        @saa.con_lock(mode: LOCK_MODE_READ, use_pi: true, **opts, &block)
      end

      CNA_ROOT = 'NW=AXE'.freeze

      def esegui(opts)  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        res = {}
        [FDC_CNA_PREFIX_FCELL, FDC_CNA_PREFIX_UCELL, FDC_CNA_PREFIX_CELL].each do |tipo|
          res[Constant.info(:fdc_cna_prefix, tipo)[:nome]] = 'n. righe dati: '
        end
        step_info = opts[:step_info] || 100_000
        con_lock(account_id: @saa.account_id, **opts) do |_locks|
          con_segnalazioni(funzione: opts[:funzione], account: @saa.account, filtro: @saa.filtro_segnalazioni, attivita_id: opts[:attivita_id]) do
            Irma.gc
            InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
              con_writer do |writer|
                [FDC_CNA_PREFIX_FCELL, FDC_CNA_PREFIX_UCELL, FDC_CNA_PREFIX_CELL].each do |tipo|
                  istanzia_header(tipo)
                  writer.scrivi_header(header: @header_file[tipo], tipo: tipo)
                  # istanzio l'actual_mo con il dist_name root
                  @actual_mo = ManagedObjectFdcCna.new(me_header: @me_header[tipo], tipo_file: tipo, init_dist_name: CNA_ROOT)
                  ret = gestisci_entita(tipo: tipo, writer: writer, res: res, info_progresso: ip)
                  res[Constant.info(:fdc_cna_prefix, tipo)[:nome]] += ret.keys.last.to_s
                  # check_fdn_create
                end
              end # con_writer
            end # InfoProgresso
          end # con_segnalazioni
        end # con_lock
        res
      end
    end # class CreazioneFdcCna
  end
end
