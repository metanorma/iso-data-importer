# lib/iso/data/importer/orchestrator.rb
# frozen_string_literal: true

require_relative "parsers"
require_relative "exporter"

module Iso
  module Data
    module Importer
      class Orchestrator
        def initialize
          log("Orchestrator initialized.", :info)
        end

        def run_all(force_download: false)
          log("Starting full data import and export run...", :info)
          log("  Force download: #{force_download}", :info)
          log("  Export format: yaml", :info) # Updated log message

          begin
            log("Fetching all data collections...", :info)
            data_collections = Parsers.fetch_all(force_download: force_download)
            log("Data fetching complete.", :info)

            # Instantiate Exporter and clean files only AFTER successful fetch
            exporter = Exporter.new
            exporter.clean_output_files # Uses Exporter's default cleaning (collection files)

            log("Exporting deliverables...", :info)
            exporter.export_deliverables(data_collections[:deliverables])

            log("Exporting technical committees...", :info)
            exporter.export_technical_committees(
              data_collections[:technical_committees])

            log("Exporting ICS entries...", :info)
            exporter.export_ics_entries(data_collections[:ics_entries].to_a)

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
