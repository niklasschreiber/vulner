# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170216
#
require 'tmpdir'
require 'rest-client'
require 'json'

module Irma
  def self.shared_fs_route(force = false)
    @shared_fs_route = nil if force
    @shared_fs_route ||= (ENV['IRMA_SHARED_FS_ROUTE'] || 'shared')
  end

  def self.shared_fs_url(force = false)
    @shared_fs_url = nil if force
    @shared_fs_url ||= ENV['IRMA_SHARED_FS_URL'].to_s.empty? ? '' : File.join(ENV['IRMA_SHARED_FS_URL'], shared_fs_route)
  end

  module SharedFs
    # rubocop:disable Metrics/ModuleLength
    module Util
      def absolute_file_path(file)
        Pathname.new(file).relative? ? shared_get_file(file) : file
      end

      def shared_get_file(shared_relative_path, file = nil)
        if Irma.shared_fs_url.empty?
          full_path = File.join(Irma.shared_dir, shared_relative_path)
          raise "Requested shared file #{shared_relative_path} is not a file (#{full_path})" unless File.file?(full_path)
          Irma.logger.info("SharedFs: returning file #{full_path}")
          full_path
        else
          Irma.logger.info("Retrieving file #{shared_relative_path} from shared_fs server url #{Irma.shared_fs_url}")
          _get_file(File.join(Irma.shared_fs_url, shared_relative_path), file)
        end
      end

      def shared_post_file(local_file, shared_relative_path, opts = {}) # rubocop:disable Metrics/AbcSize
        options = { copy: false }.merge(opts)
        if Irma.shared_fs_url.empty?
          full_path = File.join(Irma.shared_dir, shared_relative_path)
          FileUtils.mkdir_p(File.dirname(full_path))
          FileUtils.send(options[:copy] ? :cp : :mv, local_file, full_path)
          Irma.logger.info("SharedFs: created file #{full_path}")
          "Shared file #{shared_relative_path} creato con successo"
        else
          Irma.logger.info("Sending file #{shared_relative_path} to shared_fs server url #{Irma.shared_fs_url}")
          _post_file(File.join(Irma.shared_fs_url, shared_relative_path), local_file).body
        end
      end

      def shared_copy_file(source_shared_relative_path, dest_shared_relative_path)
        if Irma.shared_fs_url.empty?
          source_path = File.join(Irma.shared_dir, source_shared_relative_path)
          raise "Source shared file #{source_path} non trovato" unless File.exist?(source_path)
          shared_post_file(source_path, dest_shared_relative_path, copy: true)
        else
          Irma.logger.info("Request 'copy #{source_shared_relative_path} #{dest_shared_relative_path}' to shared_fs server url #{Irma.shared_fs_url}")
          _put_file(File.join(Irma.shared_fs_url, source_shared_relative_path), dest_shared_relative_path).body
        end
      end

      def shared_remove_path(shared_relative_path) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
        if Irma.shared_fs_url.empty?
          full_path = File.join(Irma.shared_dir, shared_relative_path)
          esito = if File.exist?(full_path)
                    if full_path != '/' && full_path != ''
                      FileUtils.rm_rf(full_path)
                      'rimosso con successo'
                    else
                      'non rimosso'
                    end
                  else
                    'non trovato'
                  end
          Irma.logger.info("SharedFs: removing path #{full_path} (#{esito})")
          "Shared path #{shared_relative_path} #{esito}"
        else
          Irma.logger.info("Request 'delete #{shared_relative_path}' to shared_fs server url #{Irma.shared_fs_url}")
          _delete_path(File.join(Irma.shared_fs_url, shared_relative_path)).body
        end
      end

      def shared_show_files(shared_relative_path, recursive: true)
        if Irma.shared_fs_url.empty?
          full_path = File.join(Irma.shared_dir, shared_relative_path)
          files = _shared_show_files(shared_relative_path, full_path, recursive: recursive)
          Irma.logger.info("SharedFs: showing files #{files}")
          files.to_json
        else
          Irma.logger.info("Request 'show files in #{shared_relative_path}' to shared_fs server url #{Irma.shared_fs_url}")
          _show_files(File.join(Irma.shared_fs_url, 'show', shared_relative_path), recursive: recursive)
        end
      end

      # metodi per scrivere e leggere filtro_metamodello su file
      def scrivi_filtro_mm_file(prefix_nome:, dir:, filtro_mm:)
        sub_dir = Irma.tmp_sub_dir('filtro_mm')
        fm_file = File.join(sub_dir, bn_fm_file = "filtro_mm-#{prefix_nome}.json")
        File.open(fm_file, 'wb') { |fd| fd.write((filtro_mm || {})) }
        fm_file_shared = File.join(dir, bn_fm_file)
        shared_post_file(fm_file, fm_file_shared)
        fm_file_shared
      ensure
        FileUtils.rm_rf(sub_dir)
      end

      def determina_filtro_mm(filtro_mm_file:, filtro_mm:)
        fm_temp = if filtro_mm_file
                    fm_file = absolute_file_path(filtro_mm_file)
                    raise "File '#{fm_file}' non trovato" unless File.exist?(fm_file)
                    ll = File.open(fm_file, 'r').gets
                    ll.chomp if ll
                  else
                    filtro_mm
                  end
        fm_temp.to_s.empty? ? nil : JSON.parse(fm_temp)
      end

      private

      def _shared_show_files(shared_relative_path, full_path, recursive: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        dir = {}
        ([full_path] + Dir[File.join(full_path, recursive ? '**/*' : '*')].sort).each do |f|
          relative_path = f == full_path ? shared_relative_path : File.join(shared_relative_path, f.sub(/^(.*?)#{shared_relative_path}/, ''))
          new_node = { descr:         File.basename(f),
                       dimensione:    File.stat(f).size,
                       data_file:     File.stat(f).mtime,
                       leaf:          File.file?(f),
                       expanded:      false,
                       relative_path: relative_path,
                       full_path:     f,
                       children:      File.directory?(f) ? [] : nil }
          dir[f] = new_node if File.directory?(f) || f == full_path
          dir[File.dirname(f)][:children] << new_node if f != full_path
        end
        dir[full_path]
      end

      def _show_files(url, recursive: true)
        res = RestClient::Request.execute(method: :get, url: URI.encode(url), headers: { params: { recursive: recursive ? 'true' : 'false' } })
        raise "show_files error for url #{url} (#{res.code}, #{res.message})" unless res.code.to_i == HTTP_CODE_OK
        res.body
      end

      def _get_file(url, file = nil) # rubocop:disable Metrics/AbcSize
        file ||= Dir::Tmpname.make_tmpname(Irma.shared_dir + '/', File.basename(url))
        FileUtils.mkdir_p(File.dirname(file))
        res = File.open(file, 'wb') do |fd|
          RestClient::Request.new(method: :get, url: URI.encode(url), block_response: ->(response) { response.read_body { |chunk| fd.write chunk } }).execute
        end
        if res.code.to_i == HTTP_CODE_OK
          file
        else
          FileUtils.rm_f file
          raise "get_file error for url #{url} (#{res.code}, #{res.message})"
        end
      end

      def _post_file(url, file)
        RestClient.post(URI.encode(url), multipart: true, content_type: 'multipart/form-data', upload: File.new(file, 'rb'))
      end

      def _put_file(url, shared_relative_path)
        RestClient.put(URI.encode(url), shared_relative_path: shared_relative_path)
      end

      def _delete_path(url)
        RestClient.delete(URI.encode(url))
      end
    end

    module RodaRoute
      include Util
      REGEXP_HEADING_SLASH = Regexp.new('^\/*')

      def self.included(other) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        raise "Cannot include #{self} into #{other} because it is not a subclass of Roda class" unless other.ancestors.include?(Roda)
        other.route(Irma.shared_fs_route) do |r|
          begin
            r.on 'show' do
              raise 'Invalid request params (invalid recursive param)' if r.params['recursive'] && !(r.params['recursive'] == 'true' || r.params['recursive'] == 'false')
              remaining_path = URI.decode(r.remaining_path.to_s.gsub(REGEXP_HEADING_SLASH, ''))
              raise 'Shared path vuoto non valido' if remaining_path.empty?
              shared_show_files(remaining_path, recursive: r.params['recursive'] && r.params['recursive'] == 'true' ? true : false)
            end
            # remove heading '/' if present
            remaining_path = URI.decode(r.remaining_path.to_s.gsub(REGEXP_HEADING_SLASH, ''))
            raise 'Shared path vuoto non valido' if remaining_path.empty?

            r.get do
              invia_file shared_get_file(remaining_path), filename: remaining_path
            end
            r.post do
              raise 'Invalid request params (missing upload param)' unless r.params['upload'] && r.params['upload'][:tempfile]
              shared_post_file(r.params['upload'][:tempfile].path, remaining_path)
            end
            r.put do
              raise 'Invalid request params (missing shared_relative_path param)' unless r.params['shared_relative_path']
              shared_copy_file(remaining_path, r.params['shared_relative_path'])
            end
            r.delete do
              shared_remove_path(remaining_path)
            end
          rescue => e
            Irma.logger.error("SharedFs WS, eccezione riscontrata nella gestione della richiesta: #{e}, #{e.backtrace}")
            request.halt([HTTP_CODE_NOT_FOUND, { 'Content-Type' => 'text/html' }, StringIO.new(e.to_s)])
          end
        end
      end
    end
  end
end
