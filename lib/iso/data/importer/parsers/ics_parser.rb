# lib/iso/data/importer/parsers/ics_parser.rb
# frozen_string_literal: true

require_relative "base_parser"
require_relative "../models/ics_entry"

module Iso
  module Data
    module Importer
      module Scrapers
        class IcsScraper < BaseScraper
          SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_ics/xml/ICS-simple.xml"
          LOCAL_FILENAME = "ICS-simple.xml"

          def download(force_download: false)
            log("Starting download for ISO ICS data...", 0, :info)
            0

            downloaded_file_path = download_file(
              SOURCE_URL,
              LOCAL_FILENAME,
              force_download: force_download,
            )

            unless downloaded_file_path && File.exist?(downloaded_file_path)
              log("Failed to download or find ICS data file. Aborting download.",
                  0, :error)
              return
            end

            Models::IcsEntryCollection.from_xml(downloaded_file_path)
          rescue StandardError => e
            log(
              "Critical error during CSV processing for ICS data: #{e.message}", 0, :error
            )
            log(
              "Backtrace (CSV processing):\n#{e.backtrace.take(5).join("\n")}", 1, :error
            )
          end
        end
      end
    end
  end
end
