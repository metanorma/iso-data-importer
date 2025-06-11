# lib/iso/data/importer/models/deliverable.rb
require 'lutaml/model'
require 'date' # For Date type coercion

module Iso
  module Data
    module Importer
      module Models
        class LocalizedPages < Lutaml::Model::Serializable
          attribute :en, :integer
          attribute :fr, :integer
          # The key_value block is primarily for Lutaml's own parsing/serialization tools,
          # not necessarily its basic new(hash) initializer.
          # We will handle initialization manually if new(hash) isn't working.
          def initialize(attributes = {})
            super() # Initialize Lutaml base
            self.en = attributes['en'] if attributes.key?('en')
            self.fr = attributes['fr'] if attributes.key?('fr')
          end
        end

        class LocalizedScope < Lutaml::Model::Serializable
          attribute :en, :string
          attribute :fr, :string
          def initialize(attributes = {})
            super() # Initialize Lutaml base
            self.en = attributes['en'] if attributes.key?('en')
            self.fr = attributes['fr'] if attributes.key?('fr')
          end
        end

        class Deliverable < Lutaml::Model::Serializable
          attribute :id, :integer
          attribute :deliverable_type, :string
          attribute :supplement_type, :string
          attribute :reference, :string
          attribute :publication_date, :date
          attribute :edition, :integer
          attribute :ics_codes, :string, collection: true
          attribute :owner_committee, :string
          attribute :current_stage, :integer
          attribute :replaces_ids, :integer, collection: true
          attribute :replaced_by_ids, :integer, collection: true
          attribute :languages, :string, collection: true
          attribute :pages, LocalizedPages
          attribute :scope, LocalizedScope

          # The key_value block is NOT being used by the default new(hash) initializer.
          # We will handle all mapping and assignment explicitly in our `initialize`.
          # key_value do
          #   ...
          # end

          def initialize(raw_json_attributes = {}) # Expects raw JSON hash with camelCase keys
            super() # Call Lutaml's base initialize FIRST, without arguments.

            # --- Explicit Manual Assignment ---
            self.id = raw_json_attributes['id']

            self.deliverable_type = raw_json_attributes['deliverableType']
            self.supplement_type = raw_json_attributes['supplementType']
            self.reference = raw_json_attributes['reference']

            if raw_json_attributes['publicationDate'].is_a?(String) && !raw_json_attributes['publicationDate'].empty?
              self.publication_date = Date.parse(raw_json_attributes['publicationDate'])
            else
              self.publication_date = nil
            end

            self.edition = raw_json_attributes['edition']

            # For collections, assign directly if it's an array, otherwise default to empty array
            self.ics_codes = raw_json_attributes['icsCode'].is_a?(Array) ? raw_json_attributes['icsCode'] : []
            self.owner_committee = raw_json_attributes['ownerCommittee']
            self.current_stage = raw_json_attributes['currentStage']
            self.replaces_ids = raw_json_attributes['replaces'].is_a?(Array) ? raw_json_attributes['replaces'] : []
            self.replaced_by_ids = raw_json_attributes['replacedBy'].is_a?(Array) ? raw_json_attributes['replacedBy'] : []
            self.languages = raw_json_attributes['languages'].is_a?(Array) ? raw_json_attributes['languages'] : []


            # Explicitly instantiate nested models
            if raw_json_attributes['pages'].is_a?(Hash)
              self.pages = LocalizedPages.new(raw_json_attributes['pages'])
            else
              self.pages = nil # Ensure it's nil if "pages" key is absent or not a hash
            end

            if raw_json_attributes['scope'].is_a?(Hash)
              self.scope = LocalizedScope.new(raw_json_attributes['scope'])
            else
              self.scope = nil # Ensure it's nil if "scope" key is absent or not a hash
            end
          end

          # No custom to_yaml_hash, rely on Lutaml's default .to_h for serialization
          # if needed elsewhere. The spec focuses on model state.
        end
      end
    end
  end
end