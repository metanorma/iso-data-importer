# lib/iso/data/importer/models/ics_entry_collection.rb
# frozen_string_literal: true

require "lutaml/model"

module Iso
  module Data
    module Importer
      module Models
        # --- MODELS WITH ADDED YAML/JSON SERIALIZATION RULES ---

        class LocaleString < Lutaml::Model::Serializable
          attribute :value, :string
          attribute :lang, :string
          xml do
            map_attribute "lang", to: :lang,
                          namespace: "http://www.w3.org/XML/1998/namespace", prefix: "xml"
            map_content to: :value
          end
          key_value do
            map "value", to: :value
            map "lang", to: :lang
          end
        end

        class IcsField < Lutaml::Model::Serializable
          attribute :identifier, :string
          attribute :title, LocaleString, collection: true
          xml do
            root "field"
            map_element "identifier", to: :identifier
            map_element "title", to: :title
          end
          key_value do
            map "identifier", to: :identifier
            map "title", to: :title
          end
        end

        class IcsReference < Lutaml::Model::Serializable
          attribute :identifier, :string
          attribute :note, LocaleString, collection: true
          xml do
            root "reference"
            map_element "identifier", to: :identifier
            map_element "note", to: :note
          end
          key_value do
            map "identifier", to: :identifier
            map "note", to: :note
          end
        end

        class IcsReferenceCollection < Lutaml::Model::Serializable
          attribute :references, IcsReference, collection: true
          xml do
            root "references"
            map_element "reference", to: :references
          end
          key_value do
            map_instances to: :references
          end
        end

        class IcsGroup < Lutaml::Model::Serializable
          attribute :identifier, :string
          attribute :field, :string
          attribute :title, LocaleString, collection: true
          attribute :scope, LocaleString, collection: true
          attribute :references, IcsReferenceCollection
          xml do
            root "group"
            map_element "identifier", to: :identifier
            map_element "field", to: :field
            map_element "title", to: :title
            map_element "scope", to: :scope
            map_element "references", to: :references
          end
          key_value do
            map "identifier", to: :identifier
            map "field", to: :field
            map "title", to: :title
            map "scope", to: :scope
            map "references", to: :references
          end
        end

        class IcsSubGroup < Lutaml::Model::Serializable
          attribute :identifier, :string
          attribute :group, :string
          attribute :title, LocaleString, collection: true
          attribute :scope, LocaleString, collection: true
          attribute :references, IcsReferenceCollection
          xml do
            root "subGroup"
            map_element "identifier", to: :identifier
            map_element "group", to: :group
            map_element "title", to: :title
            map_element "scope", to: :scope
            map_element "references", to: :references
          end
          key_value do
            map "identifier", to: :identifier
            map "group", to: :group
            map "title", to: :title
            map "scope", to: :scope
            map "references", to: :references
          end
        end

        # This class correctly PARSES the complex, heterogeneous XML file.
        # It remains unchanged from our previous fix.
        class IcsEntryCollection < Lutaml::Model::Serializable
          include Enumerable
          attribute :fields, IcsField, collection: true
          attribute :groups, IcsGroup, collection: true
          attribute :sub_groups, IcsSubGroup, collection: true

          def each(&block)
            (fields + groups + sub_groups).each(&block)
          end

          def size
            (fields&.size || 0) + (groups&.size || 0) + (sub_groups&.size || 0)
          end

          xml do
            root "fields"
            map_element "field", to: :fields
            map_element "group", to: :groups
            map_element "subGroup", to: :sub_groups
          end
        end

        # --- NEW SERIALIZER WRAPPER CLASS ---

        # This is a special-purpose class whose ONLY job is to correctly
        # serialize the flat array of ICS entries into a clean YAML list.
        # It acts as a "smart" wrapper around a plain array.
        class IcsYamlCollection < Lutaml::Model::Serializable
          # This attribute holds the flat array of mixed ICS entry types.
          # `polymorphic: true` is important because the array contains different
          # classes (IcsField, IcsGroup, IcsSubGroup).
          attribute :entries, Lutaml::Model::Serializable, collection: true,
                    polymorphic: true

          key_value do
            # This tells LutaML to NOT wrap the output in an "entries:" key.
            # This ensures the YAML output is a root-level list.
            no_root

            # This tells LutaML to serialize the contents of the `entries`
            # attribute as a flat list, using the `key_value` blocks
            # defined in each of the individual item classes.
            map_instances to: :entries
          end
        end

      end
    end
  end
end