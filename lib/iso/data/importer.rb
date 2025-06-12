# frozen_string_literal: true

require_relative 'importer/version'

module Iso
  module Data
    module Importer
      class Error < StandardError; end
      # Your code goes here...
    end
  end
end

require_relative 'importer/models/ics_entry_collection'
require_relative 'importer/models/technical_committee_collection'
require_relative 'importer/models/deliverable_collection'

require 'lutaml/model'
require 'lutaml/model/xml/nokogiri_adapter'
require 'lutaml/model/json/standard_adapter'
require 'lutaml/model/yaml/standard_adapter'

Lutaml::Model::Config.configure do |config|
  config.xml_adapter = Lutaml::Model::Xml::NokogiriAdapter
  config.yaml_adapter = Lutaml::Model::Yaml::StandardAdapter
  config.json_adapter = Lutaml::Model::Json::StandardAdapter
end
