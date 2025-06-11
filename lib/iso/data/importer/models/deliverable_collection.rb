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

          # For hash deserialization (e.g., if you were to load a collection from a single JSON/YAML)
          # and for consistent hash representation via .to_h
          key_value do
            map "deliverables", to: :deliverables # Expects a hash like { "deliverables": [...] }
          end

          # Initialize with an array of Deliverable objects
          def initialize(attributes = {})
            # attributes could be a hash like { deliverables: [deliverable1, deliverable2] }
            # or an array directly if we modify how it's called.
            # Lutaml's default initialize should handle the hash with a "deliverables" key.
            if attributes.is_a?(Array) # Allow direct initialization with an array
              super(deliverables: attributes)
            else
              super(attributes)
            end
            @deliverables ||= [] # Ensure it's an array
          end

          # Delegate common array methods to the @deliverables array
          extend Forwardable
          def_delegators :@deliverables, :each, :map, :select, :find, :size, :count, :empty?, :[], :first, :last, :<<, :concat

          # Custom methods for the collection if needed
          # def find_by_reference(ref_string)
          #   @deliverables.find { |d| d.reference == ref_string }
          # end
        end
      end
    end
  end
end