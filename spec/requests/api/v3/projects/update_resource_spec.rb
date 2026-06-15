# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require "spec_helper"
require "rack/test"
require_relative "../workspaces/update_resource_examples"

RSpec.describe "API v3 Project resource update", content_type: :json do
  describe "PATCH /api/v3/projects/:id" do
    context "for a project" do
      include_examples "APIv3 workspace update" do
        let(:path) { api_v3_paths.project(workspace.id) }
        let(:workspace_factory_key) { :project }
        let(:workspace_api_type) { "Project" }
      end
    end

    context "for a portfolio" do
      include_examples "APIv3 workspace update" do
        let(:path) { api_v3_paths.project(workspace.id) }
        let(:workspace_factory_key) { :portfolio }
        let(:workspace_api_type) { "Portfolio" }
      end
    end

    describe "subtitle" do
      include Rack::Test::Methods
      include API::V3::Utilities::PathHelper

      shared_let(:project) { create(:project, subtitle: "Old subtitle") }

      let(:permissions) { %i[edit_project] }
      let(:path) { api_v3_paths.project(project.id) }

      current_user do
        create(:user, member_with_permissions: { project => permissions })
      end

      before do
        patch path, body.to_json
      end

      context "when an authorized user sets the subtitle" do
        let(:body) { { subtitle: "New subtitle" } }

        it "responds with 200 OK" do
          expect(last_response).to have_http_status(:ok)
        end

        it "persists the new subtitle" do
          expect(project.reload.subtitle).to eq("New subtitle")
        end

        it "returns the subtitle as a plain string" do
          expect(last_response.body)
            .to be_json_eql("New subtitle".to_json)
                  .at_path("subtitle")
        end
      end

      context "when an authorized user clears the subtitle" do
        let(:body) { { subtitle: "" } }

        it "responds with 200 OK" do
          expect(last_response).to have_http_status(:ok)
        end

        it "clears the stored subtitle (nil)" do
          expect(project.reload.subtitle).to be_nil
        end
      end

      context "when the subtitle exceeds 255 characters" do
        let(:body) { { subtitle: "a" * 256 } }

        it "responds with 422 unprocessable entity" do
          expect(last_response).to have_http_status(:unprocessable_entity)
        end

        it "denotes the (translated) length error" do
          expect(last_response.body)
            .to be_json_eql("Error".to_json)
                  .at_path("_type")
          expect(last_response.body)
            .to be_json_eql("Subtitle is too long (maximum is 255 characters).".to_json)
                  .at_path("message")
        end

        it "does not change the stored subtitle" do
          expect(project.reload.subtitle).to eq("Old subtitle")
        end
      end

      context "when exactly 255 characters" do
        let(:body) { { subtitle: "a" * 255 } }

        it "responds with 200 OK" do
          expect(last_response).to have_http_status(:ok)
        end

        it "persists the value" do
          expect(project.reload.subtitle).to eq("a" * 255)
        end
      end

      context "when the user lacks edit_project permission" do
        let(:permissions) { %i[view_project_attributes] }
        let(:body) { { subtitle: "Sneaky subtitle" } }

        it "responds with 403 forbidden" do
          expect(last_response).to have_http_status(:forbidden)
        end

        it "does not change the stored subtitle" do
          expect(project.reload.subtitle).to eq("Old subtitle")
        end
      end
    end
  end
end
