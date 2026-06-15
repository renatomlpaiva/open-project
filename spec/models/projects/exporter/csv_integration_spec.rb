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
require_relative "exportable_project_context"

RSpec.describe Projects::Exports::CSV, "integration" do
  include_context "with a project with an arrangement of custom fields"
  include_context "with an instance of the described exporter"

  let(:parsed) do
    CSV.parse(output.delete_prefix(utf8_bom))
  end

  let(:utf8_bom) { "\xEF\xBB\xBF" }

  let(:header) { parsed.first }

  let(:rows) { parsed.drop(1) }

  it "performs a successful export" do
    expect(parsed.size).to eq(2)
    expect(parsed.last).to eq [project.name, project.description, "Off track", "false"]
  end

  it "starts with a UTF-8 BOM" do
    expect(output).to start_with(utf8_bom)
  end

  context "with status_explanation enabled" do
    let(:query_columns) { %w[name description project_status status_explanation public] }

    it "performs a successful export" do
      expect(parsed.size).to eq(2)
      expect(parsed.last).to eq [project.name, project.description,
                                 "Off track", "some explanation", "false"]
    end
  end

  context "with id and identifier selected" do
    let(:query_columns) { %w[name description id identifier project_status public] }

    it "performs a successful export" do
      expect(parsed.size).to eq(2)
      expect(parsed.last).to eq [project.name, project.description, project.id.to_s,
                                 project.identifier, "Off track", "false"]
    end
  end

  describe "custom field columns selected" do
    let(:query_columns) do
      %w[name description project_status public] + global_project_custom_fields.map(&:column_name)
    end

    context "without view_project_attributes permission" do
      let(:permissions) { super() - %i[view_project_attributes] }

      it "does not render project custom fields in the header" do
        expect(parsed.size).to eq 2

        expect(header).to eq ["Name", "Description", "Status", "Public"]
      end

      it "does not render the custom field values in the rows if enabled for a project" do
        expect(rows.first)
          .to eq [project.name, project.description, "Off track", "false"]
      end
    end

    context "with view_project_attributes permission" do
      it "renders available project custom fields in the header if enabled in any project" do
        expect(parsed.size).to eq 2

        cf_names = global_project_custom_fields.map(&:name)

        expect(cf_names).not_to include(not_used_string_cf.name)
        expect(cf_names).not_to include(hidden_cf.name)

        expect(header).to eq ["Name", "Description", "Status", "Public", *cf_names]
      end

      it "renders the custom field values in the rows if enabled for a project" do
        custom_values = global_project_custom_fields.map do |cf|
          case cf
          when bool_cf
            "true"
          when text_cf
            project.typed_custom_value_for(cf)
          when not_used_string_cf
            ""
          else
            project.formatted_custom_value_for(cf)
          end
        end
        expect(rows.first)
          .to eq [project.name, project.description, "Off track", "false", *custom_values]
      end
    end

    context "with admin permission" do
      let(:current_user) { create(:admin) }

      it "renders all globally available project custom fields including hidden ones in the header" do
        expect(parsed.size).to eq 3

        cf_names = global_project_custom_fields.map(&:name)

        expect(cf_names).to include(not_used_string_cf.name)
        expect(cf_names).to include(hidden_cf.name)

        expect(header).to eq ["Name", "Description", "Status", "Public", *cf_names]
      end

      it "renders the custom field values in the rows if enabled for a project" do
        custom_values = global_project_custom_fields.map do |cf|
          case cf
          when bool_cf
            "true"
          when hidden_cf
            "hidden"
          when not_used_string_cf
            ""
          when text_cf
            project.typed_custom_value_for(cf)
          else
            project.formatted_custom_value_for(cf)
          end
        end
        expect(rows.first)
          .to eq [project.name, project.description, "Off track", "false", *custom_values]
      end
    end
  end

  describe "custom comment columns selected" do
    let(:query_columns) do
      %w[name description project_status public] + global_project_custom_fields.map(&:comment_column_name)
    end

    context "without view_project_attributes permission" do
      let(:permissions) { super() - %i[view_project_attributes] }

      it "does not render custom comment columns in the header" do
        expect(parsed.size).to eq 2

        expect(header).to eq %w[Name Description Status Public]
      end

      it "does not render the custom comment values in the rows" do
        expect(rows.first).to eq [
          project.name,
          project.description,
          "Off track",
          "false"
        ]
      end
    end

    context "with view_project_attributes permission" do
      it "renders available custom comment columns in the header if enabled in any project" do
        expect(parsed.size).to eq 2

        expect(header).to eq %w[Name Description Status Public] + ["#{version_cf.name} comment"]
      end

      it "renders the custom comment values in the rows" do
        expect(rows.first).to eq [
          project.name,
          project.description,
          "Off track",
          "false",
          "Comment visible to members"
        ]
      end
    end

    context "with admin permission" do
      let(:current_user) { create(:admin) }

      it "renders all custom comment columns including hidden ones in the header" do
        expect(parsed.size).to eq 3

        expect(header).to eq %w[Name Description Status Public] + [version_cf, hidden_cf].map { "#{it.name} comment" }
      end

      it "renders all custom comment values in the rows" do
        expect(rows.first).to eq [
          project.name,
          project.description,
          "Off track",
          "false",
          "Comment visible to members",
          "Comment visible to admins"
        ]
      end
    end
  end

  context "with no project visible" do
    let(:current_user) { User.anonymous }

    it "does not include the project" do
      expect(output).not_to include project.identifier
      expect(parsed.size).to eq(1)
    end
  end

  # Feature 004 (T4): subtitle as a selectable, exportable CSV column.
  describe "with the subtitle column selected" do
    let(:query_columns) { %w[name description project_status public subtitle] }

    context "when the project has a subtitle (FR-1, FR-2, FR-3)" do
      before { project.update_column(:subtitle, "A concise project tagline") }

      it "adds a 'Subtitle' header at the selected position" do
        expect(header).to eq(%w[Name Description Status Public Subtitle])
      end

      it "emits the project's subtitle value in its row" do
        expect(rows.first).to eq(
          [project.name, project.description, "Off track", "false", "A concise project tagline"]
        )
      end
    end

    context "when the project has no subtitle (FR-4 — empty cell, no placeholder)" do
      before { project.update_column(:subtitle, nil) }

      it "still renders the 'Subtitle' header" do
        expect(header).to eq(%w[Name Description Status Public Subtitle])
      end

      it "renders an empty cell, not 'null' or a placeholder" do
        # CSV.parse yields nil for a trailing empty field; normalize to "".
        expect(rows.first[4].to_s).to eq("")
        expect(rows.first[4].to_s).not_to include("null")
      end
    end

    context "with special characters in the subtitle (FR-5 — escaped, file stays parseable)" do
      # The Project model normalizes subtitles: it collapses CR/LF into spaces
      # and squishes whitespace. We therefore assert the round-trip against the
      # value as actually stored (what a real export would contain), while still
      # exercising commas, double quotes, semicolons and non-ASCII characters
      # which must be CSV-escaped so the file remains parseable.
      let(:raw_subtitle) { %(Comma, "quote", semicolon; ümlaut & café — line\nbreak) }

      before { project.update!(subtitle: raw_subtitle) }

      it "preserves the stored value intact and keeps the file parseable" do
        stored = project.reload.subtitle

        # Sanity: the model has stripped the newline (normalization), and the
        # remaining special characters survive.
        expect(stored).to include('"quote"')
        expect(stored).to include("ümlaut & café")
        expect(stored).not_to include("\n")

        # The exported, escaped value round-trips through CSV.parse unchanged.
        expect(rows.first[4]).to eq(stored)
      end

      it "round-trips a value containing the CSV field separator and quotes" do
        project.update!(subtitle: %(a,b "c" d))

        expect(rows.first[4]).to eq("a,b \"c\" d")
        # Re-parsing the produced output succeeds (no corruption).
        expect { CSV.parse(output.delete_prefix(utf8_bom)) }.not_to raise_error
      end
    end

    context "with a 255-character subtitle (FR-9 — no truncation)" do
      let(:long_subtitle) { "x" * 255 }

      before { project.update!(subtitle: long_subtitle) }

      it "exports the full 255-character value untruncated" do
        expect(rows.first[4].length).to eq(255)
        expect(rows.first[4]).to eq(long_subtitle)
      end
    end
  end

  # FR-8: selecting subtitle must not change, remove or reorder any existing
  # column, and an export WITHOUT subtitle must remain unchanged.
  describe "FR-8 — existing columns unchanged when subtitle is (not) selected" do
    before { project.update_column(:subtitle, "Some subtitle") }

    it "leaves an export without subtitle untouched (no subtitle leakage)" do
      # Default query_columns: name, description, project_status, public.
      expect(header).to eq(%w[Name Description Status Public])
      expect(rows.first).to eq([project.name, project.description, "Off track", "false"])
    end

    context "when subtitle is appended to the existing selection" do
      let(:query_columns) { %w[name description project_status public subtitle] }

      it "keeps the existing columns and only appends the Subtitle column" do
        expect(header).to eq(%w[Name Description Status Public Subtitle])
        expect(rows.first.first(4)).to eq([project.name, project.description, "Off track", "false"])
        expect(rows.first.last).to eq("Some subtitle")
      end
    end
  end
end
