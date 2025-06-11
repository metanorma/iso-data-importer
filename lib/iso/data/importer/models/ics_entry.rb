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

            # Handle parent: store as nil if input is empty string, otherwise store value
            parent_val = attributes['parent']
            self.parent = (parent_val.nil? || parent_val.empty?) ? nil : parent_val

            self.title_en = attributes['titleEn']
            self.title_fr = attributes['titleFr']

            # Handle optional scope fields: store as nil if input is empty string or nil
            scope_en_val = attributes['scopeEn']
            self.scope_en = (scope_en_val.nil? || scope_en_val.empty?) ? nil : scope_en_val

            scope_fr_val = attributes['scopeFr']
            self.scope_fr = (scope_fr_val.nil? || scope_fr_val.empty?) ? nil : scope_fr_val
          end
        end
      end
    end
  end
end