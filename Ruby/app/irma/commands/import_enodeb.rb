# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20171017
#

require 'irma/db'

module Irma
  #
  class Command < Thor
    method_option :input_file, aliases: '-f', type: :string, banner: 'Nome del file di input'
    method_option :step_info, aliases: '-s', type: :numeric, banner: 'Step per progress (0=nessuno)', default: 10
    method_option :dry_run, type: :boolean, banner: 'Esecuzione finta, solo output a video'
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :verbose, aliases: '-v', type: :boolean, banner: 'Verbose mode', default: true
    common_options 'import_enodeb', "Esegue l'import di eNodeB e eNodebID nella tabella di anagrafica degli eNodeB"
    def import_enodeb # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      start_time = Time.now
      # controllo che la tabella di anagrafica sia vuota
      raise 'Tabella anagrafica_enodeb popolata: svuotare la tabella prima di caricare il file' if Db::AnagraficaEnodeb.count > 0
      #  controllo che il file esista
      @input_file = absolute_file_path(options[:input_file])
      raise "Input file '#{@input_file}' non trovato per l'import (#{@input_file})" unless File.exist?(@input_file)
      #------------
      out_msg("Inizio import eNodeB dal file #{@input_file}, step_info=#{options[:step_info]}")
      count = 0
      begin
        Db.connection.transaction do
          Irma.processa_file_per_linea(@input_file, suffix: 'parse_csv') do |line, n|
            begin
              # intestazione: ENID_VAREA,ENID_VENODEB_NAME,ENID_NENODEB_ID
              next if n == 0
              line_arr = line.delete('"').chomp.split(',')
              Db::AnagraficaEnodeb.create(area_territoriale: line_arr[0], enodeb_name: line_arr[1].upcase, enodeb_id: line_arr[2])
              count += 1
            rescue => e
              out_msg("Errore in processazione linea #{n} (#{line}): #{e}")
              raise
            end
          end
        end
      rescue => e
        out_msg("Import dati dal file #{@input_file} fallito (#{e})", start_time)
        raise
      end
      out_msg("Import dati dal file #{nome_file_input} terminato con successo, inseriti #{count} eNodeB", start_time)
    end

    private

    def pre_import_enodeb
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
