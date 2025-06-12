# lib/iso/data/importer/models/technical_committee_collection.rb
# frozen_string_literal: true

require "lutaml/model"
require_relative "technical_committee"

module Iso
  module Data
    module Importer
      module Models
        class TechnicalCommitteeCollection < Lutaml::Model::Collection
          # Define a collection of TechnicalCommittee instances
          instances :technical_committees, TechnicalCommittee

          key_value do
            map_instances to: :technical_committees
          end
        end
      end
    end
  end
end
