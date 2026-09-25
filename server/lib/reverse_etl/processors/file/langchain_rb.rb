# frozen_string_literal: true

module ReverseEtl
  module Processors
    module File
      class LangchainRb < BaseParser
        SUPPORTED_TYPES = {
          pdf: "parse_pdf",
          docx: "parse_docx",
          pptx: "parse_pptx",
          txt: "",
          md: ""
        }.freeze

        DRAWINGML_NAMESPACE = "http://schemas.openxmlformats.org/drawingml/2006/main"
        PRESENTATIONML_NAMESPACE = "http://schemas.openxmlformats.org/presentationml/2006/main"
        OFFICE_REL_NAMESPACE = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
        PACKAGE_REL_NAMESPACE = "http://schemas.openxmlformats.org/package/2006/relationships"
        SLIDE_REL_TYPE = "#{OFFICE_REL_NAMESPACE}/slide".freeze

        def parse_file_content(file_path, file_type)
          file_type = file_type.to_s.downcase.to_sym
          unless SUPPORTED_TYPES.key?(file_type)
            raise ArgumentError,
                  "Failed to parse file: Unsupported file type: #{file_type}"
          end

          if %i[md txt].include?(file_type)
            ::File.read(file_path).force_encoding("UTF-8")
          else
            send(SUPPORTED_TYPES[file_type], file_path)
          end
        end

        private

        def parse_pdf(file_path)
          pdf_processor = Langchain::Processors::PDF.new
          ::File.open(file_path, "rb") { |file| pdf_processor.parse(file) }
        end

        def parse_docx(file_path)
          docx_processor = Langchain::Processors::Docx.new
          ::File.open(file_path, "rb") { |file| docx_processor.parse(file) }
        end

        # PPTX is OOXML (zipped XML); extract DrawingML text without power_point_pptx.
        # Presentation order comes from p:sldIdLst + ppt/_rels/presentation.xml.rels
        # (see https://learn.microsoft.com/en-us/office/open-xml/presentation/structure-of-a-presentationml-document).
        def parse_pptx(file_path)
          slide_texts = []
          Zip::File.open(file_path) do |zip|
            pptx_slide_paths(zip).each do |slide_path|
              entry = zip.find_entry(slide_path)
              next unless entry

              xml = entry.get_input_stream(&:read)
              doc = Nokogiri::XML(xml, &:nonet)
              slide_text = pptx_slide_text(doc)
              slide_texts << slide_text unless slide_text.empty?
            end
          end
          slide_texts.join("\n\n")
        end

        # Concatenate a:t runs verbatim within each a:p; delimiter only between nonempty paragraphs.
        # Formatting can split words across runs (e.g. "co"+"operate"); do not strip or join with spaces.
        def pptx_slide_text(doc)
          paragraphs = doc.xpath("//a:p", "a" => DRAWINGML_NAMESPACE).filter_map do |paragraph|
            text = paragraph.xpath(".//a:t", "a" => DRAWINGML_NAMESPACE).map(&:text).join
            text unless text.empty?
          end
          paragraphs.join("\n")
        end

        def pptx_slide_paths(zip)
          ordered = pptx_slide_paths_from_presentation(zip)
          return ordered if ordered.any?

          zip.entries
             .map(&:name)
             .select { |name| name.match?(%r{\Appt/slides/slide\d+\.xml\z}) }
             .sort_by { |name| name[/\d+/].to_i }
        end

        def pptx_slide_paths_from_presentation(zip)
          presentation_entry = zip.find_entry("ppt/presentation.xml")
          rels_entry = zip.find_entry("ppt/_rels/presentation.xml.rels")
          return [] unless presentation_entry && rels_entry

          presentation = Nokogiri::XML(presentation_entry.get_input_stream(&:read), &:nonet)
          rels = Nokogiri::XML(rels_entry.get_input_stream(&:read), &:nonet)
          targets_by_id = pptx_slide_targets_by_rel_id(rels)

          presentation.xpath("//p:sldIdLst/p:sldId", "p" => PRESENTATIONML_NAMESPACE).filter_map do |sld_id|
            rel_id = sld_id.attribute_with_ns("id", OFFICE_REL_NAMESPACE)&.value
            pptx_resolve_slide_path(targets_by_id[rel_id])
          end
        end

        def pptx_slide_targets_by_rel_id(rels)
          targets_by_id = {}
          rels.xpath("//pr:Relationship", "pr" => PACKAGE_REL_NAMESPACE).each do |rel|
            next unless rel["Type"] == SLIDE_REL_TYPE

            targets_by_id[rel["Id"]] = rel["Target"]
          end
          targets_by_id
        end

        def pptx_resolve_slide_path(target)
          return unless target

          # Relationship targets are relative to ppt/
          "ppt/#{target.delete_prefix('/').delete_prefix('ppt/')}"
        end

        def optional_decode(content)
          return content if content.is_a?(String) && content.encoding == Encoding::UTF_8

          content.to_s.force_encoding("UTF-8")
        end
      end
    end
  end
end
