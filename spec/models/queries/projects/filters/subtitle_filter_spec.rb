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

RSpec.describe Queries::Projects::Filters::SubtitleFilter do
  include_context "filter tests"
  let(:values) { ["A subtitle", "Another subtitle"] }
  let(:model) { Project }

  it_behaves_like "basic query filter" do
    let(:class_key) { :subtitle }
    let(:human_name) { "Subtitle" }
    let(:type) { :string }
    let(:model) { Project }

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end
  end

  describe "#apply_to (generated SQL)" do
    # Mirrors name_filter_spec: each supported operator maps to the same
    # LOWER(projects.subtitle) ... predicate as the project name filter,
    # but targeting the subtitle column. Covers FR-9 (operator parity) and
    # FR-3 (case-insensitive LOWER(...) matching). AC8.
    context 'for "="' do
      let(:operator) { "=" }

      it "is the same as handwriting the query" do
        expected = model.where("LOWER(projects.subtitle) IN ('a subtitle', 'another subtitle')")

        expect(instance.apply_to(model).to_sql).to eql expected.to_sql
      end
    end

    context 'for "!"' do
      let(:operator) { "!" }

      it "is the same as handwriting the query" do
        expected = model.where("LOWER(projects.subtitle) NOT IN ('a subtitle', 'another subtitle')")

        expect(instance.apply_to(model).to_sql).to eql expected.to_sql
      end
    end

    context 'for "~"' do
      let(:operator) { "~" }

      it "is the same as handwriting the query" do
        expected = model.where("LOWER(projects.subtitle) LIKE '%a subtitle%'")

        expect(instance.apply_to(model).to_sql).to eql expected.to_sql
      end
    end

    context 'for "!~"' do
      let(:operator) { "!~" }

      it "is the same as handwriting the query" do
        expected = model.where("LOWER(projects.subtitle) NOT LIKE '%a subtitle%'")

        expect(instance.apply_to(model).to_sql).to eql expected.to_sql
      end
    end

    context 'for "**"' do
      let(:operator) { "**" }
      let(:values) { ["alpha beta"] }

      it "ANDs one case-insensitive LIKE per whitespace-separated term" do
        expected = model.where("LOWER(projects.subtitle) LIKE '%alpha%' AND LOWER(projects.subtitle) LIKE '%beta%'")

        expect(instance.apply_to(model).to_sql).to eql expected.to_sql
      end
    end
  end

  describe "#apply_to (result set)" do
    # Real records exercise matching, case-insensitivity, NULL/blank handling,
    # and literal treatment of LIKE metacharacters. Covers FR-1/FR-2/FR-3/FR-10.
    subject { instance.apply_to(model).to_a }

    shared_let(:logistics) { create(:project, subtitle: "Logistics Hub") }
    shared_let(:alpha) { create(:project, subtitle: "Team ALPHA") }
    shared_let(:no_subtitle) { create(:project, subtitle: nil) }
    # `normalizes :subtitle` squishes blank input down to nil, so this stays NULL.
    shared_let(:blank_subtitle) { create(:project, subtitle: "   ") }

    context 'with "~" (contains)' do
      let(:operator) { "~" }

      context "when matching case-insensitively (AC1, FR-3)" do
        let(:values) { ["logistics"] }

        it "includes the project regardless of letter case" do
          expect(subject).to contain_exactly(logistics)
        end
      end

      context "when the value is upper-case but the subtitle is mixed case" do
        let(:values) { ["alpha"] }

        it "still matches (case-insensitive)" do
          expect(subject).to contain_exactly(alpha)
        end
      end

      context "when no subtitle matches (AC6)" do
        let(:values) { ["nonexistent value"] }

        it "returns an empty result set without error" do
          expect(subject).to eq([])
        end
      end

      context "when projects have no subtitle (AC7, FR-10)" do
        let(:values) { ["hub"] }

        it "excludes NULL/blank-subtitle projects from contains matches" do
          expect(subject).to contain_exactly(logistics)
          expect(subject).not_to include(no_subtitle, blank_subtitle)
        end
      end
    end

    context 'with "=" (is)' do
      let(:operator) { "=" }
      let(:values) { ["logistics hub"] }

      it "matches the full subtitle case-insensitively and excludes NULL subtitles" do
        expect(subject).to contain_exactly(logistics)
        expect(subject).not_to include(no_subtitle, blank_subtitle)
      end
    end

    context 'with "!~" (does not contain)' do
      let(:operator) { "!~" }
      let(:values) { ["logistics"] }

      it "returns the non-matching projects (NOT LIKE)" do
        expect(subject).to contain_exactly(alpha)
        # NOT LIKE is NULL-unknown in SQL, so NULL-subtitle projects are not returned.
        expect(subject).not_to include(logistics, no_subtitle, blank_subtitle)
      end
    end

    context 'with "!" (is not)' do
      let(:operator) { "!" }
      let(:values) { ["logistics hub"] }

      it "returns the projects whose subtitle is not the value (NOT IN)" do
        expect(subject).to contain_exactly(alpha)
        expect(subject).not_to include(logistics, no_subtitle, blank_subtitle)
      end
    end

    context "with LIKE metacharacters in the value (special chars, parity with name filter)" do
      # The subtitle filter is a literal mirror of the NAME filter: it builds
      # "%#{value.downcase}%" without escaping, so SQL LIKE metacharacters
      # (`%`, `_`) keep their wildcard meaning. These specs pin that observable
      # behavior (no error, identical to the name filter) rather than asserting
      # escaping the production code does not perform.
      shared_let(:underscore_literal) { create(:project, subtitle: "a_b connector") }
      shared_let(:underscore_wildcard) { create(:project, subtitle: "aXb gizmo") }

      context 'with "%" in the value' do
        let(:operator) { "~" }
        let(:values) { ["100%"] }

        before { logistics } # ensure a non-matching subtitle is present

        it "matches without error (mirrors the name filter's unescaped LIKE)" do
          percent = create(:project, subtitle: "100% organic")

          expect { subject }.not_to raise_error
          expect(subject).to include(percent)
          expect(subject).not_to include(logistics, alpha)
        end
      end

      context 'with "_" in the value' do
        let(:operator) { "~" }
        let(:values) { ["a_b"] }

        it "treats `_` as a single-char wildcard, exactly like the name filter (no escaping)" do
          # Both 'a_b connector' and 'aXb gizmo' match because `_` is an
          # unescaped LIKE wildcard, consistent with the project name filter.
          expect(subject).to contain_exactly(underscore_literal, underscore_wildcard)
        end
      end
    end
  end
end
