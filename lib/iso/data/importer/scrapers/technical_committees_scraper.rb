# lib/iso/data/importer/scrapers/technical_committees_scraper.rb
# frozen_string_literal: true

require_relative "base_scraper"
require_relative "../models/technical_committee" # Corrected model name

module Iso
  module Data
    module Importer
      module Scrapers
        class TechnicalCommitteesScraper < BaseScraper
          SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_technical_committees/json/iso_technical_committees.jsonl"
          LOCAL_FILENAME = "iso_technical_committees.jsonl"

          def scrape(force_download: false)
            log("Starting scrape for ISO Technical Committees...", 0, :info)
            downloaded_file_path = download_file(
              SOURCE_URL,
              LOCAL_FILENAME,
              force_download: force_download,
            )

            unless downloaded_file_path && File.exist?(downloaded_file_path)
              log(
                "Failed to download or find technical committees file. Aborting scrape.", 0, :error
              )
              return
            end

            Models::TechnicalCommitteeCollection.from_jsonl(downloaded_file_path)
          rescue StandardError => e # For critical errors from each_jsonl_item itself (e.g., file IO)
            log(
              "Critical error during JSONL processing for technical committees: #{e.message}", 0, :error
            )
            log(
              "Backtrace (JSONL processing):\n#{e.backtrace.take(5).join("\n")}", 1, :error
            )
            # Even if a critical error happens here, processed_count will hold its value
            # The method will then proceed to the final log and return.
          end
        end
      end
    end
  end
end
