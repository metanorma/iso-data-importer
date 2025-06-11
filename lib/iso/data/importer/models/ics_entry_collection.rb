# lib/iso/data/importer/models/ics_entry_collection.rb
# frozen_string_literal: true

require 'lutaml/model'
require 'forwardable'
require_relative 'ics_entry'

module Iso
  module Data
    module Importer
      module Models
        class IcsEntryCollection < Lutaml::Model::Serializable
          attribute :ics_entries, IcsEntry, collection: true

          key_value do
            map "ics_entries", to: :ics_entries
          end

          def initialize(attributes = {})
            if attributes.is_a?(Array)
              super(ics_entries: attributes)
            else
              super(attributes)
            end
            @ics_entries ||= []
          end

          extend Forwardable
          def_delegators :@ics_entries, :each, :map, :select, :find, :size, :count, :empty?, :[], :first, :last, :<<, :concat
        end
      end
    end
  end
end