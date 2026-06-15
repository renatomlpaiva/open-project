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

RSpec.describe "Projects list subtitle display", :js, with_settings: { login_required?: false } do
  shared_let(:admin) { create(:admin) }

  shared_let(:project_with_subtitle) do
    create(:project, name: "Project with subtitle", identifier: "with-subtitle",
                     subtitle: "A short tagline")
  end
  shared_let(:project_without_subtitle) do
    create(:project, name: "Project without subtitle", identifier: "without-subtitle")
  end
  shared_let(:archived_project) do
    create(:project, name: "Archived project", identifier: "archived-subtitle",
                     subtitle: "Archived tagline", active: false)
  end

  let(:projects_page) { Pages::Projects::Index.new }
  let(:subtitle_selector) { ".projects-table--name-subtitle" }

  before do
    login_as admin
    projects_page.visit!
  end

  it "shows the subtitle as secondary text beneath the project name (scenario 1, FR-1, FR-10)" do
    projects_page.within_row(project_with_subtitle) do
      expect(page).to have_css(".projects-table--name", text: project_with_subtitle.name)
      expect(page).to have_css(subtitle_selector, text: "A short tagline")
    end
  end

  it "renders no subtitle element, label, or placeholder when absent (scenario 3, FR-3)" do
    projects_page.within_row(project_without_subtitle) do
      expect(page).to have_css(".projects-table--name", text: project_without_subtitle.name)
      expect(page).to have_no_css(subtitle_selector)
    end
  end

  it "shows the subtitle for archived projects, next to the archived label" do
    # Archived projects are only listed once the "active" filter is set to false.
    archived_filter = JSON.dump([{ active: { operator: "=", values: ["f"] } }])
    visit "#{projects_page.path}?filters=#{archived_filter}"

    projects_page.within_row(archived_project) do
      expect(page).to have_css(".projects-table--name", text: archived_project.name)
      expect(page).to have_css(".archived-label", text: "(Archived)")
      expect(page).to have_css(subtitle_selector, text: "Archived tagline")
    end
  end

  it "reflects the current stored value after the subtitle changes and after it is cleared (FR-9)" do
    projects_page.within_row(project_with_subtitle) do
      expect(page).to have_css(subtitle_selector, text: "A short tagline")
    end

    project_with_subtitle.update!(subtitle: "An updated tagline")
    projects_page.visit!
    projects_page.within_row(project_with_subtitle) do
      expect(page).to have_css(subtitle_selector, text: "An updated tagline")
      expect(page).to have_no_css(subtitle_selector, text: "A short tagline")
    end

    project_with_subtitle.update!(subtitle: "")
    projects_page.visit!
    projects_page.within_row(project_with_subtitle) do
      expect(page).to have_no_css(subtitle_selector)
    end
  end

  context "for a user who cannot see a project (scenario 7, FR-5)" do
    shared_let(:hidden_project) do
      create(:project, name: "Hidden project", identifier: "hidden-subtitle",
                       public: false, subtitle: "Secret tagline")
    end
    shared_let(:visible_project) do
      create(:project, name: "Visible project", identifier: "visible-subtitle",
                       public: true, subtitle: "Public tagline")
    end

    let(:user) { create(:user) }

    before do
      ProjectRole.non_member
      login_as user
      projects_page.visit!
    end

    it "does not reveal the subtitle of a project the user cannot see, " \
       "but shows it for one they can" do
      expect(page).to have_no_text(hidden_project.name)
      expect(page).to have_no_css(subtitle_selector, text: "Secret tagline")

      expect(page).to have_text(visible_project.name)
      expect(page).to have_css(subtitle_selector, text: "Public tagline")
    end
  end
end
