# frozen_string_literal: true

require_relative "lib/iso/data/importer/version"

all_files_in_git = Dir.chdir(File.expand_path(__dir__)) do
  `git ls-files -z`.split("\x0")
end

Gem::Specification.new do |spec|
  spec.name          = "iso-data-importer"
  spec.version       = Iso::Data::Importer::VERSION
  spec.authors = ["Ribose"]
  spec.email = ["open.source@ribose.com"]

  spec.summary = <<~SUMMARY
    Fetches and processes ISO Open Data for deliverables, technical committees, and ICS.
  SUMMARY
  spec.description = <<~DESCRIPTION
    iso-data-importer provides tools to download, parse, and store metadata from
    the ISO Open Data initiative (https://www.iso.org/open-data.html).
    It handles ISO deliverables, technical committees (TCs), and the
    International Classification for Standards (ICS), making this data
    available in a structured YAML format for offline use and integration.
  DESCRIPTION
  spec.homepage      = "https://github.com/metanorma/iso-data-importer"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"

  # Specify which files should be added to the gem when it is released.
  spec.files = all_files_in_git
    .reject { |f| f.match(%r{\A(?:test|features|bin|\.)/}) }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty"
  spec.add_dependency "lutaml-model"
  spec.add_dependency "thor"
end
