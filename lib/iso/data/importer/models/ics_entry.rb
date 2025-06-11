# lib/iso/data/importer/models/ics_entry.rb
# frozen_string_literal: true

require "lutaml/model"

module Iso
  module Data
    module Importer
      module Models
        class IcsEntry < Lutaml::Model::Serializable
          attribute :identifier, :string
          attribute :parent, :string
          attribute :title_en, :string
          attribute :title_fr, :string
          attribute :scope_en, :string
          attribute :scope_fr, :string

          def initialize(attributes = {})
            super()

            self.identifier = attributes['identifier']

            parent_val = attributes['parent']
            self.parent = parent_val.blank? ? nil : parent_val # Assumes ActiveSupport's blank? or similar

            self.title_en = attributes['titleEn']
            self.title_fr = attributes['titleFr']

            scope_en_val = attributes['scopeEn']
            self.scope_en = scope_en_val.blank? ? nil : scope_en_val

            scope_fr_val = attributes['scopeFr']
            self.scope_fr = scope_fr_val.blank? ? nil : scope_fr_val
          end
        end
      end
    end
  end
end