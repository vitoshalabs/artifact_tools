# frozen_string_literal: true

module RSpec
  module SimpleCov
    module Setup
      class << self
        # https://github.com/replaygaming/rspec-simplecov/blob/master/lib/rspec/simplecov/setup.rb#L25-L33
        def build_example(context, configuration)
          context.it configuration.test_case_text do
            result = configuration.described_thing.result
            minimum_coverage = configuration.described_thing.minimum_coverage[:line] # this line is changed
            configuration.described_thing.running = true

            expect(result.covered_percent).to be >= minimum_coverage
          end
        end
      end
    end
  end
end
