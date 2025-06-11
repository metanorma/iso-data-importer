# frozen_string_literal: true

# This line will require the version file you'll create soon
require_relative "lib/iso/data/importer/version"

Gem::Specification.new do |spec|
  spec.name          = "iso-data-importer"
  spec.version       = Iso::Data::Importer::VERSION # Assumes you'll define this constant
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

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
  spec.homepage      = "https://github.com/metanorma/iso-data-importer" # CHANGE THIS
  spec.license       = "BSD-2-Clause" 

  # Specify a minimum Ruby version. Check what other Metanorma tools use.
  # Ruby 3.0.0 is a reasonable modern choice if not otherwise specified.
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  # Runtime dependencies:
  # For command-line interface (like ietf-data-importer uses Thor)
  spec.add_dependency "thor" # If you plan a CLI similar to ietf-data-importer's `fetch` command

  # For HTTP requests
  spec.add_dependency "httparty"
  spec.add_dependency "lutaml-model"

  # Files to include in the gem package
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    # Includes all files tracked by git, excluding test/spec/features
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  # Directory for executables
  spec.bindir        = "exe" # Changed from 'exe' to 'bin' to match Bundler's default gem skeleton
                               # Or change your directory from bin/ to exe/ to match ietf-data-importer

  spec.executables   = ["iso-data-importer"] # Matches the filename in spec.bindir
                               # Bundler's default (bin/) is fine, or change to exe/ to match ietf-data-importer
  spec.executables   = spec.files.grep(%r{\A(?:bin|exe)/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end