# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisualComponent, type: :model do
  it { should validate_presence_of(:workspace_id) }
  it { should validate_presence_of(:component_type) }
  it { should validate_presence_of(:model_id) }
  it { should validate_presence_of(:data_app_id) }

  it {
    should define_enum_for(:component_type)
      .with_values(doughnut: 0, bar: 1, data_table: 2, visual_text: 3, custom: 4, chat_bot: 5)
  }

  it { should belong_to(:workspace) }
  it { should belong_to(:data_app) }
  it { should belong_to(:model) }
  it { should have_many(:feedbacks).dependent(:destroy) }
end
