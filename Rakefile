# Rakefile
require "bundler/setup" # Ensures all gems from Gemfile are available

# Require the main entry point or the classes needed for the tasks
# If you have a main lib file like `lib/iso-data-importer.rb` that loads everything:
# require "iso-data-importer"
# Otherwise, require the specific classes needed by the tasks:
require_relative "lib/iso/data/importer/orchestrator"
require_relative "lib/iso/data/importer/exporter"
require_relative "lib/iso/data/importer/parsers/base_parser" # For BaseScraper::TMP_DIR
require 'fileutils' # For FileUtils in clean tasks

namespace :data do
  desc "Fetch all ISO data, process, and export. Accepts force_download and export_format. " \
         "Usage: rake \"data:update_all[true,json]\" or rake data:update_all"
  task :update_all, [:force_download, :export_format] do |_task, args|
    puts "=> Starting full data update process..."

    # Parse arguments: rake task arguments are strings
    force_download_arg = args[:force_download]
    export_format_arg = args[:export_format]

    force_download = ["true", "t"].include?(force_download_arg)
    export_format = export_format_arg&.to_sym || :yaml # Default to :yaml if not provided

    puts "  Force Download: #{force_download}"
    puts "  Export Format:  #{export_format}"

    orchestrator = Iso::Data::Importer::Orchestrator.new
    success = orchestrator.run_all(
      force_download: force_download,
    )

    if success
      puts "=> Data update completed successfully."
    else
      puts "=> ERROR: Data update failed. Check logs for details."
      exit 1 # Indicate failure to the shell
    end
  end

  desc "Clean all generated YAML/JSON files from the data directory"
  task :clean_output do
    puts "=> Cleaning output data directory..."
    # Exporter#initialize ensures the base 'data' dir exists
    # Exporter#clean_output_files handles removing specific collection files
    exporter = Iso::Data::Importer::Exporter.new
    exporter.clean_output_files # This now only cleans collection files
    puts "=> Output data directory cleaned."
  end

  desc "Clean cached downloaded files from the tmp directory"
  task :clean_cache do
    cache_dir = Iso::Data::Importer::Parsers::BaseParser::TMP_DIR
    if Dir.exist?(cache_dir)
      puts "=> Cleaning cache directory: #{cache_dir}..."
      # FileUtils.rm_rf(cache_dir) # This would remove the 'tmp/iso_data_cache' dir itself
      # To remove only contents:
      Dir.foreach(cache_dir) do |f|
        fn = File.join(cache_dir, f)
        FileUtils.rm_rf(fn) if f != "." && f != ".." # Avoid deleting . and ..
      end
      # Or more simply if you want to remove everything inside:
      # FileUtils.remove_dir(cache_dir, true) # true to force remove non-empty
      # FileUtils.mkdir_p(cache_dir)          # then recreate it
      puts "=> Cache directory cleaned."
    else
      puts "=> Cache directory #{cache_dir} does not exist. Nothing to clean."
    end
  end

  desc "Clean both output data and cached files"
  task clean: %i[clean_output clean_cache] do
    puts "=> All clean tasks completed."
  end
end

# Set a default task to run when `rake` is called without arguments
task default: "data:update_all"

puts "Rake tasks loaded. Use `rake -T` to see all available tasks."
