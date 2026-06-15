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

RSpec.describe "Project settings: subtitle", :js do
  let(:permissions) { %i[edit_project] }
  let(:project) { create(:project) }
  let(:general_settings_page) { Pages::Projects::Settings::General.new(project) }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "allows an authorized user to set, edit, and clear the subtitle, persisting across reload" do
    general_settings_page.visit!

    # The field starts empty
    general_settings_page.expect_subtitle("")

    # Set a subtitle
    general_settings_page.set_subtitle("A short tagline")

    # The Primer flash banner confirms the save (it auto-hides, so we only assert
    # it appears and never require it to linger or be dismissed).
    expect_flash(message: I18n.t(:notice_successful_update))
    expect(project.reload.subtitle).to eq("A short tagline")

    # Persists across reload
    general_settings_page.visit!
    general_settings_page.expect_subtitle("A short tagline")

    # Edit the subtitle
    general_settings_page.set_subtitle("An edited tagline")

    expect_flash(message: I18n.t(:notice_successful_update))
    expect(project.reload.subtitle).to eq("An edited tagline")

    general_settings_page.visit!
    general_settings_page.expect_subtitle("An edited tagline")

    # Clear the subtitle
    general_settings_page.set_subtitle("")

    expect_flash(message: I18n.t(:notice_successful_update))
    expect(project.reload.subtitle).to be_nil

    general_settings_page.visit!
    general_settings_page.expect_subtitle("")
  end
end
