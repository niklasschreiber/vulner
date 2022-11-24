# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180219
#

# rubocop:disable all
module Irma
  #
  class Command < Thor

    private

    # import_formato_utente, import_filtro_formato_utente
    def check_input_file_for_import(filename, suffix: 'import_fu')
      res = { lista_file: [], formato: nil }
      @input_file = absolute_file_path(filename)
      raise "Input file '#{@input_file}' non trovato per l'import (#{filename})" unless File.exist?(@input_file)

      # input_file deve esistere ed essere un file '.zip' o '.xls'
      case File.extname(@input_file)
      when /\.xls/i
        res[:lista_file] << @input_file
        res[:formato] = :xls
      when /(\.gz|\.zip)/i
        @unzip_dir = Irma.estrai_archivio(@input_file, suffix: 'import_fu')
        raise "Input file '#{@input_file}' non e' un file corretto" unless @unzip_dir
        res[:lista_file] = Dir["#{@unzip_dir}/**/*.*"].select { |x| File.file?(x) }
        res[:formato] = :text
      else
        raise "Input file '#{@input_file}' non ha l'estensione corretta"
      end
      res
    end

    # export_formato_utente, export_filtro_formato_utente, pi_export_formato_utente
    def comprimi_e_sposta_file_export_formato_utente(formato, tmp_out_dir, out_dir, res)
      out_files = Dir["#{tmp_out_dir}/*"]
      artifact = nil
      tmp_zip_dir = nil
      if out_files.count > 0
        artifact = if formato == 'txt'
                     tmp_zip_dir = Irma.tmp_sub_dir('temp_export_fu_zip')
                     zip_file = "#{File.join(tmp_zip_dir, File.basename(tmp_out_dir))}.zip"
                     `cd "#{File.dirname(tmp_out_dir)}" && zip -r "#{zip_file}" #{File.basename(tmp_out_dir)} 2>&1`
                     err = $CHILD_STATUS.exitstatus
                     raise "Errore nella compressione della directory #{tmp_out_dir} (#{err})" unless err.zero?
                     FileUtils.rm_rf(tmp_out_dir)
                     zip_file
                   else
                     nuovo_nome_file = File.join(tmp_out_dir, File.basename(tmp_out_dir) + File.extname(out_files.first))
                     FileUtils.mv(out_files.first, nuovo_nome_file)
                     nuovo_nome_file
                   end
        target_path = File.join(out_dir, File.basename(artifact))
        # puts "ARTIFACT: #{artifact}, target_path = #{target_path}, out_dir = #{out_dir}, relative? = #{Pathname.new(out_dir).relative?}"
        # move artifact into out_dir if absolute, otherwise on shared
        Pathname.new(out_dir).relative? ? shared_post_file(artifact, target_path) : FileUtils.mv(artifact, target_path)
        res[:artifacts] << [target_path, 'export_fu']
      end
      artifact
    ensure
      FileUtils.rm_rf(tmp_zip_dir) if tmp_zip_dir
    end

    # export_formato_utente, export_filtro_formato_utente, pi_export_formato_utente
    def dir_name_export_formato_utente(prefix, sist_or_vend, no_data)
      pp = [prefix] # [options[:solo_header] ? 'export_filtro_metamodello' : 'export_fu']
      pp << Time.now.strftime('%Y%m%d%H%M') unless no_data
      pp << sist_or_vend.to_s if sist_or_vend
      pp.join('_').bonifica_filename
    end

    # import_filtro_formato_utente, export_filtro_formato_utente
    def vendor_releases_id_from_omc_list(omc_id_list, omc_fisico = false)
      vr_list = []
      omc_class = omc_fisico ? Db::OmcFisico : Db::Sistema
      vr_id_field = omc_fisico ? 'vendor_release_fisico_id' : 'vendor_release_id'
      (omc_id_list || []).each do |sss|
        omc = omc_class.first(id: sss)
        next unless omc
        vr_list << omc.send(vr_id_field)
      end
      vr_list.flatten.compact.uniq
    end

    # import_metaparametri_update_on_create, import_metaparametri_secondari
    def import_table_metaparametri_with_flag(options:, table_mp:)
      raise "File non supportato per l'import" unless %w(xls xlsx XLSX).include?(File.extname(options[:input_file]).tr('.', ''))
      num_linea_hdr = 1
      table_mp.transaction do
        table_mp.truncate
        Irma.read_xls(options[:input_file]) do |sheet_name, row_idx, record|
          num_linea = row_idx + 1
          next if record.empty? || num_linea == num_linea_hdr
          rete_descr, vendor_descr, vendor_releases, naming_path, full_name = record
          raise "Naming path non indicato a riga '#{num_linea}'" if (naming_path || {}).empty?
          raise "Nome Metaparametro non indicato a riga '#{num_linea}'" if (full_name || {}).empty?
          raise "Non esiste nessuna rete con nome '#{rete_descr}'; riga file '#{num_linea}'" unless (rete = Db::Rete.where(nome: rete_descr).first)
          raise "Non esiste nessun vendor con nome '#{vendor_descr}'; riga file '#{num_linea}'" unless (vendor = Db::Vendor.where(nome: vendor_descr).first)
          params = { rete_id: rete.id, vendor_id: vendor.id, naming_path: naming_path, full_name: full_name }
          params[:vendor_releases] = vendor_releases.to_s.tr(' ', '').split(',') unless (vendor_releases || {}).empty?
          table_mp.create(params)
        end
        table_mp.imposta_metaparametri
      end
    end
  end
end
