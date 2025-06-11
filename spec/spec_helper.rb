# spec/spec_helper.rb

# Set up gems listed in the Gemfile.
require 'bundler/setup'

# Add the lib directory to Ruby's load path.
# This allows `require 'iso/data/importer/...'` from within specs.
# Assumes spec_helper.rb is in `your_project_root/spec/`
# and your library code is in `your_project_root/lib/`.
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# --- Optional: Require your main gem entry point if it does general setup ---
# If you have a file like `lib/iso-data-importer.rb` that requires all other
# necessary components of your gem, you can require it here.
# Example:
# require 'iso-data-importer'
# For now, we'll let individual spec files require what they need after the
# load path is set.

# --- Require common testing gems ---
# These are often needed across many spec files.
# require 'pry' # For debugging
# require 'vcr' # If using VCR for HTTP interaction recording
# require 'webmock/rspec' # If using WebMock for stubbing HTTP requests

# --- RSpec Configuration ---
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  # (good practice to avoid potential name clashes)
  config.disable_monkey_patching!

  # Configure RSpec to use the :expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Optional: Allows you to focus on specific examples by tagging them with `:focus`
  config.filter_run_when_matching :focus
  config.run_all_when_everything_filtered = true # Run all if no :focus is found

  # Optional: Run specs in random order to surface order dependencies.
  # If you find an order dependency and want to debug it, you can disable
  # this and use the --seed flag from a previous run.
  config.order = :random

  # Seed global randomization in RSpec with --seed
  # This ensures that if you run specs with a specific seed,
  # the random order will be the same, aiding in debugging.
  Kernel.srand config.seed

  # --- VCR Configuration (Example, if you decide to use it) ---
  # if defined?(VCR)
  #   VCR.configure do |c|
  #     c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  #     c.hook_into :webmock # or :httparty, :faraday, etc.
  #     c.configure_rspec_metadata!
  #     # Optional: filter sensitive data
  #     # c.filter_sensitive_data('<API_KEY>') { ENV['YOUR_API_KEY'] }
  #   end
  # end

  # --- WebMock Configuration (Example, if you decide to use it) ---
  # if defined?(WebMock)
  #   # Allow connections to localhost for Selenium/Capybara drivers, etc.
  #   WebMock.disable_net_connect!(allow_localhost: true)
  # end
end