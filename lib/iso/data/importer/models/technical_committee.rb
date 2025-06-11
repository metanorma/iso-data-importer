# lib/iso/data/importer/models/technical_committee.rb
# (Ensure you have this file name if the class is TechnicalCommittee,
# or rename class to TechnicalCommittee if file is technical_committee.rb)

# frozen_string_literal: true

require "lutaml/model"
require "date" # For Date type coercion

module Iso
  module Data
    module Importer
      module Models
        # Represents a localized string (e.g., for title, scope)
        class LocalizedString < Lutaml::Model::Serializable
          attribute :en, :string
          attribute :fr, :string # Add other languages if observed in data

          def initialize(attributes = {})
            super() # Initialize Lutaml base
            # Explicitly assign from input hash, assuming keys match attribute names
            self.en = attributes['en'] if attributes.key?('en')
            self.fr = attributes['fr'] if attributes.key?('fr')
            # Add other languages here if defined as attributes
          end
        end

        # Represents an organization reference (e.g., for secretariat, members, liaisons)
        class OrganizationReference < Lutaml::Model::Serializable
          attribute :id, :integer
          attribute :acronym, :string
          attribute :reference, :string # Specifically for committeeLiaisons

          def initialize(attributes = {})
            super() # Initialize Lutaml base
            self.id = attributes['id'] if attributes.key?('id')
            self.acronym = attributes['acronym'] if attributes.key?('acronym')
            self.reference = attributes['reference'] if attributes.key?('reference')
          end
        end

        # Represents a single ISO Technical Committee or Sub-Committee
        # Consider renaming to TechnicalCommittee for Ruby convention
        class TechnicalCommittee < Lutaml::Model::Serializable
          attribute :id, :integer
          attribute :reference, :string
          attribute :status, :string # Consider adding `values: %w[Active Suspended]` if validation desired
          attribute :title, LocalizedString # Nested model
          attribute :secretariat, OrganizationReference # Nested model
          attribute :creation_date, :date
          attribute :scope, LocalizedString # Nested model
          attribute :parent_id, :integer
          attribute :children_ids, :integer, collection: true # Collection of integers
          attribute :p_members, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :o_members, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :committee_liaisons, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :organization_liaisons, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :sort_key, :string

          # The key_value block is NOT used by new(hash) as we've established.
          # It's kept here for documentation or other Lutaml tools.
          # key_value do
          #   map "id", to: :id
          #   map "reference", to: :reference
          #   map "status", to: :status
          #   map "title", to: :title # Lutaml would expect to call LocalizedString.new(value)
          #   map "secretariat", to: :secretariat # Lutaml would expect to call OrganizationReference.new(value)
          #   map "creationDate", to: :creation_date
          #   map "scope", to: :scope
          #   map "parentId", to: :parent_id
          #   map "childrenId", to: :children_ids # Maps the array from "childrenId"
          #   map "pMembers", to: :p_members # Maps array of hashes to collection of OrganizationReference
          #   map "oMembers", to: :o_members
          #   map "committeeLiaisons", to: :committee_liaisons
          #   map "organizationLiaisons", to: :organization_liaisons
          #   map "sortKey", to: :sort_key
          # end

          def initialize(raw_json_attributes = {})
            super() # Initialize Lutaml base first

            self.id = raw_json_attributes['id']
            self.reference = raw_json_attributes['reference']
            self.status = raw_json_attributes['status']

            if raw_json_attributes['title'].is_a?(Hash)
              self.title = LocalizedString.new(raw_json_attributes['title'])
            else
              self.title = nil # Or LocalizedString.new if you always want an object
            end

            if raw_json_attributes['secretariat'].is_a?(Hash)
              self.secretariat = OrganizationReference.new(raw_json_attributes['secretariat'])
            else
              self.secretariat = nil
            end

            if raw_json_attributes['creationDate'].is_a?(String) && !raw_json_attributes['creationDate'].empty?
              self.creation_date = Date.parse(raw_json_attributes['creationDate'])
            else
              self.creation_date = nil
            end

            if raw_json_attributes['scope'].is_a?(Hash)
              self.scope = LocalizedString.new(raw_json_attributes['scope'])
            else
              self.scope = nil # Or LocalizedString.new
            end

            self.parent_id = raw_json_attributes['parentId']
            # JSON key "childrenId" maps to attribute children_ids
            self.children_ids = raw_json_attributes['childrenId'].is_a?(Array) ? raw_json_attributes['childrenId'] : []

            # For collections of nested objects:
            self.p_members = map_to_organization_references(raw_json_attributes['pMembers'])
            self.o_members = map_to_organization_references(raw_json_attributes['oMembers'])
            self.committee_liaisons = map_to_organization_references(raw_json_attributes['committeeLiaisons'])
            self.organization_liaisons = map_to_organization_references(raw_json_attributes['organizationLiaisons'])

            self.sort_key = raw_json_attributes['sortKey']
          end

          private

          def map_to_organization_references(array_of_hashes)
            return [] unless array_of_hashes.is_a?(Array)
            array_of_hashes.map { |hash_data| OrganizationReference.new(hash_data) }
          end
        end
      end
    end
  end
end