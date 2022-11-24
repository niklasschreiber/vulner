# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20171121
#
require_relative 'segnalazioni_per_funzione'
# require_relative 'aggiorna_adrn/writer'

module Irma
  #
  module Funzioni
    # rubocop:disable Metrics/ClassLength, Metrics/MethodLength
    class AggiornaAdrn
      include SegnalazioniPerFunzione

      attr_reader :logger, :saa_master, :metamodello, :vendor_instance, :funzione, :log_prefix, :kfl

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def initialize(sistema_ambiente_archivio:, **opts)
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @funzione       = Db::Funzione.get_by_pk(opts[:funzione])
        @saa            = sistema_ambiente_archivio
        @vendor_release = opts[:vendor_release]
        @omc_fisico     = opts[:omc_fisico] || false
        @kfl            = Irma::MetaModello.keywords_fisico_logico(@omc_fisico)
        raise 'Keywords meta_modello non definite' unless @kfl

        @metamodello = opts[:metamodello]
        @filtro_segnalazioni_per_aggiornamento = opts[:filtro_segnalazioni]
        @writer_opts = {
          nome_file: File.join(opts[:out_dir], opts[:nome_file] || "aggiorna_adrn_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt")
        }
        #
        @logger             = opts[:logger] || Irma.logger
        @log_prefix         = opts[:log_prefix] || "Aggiorna adrn (#{@saa.sistema.full_descr})"
        #
        @me_id = {}
        @mp_id = {}
      end

      def nuova_segnalazione(tipo_segnalazione, opts = {})
        tipo_segnalazione += 1 if funzione.id == FUNZIONE_CREAZIONE_FDC_OMC_FISICO && !TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
        super(tipo_segnalazione, opts)
      end

      def con_writer
        Db::Segnalazione::RecordFormatterTxt.new(**@writer_opts).create_temp_file(**@writer_opts) do |mio_writer|
          yield mio_writer
        end
      end

      def crea_nuovo_meta_parametro(info)
        # [:id, :vendor_release_id, :meta_entita_id, :nome, :nome_struttura,
        #  :is_multivalue, :is_multistruct, :descr, :tipo, :genere, :regole_calcolo, :regole_calcolo_ae,
        #  :rete_adj, :is_predefinito, :is_to_export, :is_obbligatorio, :is_restricted, :is_forced, :tags,
        #  :full_name, :created_at, :updated_at, :is_update_on_create]

        # TO_EXPORT_FIELDS = %w(naming_path oggetto entita param_semplici param_strutturati param_multivalore param_read_only).freeze
        me_id = @me_id[info['naming_path']]
        unless me_id
          logger.error("#{@log_prefix} Impossibile creare il meta_parametro '#{info['full_name']}', non esiste meta_entita (#{info['naming_path']}) ad esso riferito")
          # TODO: segnalazione ?
          return nil
        end

        begin
          create_opts = { @kfl.field_vr_id.to_sym => @vendor_release.id,
                          @kfl.field_me_id.to_sym => me_id,
                          nome:              info['oggetto'],
                          genere:            info['genere'],
                          full_name:         info['full_name']
          }
          create_opts[:nome_struttura] = info['param_strutturati'] if info['param_strutturati'] != 0
          create_opts[:is_multivalue] = info['param_multivalore'] == 1
          create_opts[:is_multistruct] = [META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE,
                                          META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE].include?(info[:genere])
          create_opts[:is_to_export] = info['param_read_only'] == 0
          # ...
          # --- test
          # puts "PPPPPPPPPP crea_nuovo_meta_parametro con info: #{info}"
          # puts "PPPPPPPPPP                        con create_opts: #{create_opts}"
          # return OpenStruct.new(id: 1)
          # --- end test

          @kfl.classe_meta_parametro.create(create_opts)
        rescue => e
          logger.error("#{@log_prefix} Errore nel creare la meta_entita '#{info['oggetto']}', #{e}")
          # TODO: segnalazione ?
          nil
        end
      end

      def crea_nuova_meta_entita(info)
        # [:id, :vendor_release_id, :nome, :naming_path, :descr, :tipo, :versione,
        #  :extra_name, :regole_calcolo, :regole_calcolo_ae, :rete_adj, :meta_entita_ref,
        #  :fase_di_calcolo, :operazioni_ammesse, :tipo_adiacenza, :created_at, :updated_at, :tipo_oggetto]
        create_opts = { @kfl.field_vr_id.to_sym => @vendor_release.id,
                        nome: info['oggetto'],
                        naming_path: info['naming_path']
        }
        # --- test
        # puts "EEEEEEEEEE crea_nuova_meta_entita con info: #{info}"
        # puts "EEEEEEEEEE                        con create_opts: #{create_opts}"
        # return OpenStruct.new(id: 1)
        # --- end test
        @kfl.classe_meta_entita.create(create_opts)
      rescue => e
        logger.error("#{@log_prefix} Errore nel creare la meta_entita '#{info['oggetto']}', #{e}")
        # TODO: segnalazione ?
        nil
      end

      def elabora_segnalazione(segnalazione:, res:)
        return nil unless segnalazione
        info = segnalazione.to_export_hash
        unless info
          # log...segnalazione...
          res[:segnalazioni_per_aggiornamento][:scartate] += 1
          return nil
        end

        # TO_EXPORT_FIELDS = %w(naming_path oggetto entita param_semplici param_strutturati param_multivalore param_read_only).freeze
        new_obj = nil
        np = segnalazione.naming_path
        info['naming_path'] = np
        if info['entita'] == 1
          # META_ENTITA
          if @me_id[np]
            res[:meta_entita][:gia_create] += 1
          else
            new_obj = crea_nuova_meta_entita(info)
            if new_obj
              res[:meta_entita][:create] += 1
              @me_id[np] = new_obj.id
            else
              res[:meta_entita][:scartate] += 1
            end
          end
        else
          # META_PARAMETRO
          info['full_name'] = [info['param_strutturati'] != 0 ? info['param_strutturati'] : nil, info['oggetto']].compact.join(TEXT_STRUCT_NAME_SEP)
          gu = Constant.info(:tipo_segnalazione, segnalazione.tipo_segnalazione_id)[:genere_per_update]
          info['genere'] = Constant.value(:meta_parametro, gu, :genere)
          if (@mp_id[np] || {})[info['full_name']]
            res[:meta_parametri][:gia_creati] += 1
          else
            new_obj = crea_nuovo_meta_parametro(info)
            if new_obj
              res[:meta_parametri][:creati] += 1
              @mp_id[np] ||= {}
              @mp_id[np][info['full_name']] = new_obj.id
            else
              res[:meta_parametri][:scartati] += 1
            end
          end
        end
        new_obj
      end

      def load_me_mp
        @metamodello.meta_entita.each do |np, me|
          @me_id[np] = me.id
          @mp_id[np] = {}
        end
        @metamodello.meta_parametri.each do |np, mps|
          @mp_id[np] ||= {}
          mps.each do |_k, mp|
            @mp_id[np][mp.full_name] = mp.id
          end
        end
      end

      def esegui(opts)
        res = { segnalazioni_per_aggiornamento: { totali: 0, scartate: 0 },
                meta_entita: { create: 0, scartate: 0, gia_create: 0 },
                meta_parametri: { creati: 0, scartati: 0, gia_creati: 0 } }
        fs = @saa.filtro_segnalazioni.dup
        step_info = opts[:step_info] || 100_000
        %i(archivio).each { |k| fs.delete(k) }

        # inizializza @me_id e @mp_id
        load_me_mp

        con_segnalazioni(funzione: funzione, account: @saa.account, filtro: fs, attivita_id: opts[:attivita_id]) do
          Irma.gc
          InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |info_progresso|
            con_writer do |writer|
              condition = { to_update_adrn: true }
              condition[@saa.is_a?(Db::SistemaAmbienteArchivio) ? :sistema_id : :omc_fisico_id] = @saa.sistema.id
              # Lista segnalazioni ordinate per naming_path con meta_parametro: nil al primo posto se c'e'
              Db::Segnalazione.where(condition.merge(@filtro_segnalazioni_per_aggiornamento)).order(:naming_path, Sequel.desc(:meta_parametro)).all.each do |segn|
                res[:segnalazioni_per_aggiornamento][:totali] += 1
                info_progresso.incr
                obj = elabora_segnalazione(segnalazione: segn, res: res)
                writer.add_record_values(segn, nil) if obj
              end
            end # con_writer
          end # info_progresso
          res
        end # con_segnalazioni
        res
      end
    end
  end
  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      def esegui_aggiorna_adrn(opts)
        opts.update(funzione: FUNZIONE_AGGIORNA_ADRN_OMC_LOGICO)
        Funzioni::AggiornaAdrn.new(sistema_ambiente_archivio: self, **opts).esegui(**opts)
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def esegui_aggiorna_adrn(opts)
        opts.update(funzione: FUNZIONE_AGGIORNA_ADRN_OMC_FISICO)
        Funzioni::AggiornaAdrn.new(sistema_ambiente_archivio: self, **opts).esegui(**opts)
      end
    end
  end
end
