# spec/iso/data/importer/models/technical_committee_spec.rb
require "spec_helper"
require "json"
require "date"
require "iso/data/importer/models/technical_committee"

RSpec.describe Iso::Data::Importer::Models::TechnicalCommittee do # Or TechnicalCommittee
  let(:fixture_path) do
    File.join(__dir__, "../../../../fixtures/iso_technical_committees.jsonl")
  end
  # Memoize
  let!(:all_fixture_data) do
    File.readlines(fixture_path).map do |line|
      JSON.parse(line)
    end
  end
  # Helper to find a specific committee by its ID from the loaded fixture data
  def find_fixture_data_by_id(committee_id)
    found_data = all_fixture_data.find { |data| data["id"] == committee_id }
    raise "Committee with ID #{committee_id} not found in fixture!" unless found_data

    found_data
  end

  # Helper to get data from a specific line number (1-indexed)
  def get_fixture_data_by_line_number(line_number)
    data = all_fixture_data[line_number - 1]
    raise "Fixture line #{line_number} not found or file empty." unless data

    data
  end

  # --- Test Data Scenarios ---

  # Scenario 1: Rich Data (Using committee ID 45020: "ISO/IEC JTC 1")
  # This committee has many children, members, and liaisons.
  context "when initialized with rich data (e.g., ISO/IEC JTC 1, ID: 45020)" do
    let(:fixture_data) { find_fixture_data_by_id(45020) }
    subject(:committee) { described_class.new(fixture_data) }

    it 'correctly maps "id"' do
      expect(committee.id).to eq(45020)
    end

    it 'correctly maps "reference"' do
      expect(committee.reference).to eq("ISO/IEC JTC 1")
    end

    it 'correctly maps "status"' do
      expect(committee.status).to eq("Active") # From fixture data for ID 45020
    end

    describe "nested :title attribute" do
      it {
        expect(committee.title).to be_an_instance_of(Iso::Data::Importer::Models::LocalizedString)
      }
      it { expect(committee.title.en).to eq("Information technology") }
      it {
        expect(committee.title.fr).to be_nil
      } # Assuming 'fr' key absent in fixture for this title
    end

    describe "nested :secretariat attribute" do
      it {
        expect(committee.secretariat).to be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference)
      }
      it { expect(committee.secretariat.id).to eq(2188) } # ANSI
      it { expect(committee.secretariat.acronym).to eq("ANSI") }
    end

    it 'correctly maps and parses "creationDate"' do
      expect(committee.creation_date).to eq(Date.new(1987, 1, 1))
    end

    describe "nested :scope attribute" do
      it {
        expect(committee.scope).to be_an_instance_of(Iso::Data::Importer::Models::LocalizedString)
      }
      it {
        expect(committee.scope.en).to eq("Standardization in the field of information technology.")
      }
    end

    it 'maps "parentId" as nil' do
      expect(committee.parent_id).to be_nil
    end

    it 'maps "childrenId" to :children_ids as a populated array' do
      expect(committee.children_ids).to be_an_instance_of(Array)
      expect(committee.children_ids).not_to be_empty
      expect(committee.children_ids).to include(45050, 45072) # Sample children
    end

    describe ":p_members collection" do
      it {
        expect(committee.p_members).to all(be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference))
      }
      it { expect(committee.p_members.size).to be > 5 } # Expect several members
      it "contains expected member data" do
        expect(committee.p_members.map(&:acronym)).to include("ANSI", "DIN",
                                                              "SCC")
      end
    end

    describe ":o_members collection" do
      it {
        expect(committee.o_members).to all(be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference))
      }
      it { expect(committee.o_members.size).to be > 5 }
      it "contains expected member data" do
        expect(committee.o_members.map(&:acronym)).to include("SASO", "IRAM")
      end
    end

    describe ":committee_liaisons collection" do
      it {
        expect(committee.committee_liaisons).to all(be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference))
      }
      it { expect(committee.committee_liaisons.size).to be > 5 }
      it "correctly maps data, including null references" do
        liaison_with_null_ref = # ID from fixture with null reference
          committee.committee_liaisons.find do |l|
            l.id == 55172
          end
        expect(liaison_with_null_ref&.reference).to be_nil if liaison_with_null_ref

        liaison_with_ref = # ID with a reference
          committee.committee_liaisons.find do |l|
            l.id == 54110
          end
        expect(liaison_with_ref&.reference).to eq("ISO/TC 184") if liaison_with_ref
      end
    end

    describe ":organization_liaisons collection" do
      it {
        expect(committee.organization_liaisons).to all(be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference))
      }
      it { expect(committee.organization_liaisons.size).to be >= 4 }
      it "contains expected liaison data" do
        expect(committee.organization_liaisons.map(&:acronym)).to include(
          "EC - European Commission", "ITU"
        )
      end
    end

    it 'correctly maps "sortKey"' do
      expect(committee.sort_key).to eq("ISO/IEC JTC 001")
    end
  end

  # Scenario 2: Data with many nulls (Using committee ID 10320021: "IEC/ISO JSyC BDC")
  # This one has HTML in scope and several null collections.
  context "when initialized with data containing many nulls (e.g., IEC/ISO JSyC BDC, ID: 10320021)" do
    let(:fixture_data) { find_fixture_data_by_id(10320021) }
    subject(:committee) { described_class.new(fixture_data) }

    it { expect(committee.id).to eq(10320021) }
    it { expect(committee.parent_id).to be_nil }
    it { expect(committee.children_ids).to eq([]) } # From JSON null
    it { expect(committee.o_members).to eq([]) }    # From JSON null
    it { expect(committee.organization_liaisons).to eq([]) } # From JSON null

    describe "nested :scope attribute" do
      it {
        expect(committee.scope).to be_an_instance_of(Iso::Data::Importer::Models::LocalizedString)
      }
      it "has :en text including HTML markup" do
        expect(committee.scope.en).to include("<strong>", "</a>", "<ol>")
      end
    end

    describe ":p_members collection (with one member)" do
      it { expect(committee.p_members.size).to eq(1) }
      it {
        expect(committee.p_members.first).to be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference)
      }
      it "has correct member data" do
        expect(committee.p_members.first.id).to eq(1619)
        expect(committee.p_members.first.acronym).to eq("SCC")
      end
    end

    describe ":committee_liaisons collection (with one liaison)" do
      it { expect(committee.committee_liaisons.size).to eq(1) }
      it {
        expect(committee.committee_liaisons.first).to be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference)
      }
      it "has correct liaison data" do
        expect(committee.committee_liaisons.first.id).to eq(54960)
        expect(committee.committee_liaisons.first.reference).to eq("ISO/TC 215")
      end
    end
  end

  # Scenario 3: Secretariat with null id and acronym (Using committee ID 45270: "ISO/IEC JTC 1/SC 25")
  context "when secretariat has null id and acronym (e.g., ISO/IEC JTC 1/SC 25, ID: 45270)" do
    let(:fixture_data) { find_fixture_data_by_id(45270) }
    subject(:committee) { described_class.new(fixture_data) }

    it "creates a secretariat object" do
      expect(committee.secretariat).to be_an_instance_of(Iso::Data::Importer::Models::OrganizationReference)
    end
    it "secretariat id is nil" do
      expect(committee.secretariat.id).to be_nil
    end
    it "secretariat acronym is nil" do
      expect(committee.secretariat.acronym).to be_nil
    end
  end

  # Scenario 4: Testing with absent optional keys (using a manually defined hash)
  context "when initialized with JSON data where optional keys are absent" do
    let(:absent_keys_hash) do
      JSON.parse('{"id":999,"reference":"ISO/TC TEST","status":"Active"}')
    end
    subject(:committee) { described_class.new(absent_keys_hash) }

    it "assigns provided attributes correctly" do
      expect(committee.id).to eq(999)
      expect(committee.reference).to eq("ISO/TC TEST")
      expect(committee.status).to eq("Active")
    end

    it "assigns nil to simple attributes for absent keys" do
      expect(committee.creation_date).to be_nil
      expect(committee.parent_id).to be_nil
      expect(committee.sort_key).to be_nil
    end

    it "assigns nil to nested object attributes for absent keys" do
      expect(committee.title).to be_nil
      expect(committee.secretariat).to be_nil
      expect(committee.scope).to be_nil
    end

    it "assigns empty arrays to collection attributes for absent keys" do
      expect(committee.children_ids).to eq([])
      expect(committee.p_members).to eq([])
      expect(committee.o_members).to eq([])
      expect(committee.committee_liaisons).to eq([])
      expect(committee.organization_liaisons).to eq([])
    end
  end
end
