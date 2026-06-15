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

RSpec.describe Queries::Projects::Selects::Default do
  describe ".key" do
    define_negated_matcher :not_match, :match

    let(:keys) { described_class::KEYS }

    it "matches every key" do
      expect(keys).to all(match(described_class.key))
    end

    it "doesn't match any key with prefix" do
      expect(keys.map { "x#{it}" }).to all(not_match(described_class.key))
    end

    it "doesn't match any key with suffix" do
      expect(keys.map { "#{it}x" }).to all(not_match(described_class.key))
    end
  end

  # Feature 004: subtitle is a selectable / exportable projects-list column.
  # The single load-bearing app change is adding :subtitle to KEYS.
  describe "subtitle as a selectable column (feature 004, T3)" do
    it "is present in KEYS" do
      expect(described_class::KEYS).to include(:subtitle)
    end

    it "is matched by the .key regex" do
      expect(described_class.key).to match("subtitle")
    end

    it "is returned by .all_available" do
      expect(described_class.all_available.map(&:attribute)).to include(:subtitle)
    end

    it "exposes the localized 'Subtitle' caption (FR-2, reuses existing i18n)" do
      select = described_class.new(:subtitle)

      expect(select.caption).to eq("Subtitle")
      expect(select.caption).to eq(Project.human_attribute_name(:subtitle))
    end
  end

  # API / query column validity: subtitle must resolve to a real select and be
  # listed among the available selects of a project query, while NOT being part
  # of the default-selected columns (opt-in, FR-8).
  describe "subtitle query column validity (feature 004, T3)" do
    let(:query) { ProjectQuery.new }

    it "resolves subtitle to a Selects::Default and not to NotExistingSelect" do
      select = query.select_for(:subtitle)

      expect(select).to be_a(described_class)
      expect(select).not_to be_a(Queries::Selects::NotExistingSelect)
      expect(select.attribute).to eq(:subtitle)
    end

    it "is listed in the query's available_selects (API column validity)" do
      expect(query.available_selects.map(&:attribute)).to include(:subtitle)
    end

    it "is opt-in: subtitle is not among the default-selected columns" do
      expect(Setting.enabled_projects_columns).not_to include("subtitle")
      expect(query.selects.map(&:attribute)).not_to include(:subtitle)
    end
  end
end
