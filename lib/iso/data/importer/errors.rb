# lib/iso/data/importer/errors.rb
module Iso
  module Data
    module Importer
      class Error < StandardError; end
      class DownloadError < Error; end
      class ParsingError < Error; end
      class ExportError < Error; end
      # Add more specific errors as needed
    end
  end
end