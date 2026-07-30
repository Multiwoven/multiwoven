# frozen_string_literal: true

FactoryBot.define do
  factory :agentic_coding_prompt, class: "AgenticCoding::Prompt" do
    association :agentic_coding_session
    agentic_coding_app { agentic_coding_session.agentic_coding_app }
    role { :user }
    content { "MyText" }
    status { :queued }
    response_text { "MyText" }
    agent_mode { "MyString" }
    context { {} }
  end
end
