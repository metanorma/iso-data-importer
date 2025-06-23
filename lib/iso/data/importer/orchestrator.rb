# lib/iso/data/importer/orchestrator.rb
# frozen_string_literal: true

require_relative "parsers"
require_relative "exporter"
# We need to be able to access the Models module
require_relative "models/ics_entry_collection"

module Iso
  module Data
    module Importer
      class Orchestrator
        include Models # Makes `IcsYamlCollection` available without a prefix

        def initialize
          log("Orchestrator initialized.", :info)
        end

        def run_all(force_download: false)
          log("Starting full data import and export run...", :info)
          log("  Force download: #{force_download}", :info)
          log("  Export format: yaml", :info)

          begin
            log("Fetching all data collections...", :info)
            data_collections = Parsers.fetch_all(force_download: force_download)
            log("Data fetching complete.", :info)

            exporter = Exporter.new
            exporter.clean_output_files

            log("Exporting deliverables...", :info)
            exporter.export_deliverables(data_collections[:deliverables])

            log("Exporting technical committees...", :info)
            exporter.export_technical_committees(data_collections[:technical_committees])

            # --- START OF THE FINAL FIX ---
            log("Exporting ICS entries...", :info)

            # Step 1: Get the flat array of all ICS objects from our parser collection.
            flat_ics_array = data_collections[:ics_entries].to_a

            # Step 2: Create an instance of our new "smart" serializer wrapper.
            # This wrapper knows how to produce clean YAML.
            yaml_collection = IcsYamlCollection.new(entries: flat_ics_array)

            # Step 3: Pass this smart LutaML object to the exporter.
            exporter.export_ics_entries(yaml_collection)
            # --- END OF THE FINAL FIX ---

            log("Data import and export run completed successfully.", :info)
            true # Indicate success
          rescue StandardError => e
            log(
              "FATAL ERROR during orchestrator run: #{e.class} - #{e.message}", :error
            )
            log(
              "Backtrace (top 10 lines):\n  #{e.backtrace.first(10).join("\n  ")}", :error
            )
            false # Indicate failure
          end
        end

        private

        def log(message, severity = :info)
          prefix = case severity
                   when :error then "ERROR: "
                   when :warn  then "WARN:  "
                   else "INFO:  "
                   end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} Orchestrator #{prefix}#{message}"
        end
      end
    end
  end
end