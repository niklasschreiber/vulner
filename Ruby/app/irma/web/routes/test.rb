# vim: set fileencoding=utf-8
#
# Author       : P. Cortona
#
# Creation date: 20190225
#

module Irma
  #
  module Web
    class App < Roda
      def submit_dw
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        filtro.map { |k, v| '<div style="background-color: #cccccc" ><span style="font-weight: bold">' + k.to_s + '</span>: <span style="color: red">' + v.to_s + '</span></div>' }.join('<br>')
      end

      def list_file_di_configurazione_per_utente
        result = Array.new(3) do |i|
          { id: i, descr: 'FdC_000' + i.to_s + '.xml', dimensione: 12_300 + i }
        end
        result
      end

      def grid_contenuto_file_di_configurazione # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        if filtro[:fdc]
          id_fdc = filtro[:fdc].to_i
          return { total: 0, data: [] } if id_fdc < 0 || id_fdc >= 3
          # estrai info contenuto file di configurazione
          result = { total: 6, data: nil }
          i = 0
          result[:data] = %w(CRE CRE_ADJ DEL DEL_ADJ UPD UPD_ADJ).map do |ftype|
            i += 1
            { id: id_fdc.to_s + i.to_s,
              descr:               "#{ftype}_FdC_000#{id_fdc}.xml",
              dimensione:          (12_300 + i) / 6 + i,
              num_managed_objects: (1000 + id_fdc) * 10 + i,
              num_parametri:       (65 + id_fdc) * 10 + i
            }
          end
        end
        result
      end

      def attivita_schedulata_fdc_invio_nandc(parametri, _opts = {})
        file_raml = parametri['raml_list']
        raise 'Atteso un elenco di file raml' + file_raml.class.to_s unless file_raml.is_a?(Array) || file_raml.empty?
        raise 'Identificare file di configurazione non fornito' unless parametri['fdc']
        messaggio = 'Mock: Attivita schedulata correttamente. File di configurazione: ' + parametri['fdc']
        messaggio += '. <br/>Identificatori file RAML: ' + file_raml.join(',')
        messaggio
      end

      App.route('test') do |r|
        r.post('dw/submit') do
          handle_request { submit_dw }
        end
        r.get('file_di_configurazione/list') do
          handle_request { list_file_di_configurazione_per_utente }
        end
        r.post('file_di_configurazione/contenuto/grid') do
          handle_request { grid_contenuto_file_di_configurazione }
        end
        r.post('file_di_configurazione/invio_nadc/schedula') do
          # schedula_attivita do |parametri, opzioni_attivita_schedulata|
          #   attivita_schedulata_fdc_invio_nandc(parametri, opzioni_attivita_schedulata)
          # end
          handle_request do
            attivita_schedulata_fdc_invio_nandc(request.params, {})
          end
        end
        r.get do
          'OK'
        end
      end
    end
  end
end
