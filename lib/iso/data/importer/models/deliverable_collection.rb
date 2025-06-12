# lib/iso/data/importer/models/deliverable_collection.rb
# frozen_string_literal: true

require 'lutaml/model'
require_relative 'deliverable'

module Iso
  module Data
    module Importer
      module Models
        class DeliverableCollection < Lutaml::Model::Collection
          instances :deliverables, Deliverable

          jsonl do
            map_instances to: :deliverables
          end
        end
      end
    end
  end
end
