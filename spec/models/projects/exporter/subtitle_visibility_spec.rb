# frozen_string_literal: true

#-- copyright
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
#++

require "spec_helper"

# Feature 004 (T7): the exported subtitle set MUST respect the same permission
# and visibility rules as the projects list itself (FR-6 / Scenario 4). A user
# must NOT obtain subtitles for projects they cannot otherwise see.
RSpec.describe Projects::Exports::CSV, "subtitle visibility (FR-6)" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:visible_member_project) do
    create(:project, name: "Member project", identifier: "member-project",
                     subtitle: "Member-only tagline")
  end
  shared_let(:visible_public_project) do
    create(:project, name: "Public project", identifier: "public-project",
                     public: true, subtitle: "Public tagline")
  end
  shared_let(:hidden_private_project) do
    create(:project, name: "Hidden project", identifier: "hidden-project",
                     public: false, subtitle: "Secret tagline")
  end

  let(:query_columns) { %w[name subtitle] }
  let(:query) { build_stubbed(:project_query, select: query_columns) }
  let(:instance) { described_class.new(query) }
  let(:utf8_bom) { "\xEF\xBB\xBF" }
  let(:parsed) { CSV.parse(instance.export!.content.delete_prefix(utf8_bom)) }
  let(:rows) { parsed.drop(1) }
  let(:exported_names) { rows.map(&:first) }
  let(:exported_subtitles) { rows.map(&:last) }

  before { login_as current_user }

  context "for a non-member, non-admin user" do
    # The non_member role grants view_project, so public projects are visible,
    # the membership grants visibility of the member project, and the private
    # project remains hidden.
    let(:role) { create(:project_role, permissions: %i[view_project export_projects]) }
    let(:current_user) do
      create(:user, member_with_permissions: { visible_member_project => %i[view_project export_projects] })
    end

    before do
      create(:non_member, permissions: %i[view_project export_projects])
    end

    it "exports exactly the user's visible projects" do
      expect(exported_names).to contain_exactly(
        visible_member_project.name,
        visible_public_project.name
      )
      expect(exported_names).not_to include(hidden_private_project.name)
    end

    it "exports subtitles only for the visible projects, never for hidden ones" do
      expect(exported_subtitles).to contain_exactly("Member-only tagline", "Public tagline")
      expect(exported_subtitles).not_to include("Secret tagline")
    end
  end

  context "for an admin" do
    let(:current_user) { create(:admin) }

    it "exports subtitles for all projects, including the private one" do
      expect(exported_subtitles).to include(
        "Member-only tagline", "Public tagline", "Secret tagline"
      )
    end
  end

  context "for an anonymous user with no visible projects" do
    let(:current_user) { User.anonymous }

    it "produces an export with the Subtitle header and zero subtitle rows" do
      expect(parsed.first).to eq(%w[Name Subtitle])
      expect(rows).to be_empty
    end
  end
end
