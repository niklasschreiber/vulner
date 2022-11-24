# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20171016
#

module Irma
  #
  module Web
    class App < Roda
      def attivita_schedulata_creazione_fdc(parametri, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        raise 'Specificare un sistema o un omc fisico' if parametri['omc_fisico_id'].to_s.empty? && parametri['sistema_id'].to_s.empty?
        if parametri['omc_fisico_id']
          parametri['sistema_id'] = parametri['omc_fisico_id']
          opts[:omc_fisico] = true
        end
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: parametri['sistema_id']) : Db::Sistema.first(id: parametri['sistema_id'])
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{parametri['sistema_id']})" unless sistema # TODO: verificare le competenze sui sistemi
        raise 'Specificare un progetto irma' if (parametri['pi_id'] || '').empty?
        pi = Db::ProgettoIrma.first(id: parametri['pi_id'])
        raise "Non esiste nessun progetto irma con id '#{parametri['pi_id']}'" unless pi
        label_nome_fdc = parametri['nome_fdc']
        file = parametri['formatoUtente']
        opts.update(lista_sistemi:  !file.nil? ? [[sistema.id, post_locfile_to_shared_fs(locfile: file, dir: opts[:attivita_schedulata_dir])]] : [[sistema.id]],
                    pi_id:          pi.id,
                    label_nome_fdc: label_nome_fdc,
                    out_dir_root:   DIR_ATTIVITA_TAG,
                    flag_del_crt:   !parametri['cancella_ricrea'].nil? ? parametri['cancella_ricrea'] : false)
        opts[:formato_audit] = parametri['formato_audit'] if parametri['formato_audit']
        opts[:canc_rel_adj] = JSON.parse(parametri['canc_rel_adj']) unless parametri['canc_rel_adj'].nil?
        Db::TipoAttivita.crea_attivita_schedulata(opts[:omc_fisico] ? TIPO_ATTIVITA_CREAZIONE_FDC_OMC_FISICO : TIPO_ATTIVITA_CREAZIONE_FDC_OMC_LOGICO, opts)
      end

      def list_pi_filtrati # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        sessione = logged_in
        query = if filtro[:id_omc_fisico]
                  Db::ProgettoIrma.where(omc_fisico_id: filtro[:id_omc_fisico])
                elsif filtro[:id_sistema]
                  Db::ProgettoIrma.where(sistema_id: filtro[:id_sistema])
                else
                  sdcf = id_sistemi_di_competenza_filtrati
                  ofdcf = id_omc_fisici_di_competenza_filtrati
                  Db::ProgettoIrma.where(Sequel.or(sistema_id: sdcf) | Sequel.or(omc_fisico_id: ofdcf))
                end
        query = query.where(Sequel.or(account_id: sessione.account_id) | Sequel.or(account_id: nil))
        query.reverse_order(:account_id, :updated_at).map do |record|
          sof = sistema_o_omc_fisico(record)
          pof = record.per_omcfisico ? '[PER OMC FISICO]' : ''
          {
            created_at:      timestamp_to_string(record[:created_at]),
            updated_at:      ts = timestamp_to_string(record[:updated_at]),
            id:              record[:id],
            label:           sof.is_a?(Db::Sistema) ? 'Sistema' : 'Omc Fisico',
            nome:            record[:nome],
            descr:           "#{record[:nome]} (#{record[:count_entita]} records, ultimo aggiornamento il #{ts})",
            count_entita:    record[:count_entita],
            full_descr:      sof ? sof.full_descr : '',
            sorgente_descr:  "#{pof} #{record[:nome]} (aggiornato il #{ts})",
            omc_logico_id:   record[:sistema_id],
            omc_fisico_id:   record[:omc_fisico_id],
            parametri_input: record[:parametri_input],
            account_id:      record[:account_id]
          }
        end
      end
    end

    App.route('file_di_configurazione') do |r|
      r.post('creazione_fdc/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_creazione_fdc(parametri, opzioni_attivita_schedulata)
        end
      end
      r.get('pi_filtrati/list') do
        handle_request { list_pi_filtrati }
      end
      r.get('flag_cancellazione/list') do
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        sistema = Db::Sistema.get_by_pk(filtro[:sistema_id])
        # creo un array degli id di rete dove la rete del sistema e' sempre al primo posto
        reti = Constant.values(:rete)
        reti.delete(sistema.rete_id)
        reti.unshift(sistema.rete_id)
        reti.map do |rete|
          sistema.vendor_instance.flag_cancellazioni_ammesse(rete, result_type: :full)
        end.flatten.compact
      end
    end
  end
end
