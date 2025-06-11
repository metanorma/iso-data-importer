# lib/iso/data/importer/models/technical_committee_collection.rb
# frozen_string_literal: true

require 'lutaml/model'
require 'forwardable'
require_relative 'technical_committee'

module Iso
  module Data
    module Importer
      module Models
        class TechnicalCommitteeCollection < Lutaml::Model::Serializable
          attribute :technical_committees, TechnicalCommittee, collection: true

          key_value do
            map "technical_committees", to: :technical_committees
          end

          def initialize(attributes = {})
            if attributes.is_a?(Array)
              super(technical_committees: attributes)
            else
              super(attributes)
            end
            @technical_committees ||= []
          end

          extend Forwardable
          def_delegators :@technical_committees, :each, :map, :select, :find, :size, :count, :empty?, :[], :first, :last, :<<, :concat
        end
      end
    end
  end
end