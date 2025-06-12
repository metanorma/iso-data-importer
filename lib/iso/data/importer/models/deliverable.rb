require 'lutaml/model'

module Iso
  module Data
    module Importer
      module Models
        class LocalizedPages < Lutaml::Model::Serializable
          attribute :en, :integer
          attribute :fr, :integer

          key_value do
            map 'en', to: :en
            map 'fr', to: :fr
          end
        end

        class LocalizedScope < Lutaml::Model::Serializable
          attribute :en, :string
          attribute :fr, :string

          key_value do
            map 'en', to: :en
            map 'fr', to: :fr
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

          key_value do
            map 'id', to: :id
            map 'deliverableType', to: :deliverable_type
            map 'supplementType', to: :supplement_type
            map 'reference', to: :reference
            map 'publicationDate', to: :publication_date
            map 'edition', to: :edition
            map 'icsCode', to: :ics_codes
            map 'ownerCommittee', to: :owner_committee
            map 'currentStage', to: :current_stage
            map 'replaces', to: :replaces_ids
            map 'replacedBy', to: :replaced_by_ids
            map 'languages', to: :languages
            map 'pages', to: :pages
            map 'scope', to: :scope
          end
        end
      end
    end
  end
end
