# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Processors::File::LangchainRb do
  let(:parser) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:pdf_file) { Tempfile.new(["test", ".pdf"], temp_dir) }
  let(:docx_file) { Tempfile.new(["test", ".docx"], temp_dir) }
  let(:txt_file) { Tempfile.new(["test", ".txt"], temp_dir) }
  let(:md_file) { Tempfile.new(["test", ".md"], temp_dir) }

  before do
    # Mock Langchain processors
    @mock_pdf_processor = instance_double("Langchain::Processors::PDF")
    @mock_docx_processor = instance_double("Langchain::Processors::Docx")

    allow(Langchain::Processors::PDF).to receive(:new).and_return(@mock_pdf_processor)
    allow(Langchain::Processors::Docx).to receive(:new).and_return(@mock_docx_processor)
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe "SUPPORTED_TYPES" do
    it "defines supported file types and their parser methods" do
      expect(described_class::SUPPORTED_TYPES).to eq(
        pdf: "parse_pdf",
        docx: "parse_docx",
        pptx: "parse_pptx",
        txt: "",
        md: ""
      )
    end
  end

  describe "#parse_file_content" do
    context "with text files" do
      before do
        txt_file.write("Test content")
        txt_file.rewind
        md_file.write("# Test Markdown")
        md_file.rewind
      end

      it "parses txt files" do
        result = parser.parse_file_content(txt_file.path, "txt")
        expect(result).to eq("Test content")
      end

      it "parses md files" do
        result = parser.parse_file_content(md_file.path, "md")
        expect(result).to eq("# Test Markdown")
      end

      it "handles UTF-8 encoding" do
        content = "Test content with UTF-8: é, ñ, ü"
        txt_file.write(content)
        txt_file.rewind
        result = parser.parse_file_content(txt_file.path, "txt")
        expect(result).to eq(content)
      end

      it "handles file type case insensitivity" do
        result = parser.parse_file_content(txt_file.path, "TXT")
        expect(result).to eq("Test content")
      end
    end

    context "with PDF files" do
      before do
        allow(@mock_pdf_processor).to receive(:parse).and_return("PDF content")
      end

      it "parses PDF files" do
        result = parser.parse_file_content(pdf_file.path, "pdf")
        expect(result).to eq("PDF content")
      end

      it "opens file in binary mode" do
        expect(::File).to receive(:open).with(pdf_file.path, "rb").and_call_original
        parser.parse_file_content(pdf_file.path, "pdf")
      end
    end

    context "with DOCX files" do
      before do
        allow(@mock_docx_processor).to receive(:parse).and_return("DOCX content")
      end

      it "parses DOCX files" do
        result = parser.parse_file_content(docx_file.path, "docx")
        expect(result).to eq("DOCX content")
      end

      it "opens file in binary mode" do
        expect(::File).to receive(:open).with(docx_file.path, "rb").and_call_original
        parser.parse_file_content(docx_file.path, "docx")
      end
    end

    context "with PPTX files" do
      let(:pptx_path) { File.join(temp_dir, "test.pptx") }

      def write_pptx(path, slides_by_name:, presentation_order:)
        Zip::File.open(path, create: true) do |zip|
          slides_by_name.each do |name, xml|
            zip.get_output_stream("ppt/slides/#{name}") { |f| f.write(xml) }
          end

          sld_ids = presentation_order.each_with_index.map do |_name, index|
            %(<p:sldId id="#{256 + index}" r:id="rId#{index + 1}"/>)
          end.join("\n")

          zip.get_output_stream("ppt/presentation.xml") do |f|
            f.write(<<~XML)
              <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
              <p:presentation xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                              xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
                <p:sldIdLst>
                  #{sld_ids}
                </p:sldIdLst>
              </p:presentation>
            XML
          end

          relationships = presentation_order.each_with_index.map do |name, index|
            <<~XML.strip
              <Relationship Id="rId#{index + 1}"
                Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide"
                Target="slides/#{name}"/>
            XML
          end.join("\n")

          zip.get_output_stream("ppt/_rels/presentation.xml.rels") do |f|
            f.write(<<~XML)
              <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
              <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                #{relationships}
              </Relationships>
            XML
          end
        end
      end

      def slide_xml(paragraphs)
        paragraph_xml = paragraphs.map do |runs|
          run_xml = runs.map do |text|
            attrs = text.start_with?(" ") || text.end_with?(" ") ? ' xml:space="preserve"' : ""
            %(<a:r><a:t#{attrs}>#{text}</a:t></a:r>)
          end.join
          "<a:p>#{run_xml}</a:p>"
        end.join

        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                 xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
            #{paragraph_xml}
          </p:sld>
        XML
      end

      it "parses PPTX text in presentation.xml slide order, not archive filename order" do
        # Filenames imply slide1 then slide2, but presentation.xml lists slide2 first.
        write_pptx(
          pptx_path,
          slides_by_name: {
            "slide1.xml" => slide_xml([["Filename slide1"]]),
            "slide2.xml" => slide_xml([["Filename slide2"]])
          },
          presentation_order: %w[slide2.xml slide1.xml]
        )

        result = parser.parse_file_content(pptx_path, "pptx")
        expect(result).to eq("Filename slide2\n\nFilename slide1")
      end

      it "concatenates adjacent DrawingML text runs verbatim within a paragraph" do
        write_pptx(
          pptx_path,
          slides_by_name: {
            "slide1.xml" => slide_xml([%w[co operate], ["done"]])
          },
          presentation_order: %w[slide1.xml]
        )

        result = parser.parse_file_content(pptx_path, "pptx")
        expect(result).to eq("cooperate\ndone")
      end

      it "preserves significant whitespace within DrawingML text runs" do
        write_pptx(
          pptx_path,
          slides_by_name: {
            "slide1.xml" => slide_xml([["Hello", " ", "world"]])
          },
          presentation_order: %w[slide1.xml]
        )

        result = parser.parse_file_content(pptx_path, "pptx")
        expect(result).to eq("Hello world")
      end
    end

    context "when parsing fails" do
      before do
        allow(@mock_pdf_processor).to receive(:parse).and_raise(StandardError, "Parse failed")
      end

      it "raises ParserError with original error message" do
        expect do
          parser.parse_file_content(pdf_file.path, "pdf")
        end.to raise_error(StandardError, "Parse failed")
      end
    end

    context "with unsupported file type" do
      it "raises ParserError with file type in message" do
        expect do
          parser.parse_file_content("test.xyz", "xyz")
        end.to raise_error(ArgumentError, "Failed to parse file: Unsupported file type: xyz")
      end

      it "handles nil file type" do
        expect do
          parser.parse_file_content("test.xyz", nil)
        end.to raise_error(ArgumentError, "Failed to parse file: Unsupported file type: ")
      end
    end
  end

  describe "#optional_decode" do
    it "returns string content as is when already UTF-8" do
      content = "Test content"
      expect(parser.send(:optional_decode, content)).to eq(content)
    end

    it "forces UTF-8 encoding for non-string content" do
      content = "Test content".encode("ASCII-8BIT")
      result = parser.send(:optional_decode, content)
      expect(result.encoding).to eq(Encoding::UTF_8)
    end

    it "converts non-string content to string" do
      content = 123
      result = parser.send(:optional_decode, content)
      expect(result).to eq("123")
      expect(result.encoding).to eq(Encoding::UTF_8)
    end
  end
end
