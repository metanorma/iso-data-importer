# lib/iso/data/importer/parsers.rb
# frozen_string_literal: true

# Require individual scraper classes
require_relative "parsers/deliverables_parser"
require_relative "parsers/technical_committees_parser"
require_relative "parsers/ics_parser"

# Require collection model classes
require_relative "models/deliverable_collection"
require_relative "models/technical_committee_collection"
require_relative "models/ics_entry_collection"

# We also need the individual item models if we want to be explicit about types,
# though parsers already require them.
require_relative "models/deliverable"
require_relative "models/technical_committee"
require_relative "models/ics_entry"

module Iso
  module Data
    module Importer
      # Top-level module for accessing ISO data parsers and fetching collections.
      module Scrapers
        # Fetch all ISO deliverables and return them as a DeliverableCollection.
        #
        # @param force_download [Boolean] Whether to force re-downloading source files.
        # @return [Iso::Data::Importer::Models::DeliverableCollection] Collection of Deliverable objects.
        def self.fetch_deliverables(force_download: false)
          # Using puts for simple logging; a dedicated logger could be integrated later.
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Starting to fetch ISO Deliverables data..."
          scraper = DeliverablesScraper.new
          collection = scraper.download(force_download: force_download)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Fetched #{collection.size} ISO Deliverables."
          collection
        end

        # Fetch all ISO technical committees and return them as a TechnicalCommitteeCollection.
        #
        # @param force_download [Boolean] Whether to force re-downloading source files.
        # @return [Iso::Data::Importer::Models::TechnicalCommitteeCollection] Collection of TechnicalCommittee objects.
        def self.fetch_technical_committees(force_download: false)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Starting to fetch ISO Technical Committees data..."
          scraper = TechnicalCommitteesScraper.new
          collection = scraper.download(force_download: force_download)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Fetched #{collection.size} ISO Technical Committees."
          collection
        end

        # Fetch all ISO ICS entries and return them as an IcsEntryCollection.
        #
        # @param force_download [Boolean] Whether to force re-downloading source files.
        # @return [Iso::Data::Importer::Models::IcsEntryCollection] Collection of IcsEntry objects.
        def self.fetch_ics_entries(force_download: false)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Starting to fetch ISO ICS data..."
          scraper = IcsScraper.new
          collection = scraper.download(force_download: force_download)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Fetched #{collection.size} ISO ICS entries."
          collection
        end

        # Fetch all available ISO open data.
        #
        # @param force_download [Boolean] Whether to force re-downloading source files.
        # @return [Hash{Symbol => Lutaml::Model::Serializable}] A hash where keys are data types
        #   (e.g., :deliverables) and values are the corresponding collection model objects.
        def self.fetch_all(force_download: false)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Starting to fetch all ISO open data..."

          deliverables_collection = fetch_deliverables(force_download: force_download)
          tc_collection = fetch_technical_committees(force_download: force_download)
          ics_collection = fetch_ics_entries(force_download: force_download)

          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Fetching complete."
          {
            deliverables: deliverables_collection,
            technical_committees: tc_collection,
            ics_entries: ics_collection,
          }
        end
      end
    end
  end
end
