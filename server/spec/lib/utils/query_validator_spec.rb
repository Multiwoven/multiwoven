# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::QueryValidator do

  describe '.validate_query' do
    context 'with valid SQL query' do
      let(:query_type) { :raw_sql }
      let(:query) { 'SELECT * FROM users;' }

      it 'does not raise an error' do
        expect { described_class.validate_query(query_type, query) }.not_to raise_error
      end
    end

    context 'with invalid SQL query' do
      let(:query_type) { :raw_sql }
      let(:query) { 'INVALID SQL QUERY;' }

      it 'raises a StandardError with error message' do
        expect { described_class.validate_query(query_type, query) }.to raise_error(StandardError, /contains invalid SQL syntax/)
      end
    end

    context 'with unsupported query type' do
      let(:query_type) { :unsupported }
      let(:query) { 'SELECT * FROM users;' }

      it 'raises a StandardError with error message' do
        expect { described_class.validate_query(query_type, query) }.to raise_error(StandardError, /Unsupported query_type/)
      end
    end
  end
end
