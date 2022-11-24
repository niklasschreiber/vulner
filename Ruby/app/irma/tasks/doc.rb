# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151122
#
# Task to generate and check technical documentation
#

require 'rake'

def convert_erb_file(f)
  new_file = f.gsub(/\.erb$/, '')
  output_msg("Converting template file #{f}", prefix: true)
  File.open(new_file, 'w') { |fd| fd.puts(ERB.new(File.read(f)).result(binding)) }
rescue => e
  puts "ERRORE: convert_erb_file fallita per il file #{f}: #{e}, backtrace: #{e.backtrace}"
  raise
end

def cleanup_generated_adoc_files(pattern)
  # cleanup for generated .adoc files
  Dir[pattern].each do |f|
    g = f.gsub(/.erb$/, '')
    output_msg("Removing generated file #{g}")
    FileUtils.rm_f(g)
  end
end

namespace :doc do
  task :common do
    # change default location of annotation to :after
    require 'irma/db'
    require 'irma/db/annotate_models'
    Irma::Db.init
  end

  namespace :annotate do
    task add: 'doc:common' do
      Irma::Db::AnnotateModels.do_annotations(
        model_dir:          Irma::Db::MODELS_DIR,
        position_in_class:  (ENV['ANNOTATE_BEFORE'].nil? || ENV['ANNOTATE_BEFORE'] == '0') ? 'after' : 'before',
        show_indexes:       (ENV['ANNOTATE_INDEXES'].nil? || ENV['ANNOTATE_INDEXES'] == '1'),
        show_foreign_keys:  (ENV['ANNOTATE_FK'].nil? || ENV['ANNOTATE_FK'] == '1'),
        include_version:     ENV['include_version']
      )
    end

    task remove: 'doc:common' do
      Irma::Db::AnnotateModels.remove_annotations(model_dir: Irma::Db::MODELS_DIR)
    end
  end

  desc "Aggiunge le annotazioni del DB nei file di modello.
ANNOTATE_INDEXES=0 non include gli indici
ANNOTATE_BEFORE=1  mette le annotazioni all'inizio del file
"
  task annotate: 'doc:annotate:add'

  desc 'Rimuove le annotazioni del DB nei file di modello'
  task annotate_remove: 'doc:annotate:remove'

  desc 'Rigenera i manuali'
  task specifiche: 'doc:common' do
    sp_prefix = 'Specifiche/IRMA_Specifiche'
    Dir['doc/Specifiche/*/*.erb'].each { |f| convert_erb_file(f) }
    erb_pattern = 'doc/Specifiche/*.erb'
    [ # ENV['SPECIFICHE_TOTALI', suffix
      [1, '_Complete'],
      [0, '_PerIngegneria']
    ].each do |st, suffix|
      ENV['SPECIFICHE_TOTALI'] = st.to_s
      Dir[erb_pattern].each { |f| convert_erb_file(f) }
      out_file = "#{sp_prefix}#{suffix}.pdf"
      res = `cd doc; ./manage_doc.sh build_pdf #{sp_prefix}.adoc; mv -f #{sp_prefix}.pdf #{out_file}`
      raise "Generazione specifiche fallita: #{res}" unless $CHILD_STATUS.exitstatus.zero?
      puts res
      output_msg("File #{out_file} generato con successo")
    end
    cleanup_generated_adoc_files(erb_pattern)
  end

  task manuale_installazione: 'doc:common' do
    mi_prefix = 'Manuali/ManualeInstallazione/IRMA_ManualeInstallazione'
    erb_pattern = 'doc/Manuali/ManualeInstallazione/**/*.erb'
    Dir[erb_pattern].each { |f| convert_erb_file(f) }
    out_file = "#{mi_prefix}.pdf"
    res = `cd doc; ./manage_doc.sh build_pdf #{mi_prefix}.adoc #{out_file}`
    raise "Generazione manuale installazione fallita: #{res}" unless $CHILD_STATUS.exitstatus.zero?
    puts res
    output_msg("File #{out_file} generato con successo")
    cleanup_generated_adoc_files(erb_pattern)
  end

  task manuale_amministrazione: 'doc:common' do
    mi_prefix = 'Manuali/ManualeAmministrazione/IRMA_ManualeAmministrazione'
    erb_pattern = 'doc/Manuali/ManualeAmministrazione/**/*.erb'
    Dir[erb_pattern].each { |f| convert_erb_file(f) }
    out_file = "#{mi_prefix}.pdf"
    res = `cd doc; ./manage_doc.sh build_pdf #{mi_prefix}.adoc #{out_file}`
    raise "Generazione manuale amministrazione fallita: #{res}" unless $CHILD_STATUS.exitstatus.zero?
    puts res
    output_msg("File #{out_file} generato con successo")
    cleanup_generated_adoc_files(erb_pattern)
  end

  task manuali_utente: 'doc:common' do
    mu_prefix = 'Manuali/ManualeUtente/IRMA_ManualeUtente'
    erb_pattern = 'doc/Manuali/ManualeUtente/**/*.erb'
    Irma::Constant.constants(:profilo).map { |c| (!ENV['PROFILO_PER_MANUALE_UTENTE'] || c.info[:nome] == ENV['PROFILO_PER_MANUALE_UTENTE']) ? c.info[:nome] : nil }.compact.sort.each do |nome_profilo|
      output_msg("Generating user manual for profile #{nome_profilo}", prefix: true)
      ENV['PROFILO_PER_MANUALE_UTENTE'] = nome_profilo
      Dir[erb_pattern].each { |f| convert_erb_file(f) }
      out_file = "#{mu_prefix}_#{nome_profilo}.pdf"
      res = `cd doc; ./manage_doc.sh build_pdf #{mu_prefix}.adoc; mv -f #{mu_prefix}.pdf #{out_file}`
      raise "Generazione manuale utente per il profilo #{nome_profilo} fallita: #{res}" unless $CHILD_STATUS.exitstatus.zero?
      puts res
      output_msg("File #{out_file} generato con successo")
    end
    cleanup_generated_adoc_files(erb_pattern)
  end
end

task doc: ['doc:specifiche', 'doc:manuale_installazione', 'doc:manuale_amministrazione', 'doc:manuali_utente']
