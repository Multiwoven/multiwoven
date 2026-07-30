# frozen_string_literal: true

module ReverseEtl
  module Processors
    module Text
      class ChunkProcessor
        DEFAULT_CHUNK_SIZE = 1000
        DEFAULT_CHUNK_OVERLAP = 200

        def chunk_processor(chunk_config)
          if legacy?(chunk_config)
            processor_type = ENV["CHUNK_PROCESSOR"] || "langchain_rb"
            processor_class_name = "ReverseEtl::Processors::Text::#{processor_type.camelize}"
            processor_class_name.constantize.new
          else
            ReverseEtl::Processors::Text::TokenChunker.new
          end
        end

        # Process content into chunks with metadata
        def process(chunk_config, content, metadata = {})
          chunk_config[:chunk_size] ||= DEFAULT_CHUNK_SIZE
          chunk_config[:chunk_overlap] ||= DEFAULT_CHUNK_OVERLAP
          content = cleanup(content)

          chunks = chunk_processor(chunk_config).process(chunk_config, content)
          format_chunks(chunks, metadata)
        end

        private

        def format_chunks(chunks, metadata)
          chunks.map do |chunk|
            {
              element_id: Digest::MD5.hexdigest(chunk),
              text: chunk,
              created_date: metadata[:file_created_date],
              modified_date: metadata[:file_modified_date],
              filename: metadata[:file_name],
              filetype: metadata[:file_type],
              created_at: Time.current
            }
          end
        end

        def cleanup(text)
          text
            .gsub(/<[^>]+>/, " ") # Remove HTML tags
            .gsub(/\s+/, " ")
            .gsub(/\\\[\\\n/, " ") # Collapse whitespace and newlines
            .strip # Trim leading/trailing spaces
        end

        def legacy?(chunk_config)
          chunk_config[:model].blank? && chunk_config[:provider].blank?
        end
      end
    end
  end
end
