# lib/iso/data/importer/parsers/deliverables_parser.rb
# frozen_string_literal: true

require_relative "base_parser"
require_relative "models/deliverable"

module Iso
  module Data
    module Importer
      module Parsers
        class DeliverablesParser < BaseParser
          SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_deliverables_metadata/json/iso_deliverables_metadata.jsonl"
          LOCAL_FILENAME = "iso_deliverables_metadata.jsonl"

          def download(force_download: false)
            log("Starting download for ISO Deliverables...", 0, :info)
            downloaded_file_path = download_file(
              SOURCE_URL,
              LOCAL_FILENAME,
              force_download: force_download,
            )

            unless downloaded_file_path && File.exist?(downloaded_file_path)
              log(
                "Failed to download or find deliverables file. Aborting download.", 0, :error
              )
              return
            end

            contents = IO.read(downloaded_file_path)
            Models::DeliverableCollection.from_jsonl(contents)
          rescue StandardError => e # For critical errors from each_jsonl_item itself (e.g., file IO)
            log(
              "Critical error during JSONL processing for deliverables: #{e.message}", 0, :error
            )
            log(
              "Backtrace (JSONL processing):\n#{e.backtrace.take(5).join("\n")}", 1, :error
            )
            # processed_count will hold its value before this critical error (e.g., 0 if it failed early)
            # The method will then proceed to the final log and return.
          end
        end
      end
    end
  end
end
