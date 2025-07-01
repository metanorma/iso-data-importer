# lib/iso/data/importer/scrapers.rb
# frozen_string_literal: true

# Require individual scraper classes
require_relative "scrapers/deliverables_scraper"
require_relative "scrapers/technical_committees_scraper"
require_relative "scrapers/ics_scraper"

# Require collection model classes
require_relative "models/deliverable_collection"
require_relative "models/technical_committee_collection"
require_relative "models/ics_entry_collection"

# We also need the individual item models if we want to be explicit about types,
# though scrapers already require them.
require_relative "models/deliverable"
require_relative "models/technical_committee"
require_relative "models/ics_entry"


module Iso
  module Data
    module Importer
      # Top-level module for accessing ISO data scrapers and fetching collections.
      module Scrapers
        # Fetch all ISO deliverables and return them as a DeliverableCollection.
        #
        # @param force_download [Boolean] Whether to force re-downloading source files.
        # @return [Iso::Data::Importer::Models::DeliverableCollection] Collection of Deliverable objects.
        def self.fetch_deliverables(force_download: false)
          # Using puts for simple logging; a dedicated logger could be integrated later.
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Starting to fetch ISO Deliverables data..."
          scraper = DeliverablesScraper.new
          deliverables_array = []
          scraper.scrape(force_download: force_download) do |deliverable|
            deliverables_array << deliverable
          end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Fetched #{deliverables_array.size} ISO Deliverables."
          Models::DeliverableCollection.new(deliverables_array)
        end

        # Fetch all ISO technical committees and return them as a TechnicalCommitteeCollection.
        #
        # @param force_download [Boolean] Whether to force re-downloading source files.
        # @return [Iso::Data::Importer::Models::TechnicalCommitteeCollection] Collection of TechnicalCommittee objects.
        def self.fetch_technical_committees(force_download: false)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Starting to fetch ISO Technical Committees data..."
          scraper = TechnicalCommitteesScraper.new
          committees_array = []
          scraper.scrape(force_download: force_download) do |committee|
            committees_array << committee
          end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Fetched #{committees_array.size} ISO Technical Committees."
          Models::TechnicalCommitteeCollection.new(committees_array)
        end

        # Fetch all ISO ICS entries and return them as an IcsEntryCollection.
        #
        # @param force_download [Boolean] Whether to force re-downloading source files.
        # @return [Iso::Data::Importer::Models::IcsEntryCollection] Collection of IcsEntry objects.
        def self.fetch_ics_entries(force_download: false)
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Starting to fetch ISO ICS data..."
          scraper = IcsScraper.new
          ics_entries_array = []
          scraper.scrape(force_download: force_download) do |ics_entry|
            ics_entries_array << ics_entry
          end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} INFO:  Fetched #{ics_entries_array.size} ISO ICS entries."
          Models::IcsEntryCollection.new(ics_entries_array)
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
            ics_entries: ics_collection
          }
        end
      end
    end
  end
end