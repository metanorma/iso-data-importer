# spec/iso/data/importer/scrapers_spec.rb
require 'spec_helper'

# Require the main Scrapers module file
require 'iso/data/importer/scrapers'

# Require all model classes (items and collections)
require 'iso/data/importer/models/deliverable'
require 'iso/data/importer/models/deliverable_collection'
require 'iso/data/importer/models/technical_committee'
require 'iso/data/importer/models/technical_committee_collection'
require 'iso/data/importer/models/ics_entry'
require 'iso/data/importer/models/ics_entry_collection'

# Require individual scraper classes for stubbing .new
require 'iso/data/importer/scrapers/deliverables_scraper'
require 'iso/data/importer/scrapers/technical_committees_scraper'
require 'iso/data/importer/scrapers/ics_scraper'

RSpec.describe Iso::Data::Importer::Scrapers do
  # Create mock item model instances for testing
  let(:mock_deliverable1) { instance_double(Iso::Data::Importer::Models::Deliverable, id: 1) }
  let(:mock_deliverable2) { instance_double(Iso::Data::Importer::Models::Deliverable, id: 2) }
  let(:mock_tc1) { instance_double(Iso::Data::Importer::Models::TechnicalCommittee, id: 101) }
  let(:mock_tc2) { instance_double(Iso::Data::Importer::Models::TechnicalCommittee, id: 102) }
  let(:mock_ics1) { instance_double(Iso::Data::Importer::Models::IcsEntry, identifier: "01.020") }
  let(:mock_ics2) { instance_double(Iso::Data::Importer::Models::IcsEntry, identifier: "03.040") }

  # Mock instances of the individual scrapers
  let(:deliverables_scraper_instance) { instance_double(Iso::Data::Importer::Scrapers::DeliverablesScraper) }
  let(:tc_scraper_instance) { instance_double(Iso::Data::Importer::Scrapers::TechnicalCommitteesScraper) }
  let(:ics_scraper_instance) { instance_double(Iso::Data::Importer::Scrapers::IcsScraper) }

  before do
    # Stub the .new method for each scraper class to return our mock instances
    allow(Iso::Data::Importer::Scrapers::DeliverablesScraper).to receive(:new).and_return(deliverables_scraper_instance)
    allow(Iso::Data::Importer::Scrapers::TechnicalCommitteesScraper).to receive(:new).and_return(tc_scraper_instance)
    allow(Iso::Data::Importer::Scrapers::IcsScraper).to receive(:new).and_return(ics_scraper_instance)

    # Default stub for scrape methods: yield nothing, return count 0.
    # Specific tests will override this to simulate yielding data.
    allow(deliverables_scraper_instance).to receive(:scrape).and_return(0)
    allow(tc_scraper_instance).to receive(:scrape).and_return(0)
    allow(ics_scraper_instance).to receive(:scrape).and_return(0)
  end

  describe '.fetch_deliverables' do
    it 'instantiates DeliverablesScraper, calls its scrape method, and returns a DeliverableCollection' do
      # Configure the mock scraper to yield our mock deliverables
      expect(deliverables_scraper_instance).to receive(:scrape) do |&block_param|
        block_param.call(mock_deliverable1)
        block_param.call(mock_deliverable2)
        2 # Simulate scrape returning the count of processed items
      end.with(force_download: false) # Check default argument

      collection = described_class.fetch_deliverables # force_download defaults to false

      expect(collection).to be_an_instance_of(Iso::Data::Importer::Models::DeliverableCollection)
      expect(collection.size).to eq(2)
      # Assuming collection delegates `map` or we access its internal array if it has one named `deliverables`
      expect(collection.map(&:itself)).to contain_exactly(mock_deliverable1, mock_deliverable2)
    end

    it 'passes force_download: true to the scraper' do
      expect(deliverables_scraper_instance).to receive(:scrape)
        .with(force_download: true)
        .and_return(0) # Return value for scrape method
      described_class.fetch_deliverables(force_download: true)
    end
  end

  describe '.fetch_technical_committees' do
    it 'instantiates TechnicalCommitteesScraper, calls its scrape method, and returns a TechnicalCommitteeCollection' do
      expect(tc_scraper_instance).to receive(:scrape) do |&block_param|
        block_param.call(mock_tc1)
        1
      end.with(force_download: false)

      collection = described_class.fetch_technical_committees
      expect(collection).to be_an_instance_of(Iso::Data::Importer::Models::TechnicalCommitteeCollection)
      expect(collection.size).to eq(1)
      expect(collection.map(&:itself)).to contain_exactly(mock_tc1)
    end

    it 'passes force_download: true to the scraper' do
      expect(tc_scraper_instance).to receive(:scrape)
        .with(force_download: true)
        .and_return(0)
      described_class.fetch_technical_committees(force_download: true)
    end
  end

  describe '.fetch_ics_entries' do
    it 'instantiates IcsScraper, calls its scrape method, and returns an IcsEntryCollection' do
      expect(ics_scraper_instance).to receive(:scrape) do |&block_param|
        block_param.call(mock_ics1)
        block_param.call(mock_ics2)
        2
      end.with(force_download: false)

      collection = described_class.fetch_ics_entries
      expect(collection).to be_an_instance_of(Iso::Data::Importer::Models::IcsEntryCollection)
      expect(collection.size).to eq(2)
      expect(collection.map(&:itself)).to contain_exactly(mock_ics1, mock_ics2)
    end

    it 'passes force_download: true to the scraper' do
      expect(ics_scraper_instance).to receive(:scrape)
        .with(force_download: true)
        .and_return(0)
      described_class.fetch_ics_entries(force_download: true)
    end
  end

  describe '.fetch_all' do
    # Mock data for the collections returned by individual fetch methods
    let(:mock_deliverables_collection) { Iso::Data::Importer::Models::DeliverableCollection.new([mock_deliverable1]) }
    let(:mock_tc_collection) { Iso::Data::Importer::Models::TechnicalCommitteeCollection.new([mock_tc1, mock_tc2]) }
    let(:mock_ics_collection) { Iso::Data::Importer::Models::IcsEntryCollection.new([mock_ics1]) }

    before do
      # Stub the module's own fetch methods to return our mock collections
      allow(described_class).to receive(:fetch_deliverables).and_return(mock_deliverables_collection)
      allow(described_class).to receive(:fetch_technical_committees).and_return(mock_tc_collection)
      allow(described_class).to receive(:fetch_ics_entries).and_return(mock_ics_collection)
    end

    it 'calls fetch methods for deliverables, technical_committees, and ics_entries' do
      # Expectations are already set by the `allow(...).to receive(...)` in the before block.
      # We just need to call the method and verify the stubs were hit.
      # Or, more explicitly:
      expect(described_class).to receive(:fetch_deliverables).with(force_download: false).and_return(mock_deliverables_collection)
      expect(described_class).to receive(:fetch_technical_committees).with(force_download: false).and_return(mock_tc_collection)
      expect(described_class).to receive(:fetch_ics_entries).with(force_download: false).and_return(mock_ics_collection)

      described_class.fetch_all # force_download defaults to false
    end

    it 'passes force_download: true to underlying fetch methods' do
      expect(described_class).to receive(:fetch_deliverables).with(force_download: true).and_return(mock_deliverables_collection)
      expect(described_class).to receive(:fetch_technical_committees).with(force_download: true).and_return(mock_tc_collection)
      expect(described_class).to receive(:fetch_ics_entries).with(force_download: true).and_return(mock_ics_collection)

      described_class.fetch_all(force_download: true)
    end

    it 'returns a hash containing all fetched collection objects' do
      # Let the stubs from the `before` block provide the return values
      result = described_class.fetch_all

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly(:deliverables, :technical_committees, :ics_entries)
      expect(result[:deliverables]).to eq(mock_deliverables_collection)
      expect(result[:deliverables].size).to eq(1) # Verify content via collection
      expect(result[:technical_committees]).to eq(mock_tc_collection)
      expect(result[:technical_committees].size).to eq(2)
      expect(result[:ics_entries]).to eq(mock_ics_collection)
      expect(result[:ics_entries].size).to eq(1)
    end
  end
end