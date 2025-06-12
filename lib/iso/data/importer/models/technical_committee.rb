# lib/iso/data/importer/models/technical_committee.rb
# (Ensure you have this file name if the class is TechnicalCommittee,
# or rename class to TechnicalCommittee if file is technical_committee.rb)

# frozen_string_literal: true

require 'lutaml/model'

module Iso
  module Data
    module Importer
      module Models
        # Represents a localized string (e.g., for title, scope)
        class LocalizedString < Lutaml::Model::Serializable
          attribute :en, :string
          attribute :fr, :string
        end

        # Represents an organization reference (e.g., for secretariat, members, liaisons)
        class OrganizationReference < Lutaml::Model::Serializable
          attribute :id, :integer
          attribute :acronym, :string
          attribute :reference, :string # Specifically for committeeLiaisons
        end

        # Represents a single ISO Technical Committee or Sub-Committee
        # Consider renaming to TechnicalCommittee for Ruby convention
        class TechnicalCommittee < Lutaml::Model::Serializable
          attribute :id, :integer
          attribute :reference, :string
          attribute :status, :string
          attribute :title, LocalizedString
          attribute :secretariat, OrganizationReference
          attribute :creation_date, :date
          attribute :scope, LocalizedString # Nested model
          attribute :parent_id, :integer
          attribute :children_ids, :integer, collection: true # Collection of integers
          attribute :p_members, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :o_members, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :committee_liaisons, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :organization_liaisons, OrganizationReference, collection: true # Collection of OrganizationReference objects
          attribute :sort_key, :string

          json do
            map 'id', to: :id
            map 'reference', to: :reference
            map 'status', to: :status
            map 'title', to: :title
            map 'secretariat', to: :secretariat
            map 'creationDate', to: :creation_date
            map 'scope', to: :scope
            map 'parentId', to: :parent_id
            map 'childrenId', to: :children_ids
            map 'pMembers', to: :p_members
            map 'oMembers', to: :o_members
            map 'committeeLiaisons', to: :committee_liaisons
            map 'organizationLiaisons', to: :organization_liaisons
            map 'sortKey', to: :sort_key
          end
        end
      end
    end
  end
end
