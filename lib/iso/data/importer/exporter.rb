# lib/iso/data/importer/exporter.rb
# frozen_string_literal: true

require "yaml"
require "fileutils"

# Assuming models are loaded by the time Exporter is used
require_relative "models/deliverable_collection"
require_relative "models/technical_committee_collection"
require_relative "models/ics_entry_collection"

module Iso
  module Data
    module Importer
      class Exporter
        # Base filenames for collection-level export
        ALL_DELIVERABLES_FILENAME_BASE = "deliverables"
        ALL_TCS_FILENAME_BASE = "committees"
        ALL_ICS_FILENAME_BASE = "ics"

        # The output directory path is now stored in an instance variable
        attr_reader :output_dir

        # The constructor now accepts the output directory path.
        # It defaults to a local "data" directory for development convenience.
        def initialize(output_dir: "data")
          @output_dir = output_dir
          log("Initializing Exporter. Output directory: '#{@output_dir}'", :info)
          ensure_output_directory(@output_dir)
        end

        def ensure_output_directory(dir_path)
          FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
        end

        # Clears the collection output files (only .yaml).
        def clean_output_files
          log("Cleaning collection YAML output files from '#{@output_dir}'...", :info)
          base_filenames = [
            ALL_DELIVERABLES_FILENAME_BASE,
            ALL_TCS_FILENAME_BASE,
            ALL_ICS_FILENAME_BASE,
          ]
          extensions = [".yaml"] # Only YAML

          base_filenames.each do |base_name|
            extensions.each do |ext|
              # Use the instance variable for the path
              filepath_to_remove = File.join(@output_dir, "#{base_name}#{ext}")
              FileUtils.rm_f(filepath_to_remove) if File.exist?(filepath_to_remove)
            end
          end
          log("Collection YAML output files cleaned.", :info)
        end

        # Generic export method for a whole collection to a single YAML file
        def export_collection_to_single_file(collection, base_filename, data_type_name)
          if collection.nil? || (collection.respond_to?(:empty?) && collection.empty?)
            log("No #{data_type_name} to export.", :info)
            return
          end

          collection_size = collection.respond_to?(:size) ? collection.size : "unknown number of"

          file_extension = ".yaml"
          # Use the instance variable for the path
          filepath = File.join(@output_dir, "#{base_filename}#{file_extension}")

          log("Exporting #{collection_size} #{data_type_name} to single file: #{filepath} (format: yaml)...", :info)

          output_string = serialize_collection(collection)
          File.write(filepath, output_string)

          log("#{data_type_name} export (collection file) complete to #{filepath}", :info)
        end

        def export_deliverables(deliverable_collection)
          export_collection_to_single_file(
            deliverable_collection,
            ALL_DELIVERABLES_FILENAME_BASE,
            "Deliverables",
            )
        end

        def export_technical_committees(tc_collection)
          export_collection_to_single_file(
            tc_collection,
            ALL_TCS_FILENAME_BASE,
            "Technical Committees",
            )
        end

        def export_ics_entries(ics_collection)
          export_collection_to_single_file(
            ics_collection,
            ALL_ICS_FILENAME_BASE,
            "ICS Entries",
            )
        end

        private

        def serialize_collection(collection)
          collection.to_yaml
        end

        def log(message, severity = :info)
          prefix = case severity
                   when :error then "ERROR: "
                   when :warn  then "WARN:  "
                   else "INFO:  "
                   end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} Exporter #{prefix}#{message}"
        end
      end
    end
  end
end