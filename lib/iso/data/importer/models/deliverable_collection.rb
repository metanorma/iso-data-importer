# lib/iso/data/importer/models/deliverable_collection.rb
# frozen_string_literal: true

require 'lutaml/model'
require 'forwardable'
require_relative 'deliverable' # Assuming deliverable.rb is in the same directory

module Iso
  module Data
    module Importer
      module Models
        class DeliverableCollection < Lutaml::Model::Serializable
          attribute :deliverables, Deliverable, collection: true

          key_value do
            map "deliverables", to: :deliverables
          end

          def initialize(attributes = {})
            if attributes.is_a?(Array)
              super(deliverables: attributes)
            else
              super(attributes)
            end
            @deliverables ||= [] # Ensure it's an array
          end

          extend Forwardable
          def_delegators :@deliverables, :each, :map, :select, :find, :size, :count, :empty?, :[], :first, :last, :<<, :concat
        end
      end
    end
  end
end