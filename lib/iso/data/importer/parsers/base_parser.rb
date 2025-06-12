# lib/iso/data/importer/parsers/base_parser.rb
# frozen_string_literal: true

require "httparty"
require "fileutils"
require "json"
require "csv"

module Iso
  module Data
    module Importer
      module Scrapers
        class BaseScraper
          TMP_DIR = "tmp/iso_data_cache"

          def initialize
            FileUtils.mkdir_p(TMP_DIR) unless Dir.exist?(TMP_DIR)
          end

          def download_file(url, filename, force_download: false)
            local_path = File.join(TMP_DIR, filename)

            if !force_download && File.exist?(local_path) && File.size(local_path).positive?
              log "Using cached file: #{local_path}", 0, :info
              return local_path
            end

            log "Downloading #{filename} from #{url}...", 0, :info
            begin
              File.open(local_path, "wb") do |file|
                response = HTTParty.get(url, stream_body: true,
                                             timeout: 180) do |chunk|
                  file.write chunk
                end
                unless response.success?
                  FileUtils.rm_f(local_path)
                  log "Error downloading #{filename}: #{response.code} - #{response.message}",
                      1, :error
                  if response.body
                    log "Response body snippet: #{response.body[0..500]}...", 2,
                        :error
                  end
                  return nil
                end
              end
              log "Successfully downloaded to #{local_path}", 0, :info
              local_path
            rescue HTTParty::Error, SocketError, Timeout::Error,
                   StandardError => e
              FileUtils.rm_f(local_path)
              log "Exception downloading #{filename}: #{e.class} - #{e.message}",
                  1, :error
              nil
            end
          end

          def log(message, indent_level = 0, severity = :info)
            indent = "  " * indent_level
            prefix = case severity
                     when :error then "ERROR: "
                     when :warn  then "WARN:  "
                     else "INFO:  "
                     end
            puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{prefix}#{indent}#{message}"
          end
        end
      end
    end
  end
end
