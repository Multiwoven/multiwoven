# frozen_string_literal: true

module Liquid
  module CustomFilters
    CAST_METHODS = {
      "string" => :to_s,
      "number" => :to_f,
      "boolean" => ->(input) { ActiveRecord::Type::Boolean.new.cast(input) }
    }.freeze

    def cast(input, type)
      method = CAST_METHODS[type]
      method ? apply_cast_method(input, method) : input
    end

    def regex_replace(input, pattern, replacement = "", flags = "")
      re = build_regexp(pattern, flags)
      input.gsub(re, replacement)
    end

    def match_regex(input, pattern, flags = "")
      re = build_regexp(pattern, flags)
      if re.match?(input)
        input
      else
        Raise StandardError, "Input does not match regex pattern"
      end
    end

    def to_datetime(input, existing_date_format)
      return input if input.blank?

      DateTime.strptime(input, existing_date_format)&.iso8601
    end

    private

    def apply_cast_method(input, method)
      method.is_a?(Proc) ? method.call(input) : input.send(method)
    end

    def build_regexp(pattern, flags)
      options = flags.chars.reduce(0) do |opts, flag|
        opts | flag_option(flag)
      end
      Regexp.new(pattern, options)
    end

    # Maps single character flags to their corresponding Regexp option constants.
    # Note: Ruby does not support 'n', 'e', 's', 'u' flags directly, and 'o' flag behavior is implicit.
    #       We handle common flags here and use FIXEDENCODING for unsupported flags as a placeholder.
    def flag_option(flag)
      case flag
      when "i" then Regexp::IGNORECASE
      when "m" then Regexp::MULTILINE
      when "x" then Regexp::EXTENDED
      when "n", "e", "s", "u" then Regexp::FIXEDENCODING
      else 0 # No action for unrecognized flags
      end
    end
  end
end
