# frozen_string_literal: true

class AddContextToAgenticCodingPrompts < ActiveRecord::Migration[7.1]
  def change
    add_column :agentic_coding_prompts, :context, :jsonb, default: {}, null: false
  end
end
