# Rakefile
require "bundler/setup"

# This one line loads your main gem file, which in turn loads everything
# else, INCLUDING the crucial LutaML configuration block.
require_relative "lib/iso/data/importer"

require "fileutils" # Keep this one for the clean tasks

namespace :data do
  desc "Fetch all ISO data, process, and export. Accepts force_download, export_format, and output_dir. " \
         "Usage: rake \"data:update_all[true,json,path/to/output]\""
  # Add :output_dir to the task's argument list
  task :update_all, [:force_download, :export_format, :output_dir] do |_task, args|
    puts "=> Starting full data update process..."

    force_download_arg = args[:force_download]
    export_format_arg = args[:export_format]
    # Get the output directory from the arguments, defaulting to "data"
    output_dir_arg = args[:output_dir] || "data"

    force_download = ["true", "t", true].include?(force_download_arg)
    export_format = export_format_arg&.to_sym || :yaml

    puts "  Force Download: #{force_download}"
    puts "  Export Format:  #{export_format}"
    puts "  Output Directory: #{output_dir_arg}"

    orchestrator = Iso::Data::Importer::Orchestrator.new
    # Pass the new output_dir argument to the orchestrator
    success = orchestrator.run_all(
      force_download: force_download,
      output_dir: output_dir_arg,
      )

    if success
      puts "=> Data update completed successfully."
    else
      puts "=> ERROR: Data update failed. Check logs for details."
      exit 1
    end
  end

  desc "Clean all generated YAML/JSON files from the data directory"
  task :clean_output do
    puts "=> Cleaning output data directory..."
    # Initialize with default path for simple clean, or could be parameterized
    exporter = Iso::Data::Importer::Exporter.new
    exporter.clean_output_files
    puts "=> Output data directory cleaned."
  end

  desc "Clean cached downloaded files from the tmp directory"
  task :clean_cache do
    # Assuming this path is correctly defined inside the gem's code
    cache_dir = Iso::Data::Importer::Parsers::BaseParser::TMP_DIR
    if Dir.exist?(cache_dir)
      puts "=> Cleaning cache directory: #{cache_dir}..."
      FileUtils.rm_rf(Dir.glob("#{cache_dir}/*"))
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