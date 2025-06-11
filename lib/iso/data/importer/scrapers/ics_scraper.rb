# lib/iso/data/importer/scrapers/ics_scraper.rb
# frozen_string_literal: true

require_relative 'base_scraper'
require_relative '../models/ics_entry'

module Iso
  module Data
    module Importer
      module Scrapers
        class IcsScraper < BaseScraper
          SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_ics/csv/ICS.csv"
          LOCAL_FILENAME = "ICS.csv"

          def scrape(force_download: false, &block_param) # Changed `&block` to `&block_param` to avoid conflict
            log("Starting scrape for ISO ICS data...", 0, :info)
            processed_count = 0

            downloaded_file_path = download_file(
              SOURCE_URL,
              LOCAL_FILENAME,
              force_download: force_download
            )

            unless downloaded_file_path && File.exist?(downloaded_file_path)
              log("Failed to download or find ICS data file. Aborting scrape.", 0, :error)
              return processed_count
            end

            begin
              each_csv_row(downloaded_file_path, clean_headers: false) do |csv_row_hash|
                begin
                  ics_entry = Iso::Data::Importer::Models::IcsEntry.new(csv_row_hash)
                  block_param&.call(ics_entry) # Use the captured block_param
                  processed_count += 1
                rescue ArgumentError => e
                  log("Error instantiating IcsEntry model: #{e.message}", 1, :warn)
                  log("Problematic CSV data row: #{csv_row_hash.inspect[0..350]}...", 2, :warn)
                rescue StandardError => e
                  log("Unexpected error processing an ICS entry: #{e.class} - #{e.message}", 1, :error)
                  log("Item data row: #{csv_row_hash.inspect[0..350]}...", 2, :error)
                  log("Backtrace (item processing):\n#{e.backtrace.take(5).join("\n")}", 2, :error)
                end
              end
            rescue StandardError => e
              log("Critical error during CSV processing for ICS data: #{e.message}", 0, :error)
              log("Backtrace (CSV processing):\n#{e.backtrace.take(5).join("\n")}", 1, :error)
            end

            log("Finished scraping ISO ICS data. Processed #{processed_count} items.", 0, :info)
            return processed_count
          end
        end
      end
    end
  end
end