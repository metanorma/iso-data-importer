# lib/iso/data/importer/exporter.rb
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'json'

# Assuming models are loaded by the time Exporter is used
require_relative 'models/deliverable_collection'
require_relative 'models/technical_committee_collection'
require_relative 'models/ics_entry_collection'

module Iso
  module Data
    module Importer
      class Exporter
        DATA_OUTPUT_DIR = "data" # Root directory for YAML/JSON output

        # Base filenames for collection-level export
        ALL_DELIVERABLES_FILENAME_BASE = "deliverables"
        ALL_TCS_FILENAME_BASE = "committees"
        ALL_ICS_FILENAME_BASE = "ics"

        def initialize
          log("Initializing Exporter and ensuring base output directory exists...", :info)
          ensure_output_directory(DATA_OUTPUT_DIR)
        end

        def ensure_output_directory(dir_path)
          FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
        end

        # Clears the collection output files (both .yaml and .json).
        def clean_output_files
          log("Cleaning collection output files from #{DATA_OUTPUT_DIR}...", :info)
          base_filenames = [ALL_DELIVERABLES_FILENAME_BASE, ALL_TCS_FILENAME_BASE, ALL_ICS_FILENAME_BASE]
          extensions = [".yaml", ".json"]

          base_filenames.each do |base_name|
            extensions.each do |ext|
              filepath_to_remove = File.join(self.class::DATA_OUTPUT_DIR, "#{base_name}#{ext}")
              FileUtils.rm_f(filepath_to_remove)
            end
          end
          log("Collection output files cleaned.", :info)
        end

        # Generic export method for a whole collection to a single file
        def export_collection_to_single_file(collection, base_filename, data_type_name, format: :yaml)
          # Check if collection is nil or empty using respond_to? for safety with doubles in tests
          if collection.nil? || (collection.respond_to?(:empty?) && collection.empty?) || (collection.respond_to?(:size) && collection.size == 0)
            log("No #{data_type_name} to export.", :info)
            return
          end

          # Ensure collection responds to size for logging, if not already checked
          collection_size = collection.respond_to?(:size) ? collection.size : "unknown number of"

          file_extension = format == :json ? ".json" : ".yaml"
          filepath = File.join(self.class::DATA_OUTPUT_DIR, "#{base_filename}#{file_extension}")

          log("Exporting #{collection_size} #{data_type_name} to single file: #{filepath} (format: #{format})...", :info)

          output_string = serialize_collection(collection, format)
          File.write(filepath, output_string)

          log("#{data_type_name} export (collection file, #{format}) complete to #{filepath}", :info)
        end

        def export_deliverables(deliverable_collection, format: :yaml)
          export_collection_to_single_file(
            deliverable_collection,
            ALL_DELIVERABLES_FILENAME_BASE,
            "Deliverables",
            format: format
          )
        end

        def export_technical_committees(tc_collection, format: :yaml)
          export_collection_to_single_file(
            tc_collection,
            ALL_TCS_FILENAME_BASE,
            "Technical Committees",
            format: format
          )
        end

        def export_ics_entries(ics_collection, format: :yaml)
          export_collection_to_single_file(
            ics_collection,
            ALL_ICS_FILENAME_BASE,
            "ICS Entries",
            format: format
          )
        end

        private

        def serialize_collection(collection, format)
          case format.to_sym
          when :yaml
            # Relies on collection responding to .to_yaml or .to_h (Lutaml default)
            collection.respond_to?(:to_yaml) ? collection.to_yaml : collection.to_h.to_yaml
          when :json
            collection.respond_to?(:to_json) ? collection.to_json : collection.to_h.to_json
          else
            raise ArgumentError, "Unsupported export format: #{format}"
          end
        end

        def log(message, severity = :info)
          prefix = case severity
                   when :error then "ERROR: "
                   when :warn  then "WARN:  "
                   else            "INFO:  "
                   end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{prefix}#{message}"
        end
      end
    end
  end
end