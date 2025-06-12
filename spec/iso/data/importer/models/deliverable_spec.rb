# spec/iso/data/importer/models/deliverable_spec.rb
require "spec_helper"
require "json"
require "date"
require "iso/data/importer/models/deliverable"

RSpec.describe Iso::Data::Importer::Models::Deliverable do
  let(:fixture_path) do
    File.join(__dir__, "../../../../fixtures/iso_deliverables_metadata.jsonl")
  end

  # Helper to get a specific line's parsed JSON data from the fixture.
  def get_fixture_data(line_number)
    line_content = File.readlines(fixture_path)[line_number - 1]
    raise "Fixture line #{line_number} not found or file empty." if line_content.nil?

    JSON.parse(line_content)
  end

  # --- Test Data Scenarios from Provided Fixture Lines ---

  # Scenario 1: Using Line 2 - has a date, some collections, nulls, and pages/scope with only 'en'
  # {"id":3,"deliverableType":"R","supplementType":null,"reference":"ISO/R 102:1959","publicationDate":"1959-01-01",
  # "edition":1,"icsCode":null,"ownerCommittee":"ISO/TMBG","currentStage":9599,"replaces":null,"replacedBy":null,
  # "languages":["en","fr"],"pages":{"en":1},"scope":{"en":null}}
  context "when initialized with data from fixture line 2 (mixed content)" do
    # Line 2 from your provided snippet
    let(:fixture_data) do
      get_fixture_data(2)
    end
    subject(:deliverable) { described_class.new(fixture_data) }

    it 'correctly maps "id"' do
      expect(deliverable.id).to eq(3)
    end

    it 'correctly maps "deliverableType"' do
      expect(deliverable.deliverable_type).to eq("R")
    end

    it 'correctly maps "supplementType" (which is null)' do
      expect(deliverable.supplement_type).to be_nil
    end

    it 'correctly maps "reference"' do
      expect(deliverable.reference).to eq("ISO/R 102:1959")
    end

    it 'correctly maps and parses "publicationDate"' do
      expect(deliverable.publication_date).to eq(Date.new(1959, 1, 1))
    end

    it 'correctly maps "edition"' do
      expect(deliverable.edition).to eq(1)
    end

    it 'correctly maps "icsCode" (null in JSON) to an empty array' do
      expect(deliverable.ics_codes).to eq([])
    end

    it 'correctly maps "ownerCommittee"' do
      expect(deliverable.owner_committee).to eq("ISO/TMBG")
    end

    it 'correctly maps "currentStage"' do
      expect(deliverable.current_stage).to eq(9599)
    end

    it 'correctly maps "replaces" (null in JSON) to :replaces_ids as an empty array' do
      expect(deliverable.replaces_ids).to eq([])
    end

    it 'correctly maps "replacedBy" (null in JSON) to :replaced_by_ids as an empty array' do
      expect(deliverable.replaced_by_ids).to eq([])
    end

    it 'correctly maps "languages" to :languages (collection)' do
      expect(deliverable.languages).to contain_exactly("en", "fr")
    end

    describe 'nested :pages attribute (from {"en":1})' do
      it "is an instance of LocalizedPages" do
        expect(deliverable.pages).to be_an_instance_of(Iso::Data::Importer::Models::LocalizedPages)
      end

      it "has correctly mapped :en page count" do
        expect(deliverable.pages.en).to eq(1)
      end

      it 'has :fr page count as nil (since "fr" key was absent in pages hash)' do
        expect(deliverable.pages.fr).to be_nil
      end
    end

    describe 'nested :scope attribute (from {"en":null})' do
      it "is an instance of LocalizedScope" do
        expect(deliverable.scope).to be_an_instance_of(Iso::Data::Importer::Models::LocalizedScope)
      end

      it "has :en scope text as nil" do
        expect(deliverable.scope.en).to be_nil
      end

      it 'has :fr scope text as nil (since "fr" key was absent in scope hash)' do
        expect(deliverable.scope.fr).to be_nil
      end
    end
  end

  # Scenario 2: Using Line 1 - many nulls, pages/scope with only 'en' and null value
  # {"id":2,"deliverableType":"IS","supplementType":null,"reference":"ISO/WD 0","publicationDate":null,
  # "edition":1,"icsCode":null,"ownerCommittee":"ISO/TC 22","currentStage":2098,"replaces":null,"replacedBy":null,
  # "languages":null,"pages":{"en":null},"scope":{"en":null}}
  context "when initialized with data from fixture line 1 (many nulls)" do
    # Line 1 from your provided snippet
    let(:fixture_data) do
      get_fixture_data(1)
    end
    subject(:deliverable) { described_class.new(fixture_data) }

    it "assigns nil to :publication_date from JSON null" do
      expect(deliverable.publication_date).to be_nil
    end

    it "assigns an empty array to :ics_codes from JSON null" do
      expect(deliverable.ics_codes).to eq([])
    end

    it "assigns an empty array to :languages from JSON null" do
      expect(deliverable.languages).to eq([])
    end

    describe 'nested :pages attribute (from JSON {"en": null})' do
      it "is an instance of LocalizedPages" do
        expect(deliverable.pages).to be_an_instance_of(Iso::Data::Importer::Models::LocalizedPages)
      end

      it ":en page count is nil" do
        expect(deliverable.pages.en).to be_nil
      end
    end

    describe 'nested :scope attribute (from JSON {"en": null})' do
      it "is an instance of LocalizedScope" do
        expect(deliverable.scope).to be_an_instance_of(Iso::Data::Importer::Models::LocalizedScope)
      end

      it ":en scope text is nil" do
        expect(deliverable.scope.en).to be_nil
      end
    end
  end

  # Scenario 3: Testing with absent optional keys (using a manually defined hash for this)
  # The provided fixture lines seem to always include all keys, even if values are null.
  context "when initialized with JSON data where optional keys are absent" do
    let(:absent_keys_json_string) do
      '{"id":100,"deliverableType":"TR","reference":"ISO/XYZ 123"}'
    end
    let(:absent_keys_hash) { JSON.parse(absent_keys_json_string) }
    subject(:deliverable) { described_class.new(absent_keys_hash) }

    it "assigns provided attributes correctly" do
      expect(deliverable.id).to eq(100)
      expect(deliverable.deliverable_type).to eq("TR")
      expect(deliverable.reference).to eq("ISO/XYZ 123")
    end

    it "assigns nil to simple attributes for absent keys" do
      expect(deliverable.supplement_type).to be_nil
      expect(deliverable.publication_date).to be_nil
      expect(deliverable.edition).to be_nil
      expect(deliverable.owner_committee).to be_nil
      expect(deliverable.current_stage).to be_nil
    end

    it "assigns empty arrays to collection attributes for absent keys" do
      expect(deliverable.ics_codes).to eq([])
      expect(deliverable.replaces_ids).to eq([])
      expect(deliverable.replaced_by_ids).to eq([])
      expect(deliverable.languages).to eq([])
    end

    it "assigns nil to nested object attributes for absent keys" do
      expect(deliverable.pages).to be_nil
      expect(deliverable.scope).to be_nil
    end
  end
end
