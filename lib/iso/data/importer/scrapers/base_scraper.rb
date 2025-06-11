# lib/iso/data/importer/scrapers/base_scraper.rb
# frozen_string_literal: true

require 'httparty'
require 'fileutils'
require 'json'
require 'csv'

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

            if !force_download && File.exist?(local_path) && File.size(local_path) > 0
              log "Using cached file: #{local_path}", 0, :info
              return local_path
            end

            log "Downloading #{filename} from #{url}...", 0, :info
            begin
              File.open(local_path, 'wb') do |file|
                response = HTTParty.get(url, stream_body: true, timeout: 180) do |chunk|
                  file.write chunk
                end
                unless response.success?
                  FileUtils.rm_f(local_path)
                  log "Error downloading #{filename}: #{response.code} - #{response.message}", 1, :error
                  log "Response body snippet: #{response.body[0..500]}...", 2, :error if response.body
                  return nil
                end
              end
              log "Successfully downloaded to #{local_path}", 0, :info
              local_path
            rescue HTTParty::Error, SocketError, Timeout::Error, StandardError => e
              FileUtils.rm_f(local_path)
              log "Exception downloading #{filename}: #{e.class} - #{e.message}", 1, :error
              nil
            end
          end

          def each_jsonl_item(file_path)
            return 0 unless file_path && File.exist?(file_path)
            count = 0
            File.foreach(file_path).with_index do |line, idx|
              begin
                yield JSON.parse(line)
                count += 1
              rescue JSON::ParserError => e
                log "Skipping invalid JSON line #{idx + 1} in #{File.basename(file_path)}: #{line.strip}", 1, :warn
                log "Error: #{e.message}", 2, :warn
              end
            end
            log "Parsed #{count} items from #{File.basename(file_path)}", 0, :info
            count
          end

          def each_csv_row(file_path, clean_headers: true, &block)
            return 0 unless file_path && File.exist?(file_path)
            file_content = File.read(file_path, encoding: 'UTF-8').sub("\xEF\xBB\xBF", '')
            count = 0
            begin
              CSV.parse(file_content, headers: true, skip_blanks: true) do |row|
                row_hash = row.to_h
                # ... header cleaning ...
                yield row_hash
                count += 1
              end
              log "Processed #{count} rows from #{File.basename(file_path)}", 0, :info
            rescue CSV::MalformedCSVError => e
              log "Malformed CSV error in #{File.basename(file_path)} near line #{e.line_number}: #{e.message}", 1, :error
            rescue StandardError => e
              log "Error processing CSV #{File.basename(file_path)}: #{e.message}", 1, :error
            end
            count
          end

          def log(message, indent_level = 0, severity = :info)
            indent = "  " * indent_level
            prefix = case severity
                     when :error then "ERROR: "
                     when :warn  then "WARN:  "
                     else            "INFO:  "
                     end
            puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{prefix}#{indent}#{message}"
          end
        end
      end
    end
  end
end