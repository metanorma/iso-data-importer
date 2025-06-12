# lib/iso/data/importer/models/ics_entry_collection.rb
# frozen_string_literal: true

require "lutaml/model"

module Iso
  module Data
    module Importer
      module Models
        class LocaleString < Lutaml::Model::Serializable
          attribute :value, :string
          attribute :lang, :string
          xml do
            # namespace 'http://www.w3.org/XML/1998/namespace'
            map_attribute "lang", to: :lang,
                                  namespace: "http://www.w3.org/XML/1998/namespace", prefix: "xml"
            map_content to: :value
          end
        end

        # <field>
        #   <identifier>01</identifier>
        #   <title xml:lang="en">Generalities. Terminology. Standardization. Documentation</title>
        #   <title xml:lang="fr">Généralités. Terminologie. Normalisation. Documentation</title>
        # </field>
        class IcsField < Lutaml::Model::Serializable
          attribute :identifier, :string
          attribute :title, LocaleString, collection: true

          xml do
            root "field"
            map_element "identifier", to: :identifier
            map_element "title", to: :title
          end
        end

        # <reference>
        #   <identifier>01.080.30</identifier>
        #   <note xml:lang="en">Graphical symbols for use on technical drawings</note>
        #   <note xml:lang="fr">Symboles graphiques destinés aux dessins techniques</note>
        # </reference>
        class IcsReference < Lutaml::Model::Serializable
          attribute :identifier, :string
          attribute :note, LocaleString, collection: true
          xml do
            root "reference"
            map_element "identifier", to: :identifier
            map_element "note", to: :note
          end
        end

        class IcsReferenceCollection < Lutaml::Model::Serializable
          attribute :references, IcsReference, collection: true
          xml do
            root "references"
            map_element "reference", to: :references
          end
        end

        # <group>
        #   <identifier>01.100</identifier>
        #   <field>01</field>
        #   <title xml:lang="en">Technical drawings</title>
        #   <title xml:lang="fr">Dessins techniques</title>
        #   <references>
        #     <reference>
        #       <identifier>01.080.30</identifier>
        #       <note xml:lang="en">Graphical symbols for use on technical drawings</note>
        #       <note xml:lang="fr">Symboles graphiques destinés aux dessins techniques</note>
        #     </reference>
        #     <reference>
        #       <identifier>35.240.10</identifier>
        #       <note xml:lang="en">Computer-aided design</note>
        #       <note xml:lang="fr">Dessin assisté par ordinateur</note>
        #     </reference>
        #   </references>
        # </group>
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
        end

        # <subGroup>
        #   <identifier>03.080.20</identifier>
        #   <group>03.080</group>
        #   <title xml:lang="en">Services for companies</title>
        #   <title xml:lang="fr">Services aux entreprises</title>
        #   <scope xml:lang="en">Including publicity, advertising, professional services, recruitment services, management consultancy, outsourcing, etc.</scope>
        #   <scope xml:lang="fr">Y compris publicité, communication, services professionnels, services de recrutement, conseil en gestion, sous-traitance, etc.</scope>
        #   <references>
        #     <reference>
        #       <identifier>03.100.01</identifier>
        #       <note xml:lang="en">Outsourcing as part of a company organization</note>
        #       <note xml:lang="fr">Sous-traitance du point de vue de l'organisation d'une entreprise</note>
        #     </reference>
        #     <reference>
        #       <identifier>03.100.30</identifier>
        #       <note xml:lang="en">Staff training and staff certification</note>
        #       <note xml:lang="fr">Formation et certification du personnel</note>
        #     </reference>
        #   </references>
        # </subGroup>

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
        end

        class IcsEntryCollection < Lutaml::Model::Serializable
          attribute :fields, IcsField, collection: true
          attribute :groups, IcsGroup, collection: true
          attribute :sub_groups, IcsSubGroup, collection: true

          xml do
            root "fields"

            map_element "field", to: :fields
            map_element "group", to: :groups
            map_element "subGroup", to: :sub_groups
          end
        end
      end
    end
  end
end
