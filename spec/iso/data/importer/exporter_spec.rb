# spec/iso/data/importer/exporter_spec.rb
require 'spec_helper'

require 'iso/data/importer/exporter'
require 'iso/data/importer/models/deliverable_collection'
require 'iso/data/importer/models/technical_committee_collection'
require 'iso/data/importer/models/ics_entry_collection'

require 'fileutils'
require 'yaml'
require 'json'
require 'tmpdir'

RSpec.describe Iso::Data::Importer::Exporter do
  let(:temp_output_root) { Dir.mktmpdir("iso_exporter_spec_") }
  let(:data_output_dir_for_test) { temp_output_root }

  # --- Mock Item Hashes (representing item_model.to_h output) ---
  let(:deliverable1_item_hash_val) { { "id" => 1, "docidentifier" => "ISO 9001:2015" } }
  let(:deliverable2_item_hash_val) { { "id" => 2, "docidentifier" => "ISO/TR 10013" } }
  let(:tc1_item_hash_val) { { "id" => 101, "reference" => "ISO/TC 1" } }
  let(:ics1_item_hash_val) { { "identifier" => "01.020" } }

  let!(:exporter_instance) do
    stub_const("Iso::Data::Importer::Exporter::DATA_OUTPUT_DIR", data_output_dir_for_test)
    described_class.new
  end

  after(:each) do
    FileUtils.rm_rf(temp_output_root) if Dir.exist?(temp_output_root)
  end

  # --- Shared Examples for Collection Export Methods ---
  # Arguments:
  # - export_method_name: Symbol (e.g., :export_deliverables)
  # - collection_class: The actual Collection class
  # - item_mocks_input_array_let_name: Symbol, name of the `let` variable for an array of item creation details (e.g. :deliverable_item_creation_details)
  # - item_hashes_let_name: Symbol, name of the `let` variable for corresponding item hashes
  # - collection_filename_base_const_name: Symbol, e.g., :ALL_DELIVERABLES_FILENAME_BASE from Exporter
  # - collection_items_key_string: String, e.g., "deliverables" - the top key in the collection's hash
  shared_examples "a single file collection export method" do |export_method_name, collection_class, item_creation_details_let_name, item_hashes_let_name, collection_filename_base_const_name, collection_items_key_string|
    let(:item_creation_details) { send(item_creation_details_let_name) } # e.g., [{}, {}]
    let(:item_hashes) { send(item_hashes_let_name) } # e.g., [deliverable1_item_hash_val, ...]

    # Create mock item objects within the example's scope
    let(:mock_items) do
      item_creation_details.map.with_index do |_placeholder, i| # Use placeholder if item_creation_details is just for count
        double("ItemModel#{i}", to_h: item_hashes[i]) # Items only need to_h for collection's to_h
      end
    end
    let(:collection_object) { collection_class.new(mock_items) }

    let(:collection_filename_base) { Iso::Data::Importer::Exporter.const_get(collection_filename_base_const_name) }
    let(:collection_output_dir) { data_output_dir_for_test }

    let(:expected_collection_hash_for_serialization) { { collection_items_key_string => item_hashes } }
    let(:expected_yaml_string) { expected_collection_hash_for_serialization.to_yaml }
    let(:expected_json_string) { expected_collection_hash_for_serialization.to_json }

    before do
      allow(collection_object).to receive(:to_h).and_return(expected_collection_hash_for_serialization)
      allow(collection_object).to receive(:to_yaml).and_return(expected_yaml_string)
      allow(collection_object).to receive(:to_json).and_return(expected_json_string)
    end

    it "writes the entire collection to a single YAML file (default format)" do
      expected_filepath = File.join(collection_output_dir, "#{collection_filename_base}.yaml")
      expect(File).to receive(:write).with(expected_filepath, expected_yaml_string)
      exporter_instance.public_send(export_method_name, collection_object)
    end

    it "writes the entire collection to a single JSON file when format is :json" do
      expected_filepath = File.join(collection_output_dir, "#{collection_filename_base}.json")
      expect(File).to receive(:write).with(expected_filepath, expected_json_string)
      exporter_instance.public_send(export_method_name, collection_object, format: :json)
    end

    it "does nothing if the collection is nil or empty" do
      expect(File).not_to receive(:write)
      exporter_instance.public_send(export_method_name, nil)
      empty_collection = collection_class.new([])
      allow(empty_collection).to receive(:size).and_return(0)
      allow(empty_collection).to receive(:empty?).and_return(true)
      exporter_instance.public_send(export_method_name, empty_collection)
    end
  end

  describe '#export_deliverables' do
    # Define let variables for the item hashes and a placeholder for mock creation
    let(:deliverable_item_creation_details_for_export) { [{}, {}] } # Two items
    let(:deliverable_hashes_for_export) { [deliverable1_item_hash_val, deliverable2_item_hash_val] }

    it_behaves_like "a single file collection export method",
                    :export_deliverables,
                    Iso::Data::Importer::Models::DeliverableCollection,
                    :deliverable_item_creation_details_for_export, # Pass symbol name
                    :deliverable_hashes_for_export,                # Pass symbol name
                    :ALL_DELIVERABLES_FILENAME_BASE,
                    "deliverables"
  end

  describe '#export_technical_committees' do
    let(:tc_item_creation_details_for_export) { [{}] } # One item
    let(:tc_hashes_for_export) { [tc1_item_hash_val] }

    it_behaves_like "a single file collection export method",
                    :export_technical_committees,
                    Iso::Data::Importer::Models::TechnicalCommitteeCollection,
                    :tc_item_creation_details_for_export,
                    :tc_hashes_for_export,
                    :ALL_TCS_FILENAME_BASE,
                    "technical_committees"
  end

  describe '#export_ics_entries' do
    let(:ics_item_creation_details_for_export) { [{}] } # One item
    let(:ics_hashes_for_export) { [ics1_item_hash_val] }

    it_behaves_like "a single file collection export method",
                    :export_ics_entries,
                    Iso::Data::Importer::Models::IcsEntryCollection,
                    :ics_item_creation_details_for_export,
                    :ics_hashes_for_export,
                    :ALL_ICS_FILENAME_BASE,
                    "ics_entries"
  end

  describe '#initialize' do
    it 'creates the base output directory only' do
      expect(Dir.exist?(data_output_dir_for_test)).to be true
      expect(Dir.exist?(File.join(data_output_dir_for_test, "deliverables"))).to be false
      expect(Dir.exist?(File.join(data_output_dir_for_test, "committees"))).to be false
      expect(Dir.exist?(File.join(data_output_dir_for_test, "ics"))).to be false
    end
  end

  describe '#clean_output_files' do
    let(:deliverables_coll_yaml_path) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ALL_DELIVERABLES_FILENAME_BASE + ".yaml") }
    let(:deliverables_coll_json_path) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ALL_DELIVERABLES_FILENAME_BASE + ".json") }
    let(:dummy_individual_dir_path) { File.join(data_output_dir_for_test, "deliverables_old_subdir") }
    let(:dummy_individual_file_path) { File.join(dummy_individual_dir_path, "dummy_individual.yaml")}

    before do
      FileUtils.touch(deliverables_coll_yaml_path)
      FileUtils.touch(deliverables_coll_json_path)
      FileUtils.mkdir_p(dummy_individual_dir_path)
      FileUtils.touch(dummy_individual_file_path)
    end

    it 'removes only collection-level .yaml and .json files from the DATA_OUTPUT_DIR' do
      exporter_instance.clean_output_files
      expect(File.exist?(deliverables_coll_yaml_path)).to be false
      expect(File.exist?(deliverables_coll_json_path)).to be false
      expect(File.exist?(dummy_individual_file_path)).to be true
      expect(Dir.exist?(dummy_individual_dir_path)).to be true
    end
  end
end