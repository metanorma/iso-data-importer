# lib/iso/data/importer/orchestrator.rb
# frozen_string_literal: true

require_relative "parsers"
require_relative "exporter"
require_relative "models/ics_entry_collection"

module Iso
  module Data
    module Importer
      class Orchestrator
        include Models

        def initialize
          log("Orchestrator initialized.", :info)
        end

        # The run_all method now accepts the output_dir argument
        def run_all(force_download: false, output_dir: "data")
          log("Starting full data import and export run...", :info)
          log("  Force download: #{force_download}", :info)
          log("  Export format: yaml", :info)
          log("  Output directory: #{output_dir}", :info)

          begin
            log("Fetching all data collections...", :info)
            data_collections = Parsers.fetch_all(force_download: force_download)
            log("Data fetching complete.", :info)

            # Pass the output_dir to the Exporter's constructor
            exporter = Exporter.new(output_dir: output_dir)
            exporter.clean_output_files

            log("Exporting deliverables...", :info)
            exporter.export_deliverables(data_collections[:deliverables])

            log("Exporting technical committees...", :info)
            exporter.export_technical_committees(data_collections[:technical_committees])

            log("Exporting ICS entries...", :info)
            flat_ics_array = data_collections[:ics_entries].to_a
            yaml_collection = IcsYamlCollection.new(entries: flat_ics_array)
            exporter.export_ics_entries(yaml_collection)

            log("Data import and export run completed successfully.", :info)
            true
          rescue StandardError => e
            log("FATAL ERROR during orchestrator run: #{e.class} - #{e.message}", :error)
            log("Backtrace (top 10 lines):\n  #{e.backtrace.first(10).join("\n  ")}", :error)
            false
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