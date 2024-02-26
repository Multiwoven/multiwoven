# frozen_string_literal: true

# spec/interactors/syncs/sync_configurations_spec.rb
require "rails_helper"

RSpec.describe Syncs::SyncConfigurations, type: :interactor do
  describe "#call" do
    subject(:call_interactor) { described_class.call }

    it "completes successfully" do
      expect(call_interactor.success?).to be_truthy
    end

    it "assigns configurations to the context" do
      expect(call_interactor.configurations).not_to be_nil
    end

    describe "structure of configurations" do
      let(:configurations) { call_interactor.configurations }

      it "includes the expected top-level :data key" do
        expect(configurations.keys).to contain_exactly(:data)
      end

      describe ":data key" do
        let(:data) { configurations[:data] }

        it "contains :configurations key" do
          expect(data.keys).to contain_exactly(:configurations)
        end

        describe ":configurations key" do
          let(:configurations_data) { data[:configurations] }

          it "includes :catalog_mapping_types key" do
            expect(configurations_data.keys).to contain_exactly(:catalog_mapping_types)
          end

          describe ":catalog_mapping_types" do
            let(:catalog_mapping_types) { configurations_data[:catalog_mapping_types] }

            describe "static configuration" do
              let(:static_config) { catalog_mapping_types[:static] }

              it "defines configurations for string, number, boolean, and null types" do
                expect(static_config.keys).to match_array(%i[string number boolean null])
              end

              it "specifies the type and description for string configuration correctly" do
                description = "combination of numbers, letters, and special characters"
                expect(static_config[:string]).to match(type: "string",
                                                        description: a_string_including(description))
              end

              it "specifies the type and description for number configuration correctly" do
                description = "numerical value as integer or float"
                expect(static_config[:number]).to match(type: "float",
                                                        description: a_string_including(description))
              end

              it "specifies the type and description for boolean configuration correctly" do
                expect(static_config[:boolean]).to match(type: "boolean",
                                                         description: a_string_including("true or false value"))
              end

              it "specifies the type and description for null configuration correctly" do
                expect(static_config[:null]).to match(type: "null", description: a_string_including("null value"))
              end
            end

            describe "template configuration" do
              let(:template_config) { catalog_mapping_types[:template] }

              it "contains :variable and :filter keys" do
                expect(template_config.keys).to match_array(%i[variable filter])
              end

              describe "filter configuration" do
                let(:filter_config) { template_config[:filter] }

                it "includes expected keys for cast and regex_replace filters" do
                  expect(filter_config.keys).to match_array(%i[cast regex_replace])
                end

                it "specifies the description and value for the cast filter correctly" do
                  expect(filter_config[:cast]).to include(
                    description: a_string_including("Cast input to specified type"),
                    value: a_string_including("{{ cast:")
                  )
                end

                it "specifies the description and value for the regex_replace filter correctly" do
                  expect(filter_config[:regex_replace]).to include(
                    description: a_string_including("Search and replace substrings of input using RegEx"),
                    value: a_string_including("{{ regex_replace :")
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
