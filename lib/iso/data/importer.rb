# lib/iso/data/importer.rb
# frozen_string_literal: true

# --- SETUP AND CONFIGURATION FIRST ---
require "lutaml/model"

# This configuration block MUST run before any models are loaded.
Lutaml::Model::Config.configure do |config|
  config.xml_adapter_type = :nokogiri
  config.yaml_adapter_type = :standard_yaml
  config.json_adapter_type = :standard_json
end

# --- NOW, LOAD THE REST OF THE GEM'S CODE ---
require_relative "importer/version"

module Iso
  module Data
    module Importer
      class Error < StandardError; end
      # Your code goes here...
    end
  end
end

require_relative "importer/models/ics_entry_collection"
require_relative "importer/models/technical_committee_collection"
require_relative "importer/models/deliverable_collection"

# It's also good practice to load the rest of your files here too
require_relative "importer/cli"
require_relative "importer/orchestrator"