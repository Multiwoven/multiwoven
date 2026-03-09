# frozen_string_literal: true

FactoryBot.define do
  factory :agentic_coding_deployment, class: "AgenticCoding::Deployment" do
    association :agentic_coding_session
    agentic_coding_app { agentic_coding_session.agentic_coding_app }
    workspace { agentic_coding_app.workspace }
    status { :pending }
    deploy_url { "MyString" }
    deploy_target { "MyString" }
    commit_sha { "MyString" }
    version_tag { "MyString" }
    deploy_metadata { {} }
    error_message { "MyText" }
  end
end
