# lib/iso/data/importer/cli.rb
# frozen_string_literal: true

require 'thor'
require_relative 'orchestrator'

module Iso
  module Data
    module Importer
      class CLI < Thor
        # Define package_name for Thor's help messages
        def self.package_name
          "iso-data-importer"
        end

        # Ensures that exit status is 1 on failure, for scripting.
        def self.exit_on_failure?
          true
        end

        # Default task if no command is specified (optional)
        # desc "help", "Shows help"
        # def help(command = nil)
        #   super
        # end
        # default_task :help

        desc "update_all", "Fetches all ISO data, processes it, and exports to YAML/JSON files."
        method_option :force_download,
                      aliases: "-f",
                      type: :boolean,
                      default: false,
                      desc: "Force re-downloading of source files, ignoring cache."
        method_option :format,
                      aliases: "-o", # o for output format
                      type: :string,
                      default: 'yaml',
                      enum: %w[yaml json],
                      desc: "Output format for exported files (yaml or json)."
        def update_all
          puts "Initializing ISO Data Importer CLI..."
          puts "Options:"
          puts "  Force Download: #{options[:force_download]}"
          puts "  Export Format:  #{options[:format]}"
          puts "---"

          orchestrator = Orchestrator.new
          success = orchestrator.run_all(
            force_download: options[:force_download],
            export_format: options[:format].to_sym # Convert string option to symbol
          )

          if success
            puts "---"
            puts "Data import process completed successfully."
          else
            puts "---"
            STDERR.puts "ERROR: Data import process failed. Check logs above for details."
          end
        end

        desc "clean", "Cleans cached files and/or output data files."
        method_option :cache,
                      type: :boolean,
                      default: false,
                      desc: "Clean only the cached downloaded files from tmp/."
        method_option :output,
                      type: :boolean,
                      default: false,
                      desc: "Clean only the generated YAML/JSON files from data/."
        method_option :all,
                      type: :boolean,
                      default: true, # If no specific flag, clean all by default with this task
                      desc: "Clean both cache and output files (default if no other flag specified)."
        def clean
          cleaned_something = false

          # Determine what to clean
          clean_cache = options[:cache]
          clean_output = options[:output]
          clean_all_if_no_specific = options[:all] && !options[:cache] && !options[:output]

          if clean_all_if_no_specific || clean_cache
            puts "Cleaning cached files..."
            require_relative 'scrapers/base_scraper' # For BaseScraper::TMP_DIR
            cache_dir = Iso::Data::Importer::Scrapers::BaseScraper::TMP_DIR
            if Dir.exist?(cache_dir)
              Dir.foreach(cache_dir) do |f|
                fn = File.join(cache_dir, f)
                FileUtils.rm_rf(fn) if f != '.' && f != '..'
              end
              puts "Cache directory cleaned: #{cache_dir}"
            else
              puts "Cache directory not found: #{cache_dir}"
            end
            cleaned_something = true
          end

          if clean_all_if_no_specific || clean_output
            puts "Cleaning output files..."
            exporter = Exporter.new # Exporter knows how to clean its output
            exporter.clean_output_files
            puts "Output files cleaned from data/ directory."
            cleaned_something = true
          end

          puts "Clean operation finished." if cleaned_something
          puts "No specific clean operation selected. Use --cache, --output, or --all (default)." unless cleaned_something
        end

        # You might want a version command
        desc "version", "Prints the gem version"
        def version
          require_relative 'version'
          puts Iso::Data::Importer::VERSION
        end

      end
    end
  end
end