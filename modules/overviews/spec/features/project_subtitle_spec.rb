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

RSpec.describe "Project Overview heading subtitle", :js do
  shared_let(:admin) { create(:admin) }

  let(:project) { create(:project, name: "Project Phoenix", subtitle: "A short tagline") }
  let(:subtitle_selector) { ".PageHeader-description .Truncate .Truncate-text" }

  before do
    login_as admin
  end

  def visit_overview
    visit project_overview_path(project)
    within "#content" do
      expect(page).to have_heading project.name
    end
  end

  it "shows the subtitle near the project name in the Overview heading (scenario 2, FR-2)" do
    visit_overview

    expect(page).to have_css(subtitle_selector, text: "A short tagline")
    expect(page).to have_css("#{subtitle_selector}[title='A short tagline']")
  end

  context "when the project has no subtitle (scenario 4, FR-3)" do
    let(:project) { create(:project, name: "Project Phoenix") }

    it "renders no description/subtitle element or placeholder" do
      visit_overview

      expect(page).to have_no_css(".PageHeader-description")
    end
  end

  it "reflects the updated value, then nothing after it is cleared (FR-9)" do
    visit_overview
    expect(page).to have_css(subtitle_selector, text: "A short tagline")

    project.update!(subtitle: "An updated tagline")
    visit_overview
    expect(page).to have_css(subtitle_selector, text: "An updated tagline")
    expect(page).to have_no_css(subtitle_selector, text: "A short tagline")

    project.update!(subtitle: "")
    visit_overview
    expect(page).to have_no_css(".PageHeader-description")
  end

  # NOTE: archived behaviour for the Overview heading is asserted at the component level
  # (page_header_component_spec, "when the project is archived"). OpenProject does not serve
  # the Overview page for an archived project (it 404s, even for admins), so the archived
  # subtitle cannot be exercised end-to-end on this surface. The archived-name-shows-subtitle
  # acceptance is covered end-to-end on the projects list, where archived rows are displayed.
end
