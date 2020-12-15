# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency"
require "dependabot/dependency_file"
require "dependabot/shared_helpers"
require "dependabot/elm/file_updater"
require_common_spec "file_updaters/shared_examples_for_file_updaters"

RSpec.describe Dependabot::Elm::FileUpdater do
  it_behaves_like "a dependency file updater"

  let(:updater) do
    described_class.new(
      dependency_files: files,
      dependencies: [dependency],
      credentials: credentials
    )
  end

  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end
  let(:files) { [elm_package_file, elm_json_file] }
  let(:elm_package_file) do
    Dependabot::DependencyFile.new(
      content: fixture("elm_packages", elm_package_file_fixture_name),
      name: "elm-package.json"
    )
  end
  let(:elm_package_file_fixture_name) { "elm_css_and_datetimepicker" }
  let(:elm_json_file) do
    Dependabot::DependencyFile.new(
      content: fixture("elm_jsons", elm_json_file_fixture_name),
      name: "elm.json"
    )
  end
  let(:elm_json_file_fixture_name) { "app.json" }

  let(:dependency) do
    Dependabot::Dependency.new(
      name: "rtfeldman/elm-css",
      version: "14.0.0",
      requirements: [{
        file: "elm-package.json",
        requirement: "14.0.0 <= v <= 14.0.0",
        groups: [],
        source: nil
      }],
      previous_version: "13.1.1",
      previous_requirements: [{
        file: "elm-package.json",
        requirement: "13.1.1 <= v <= 13.1.1",
        groups: [],
        source: nil
      }],
      package_manager: "elm"
    )
  end
  let(:tmp_path) { Dependabot::Utils::BUMP_TMP_DIR_PATH }

  before { Dir.mkdir(tmp_path) unless Dir.exist?(tmp_path) }

  describe "#updated_dependency_files" do
    subject(:updated_files) { updater.updated_dependency_files }

    it "doesn't store the files permanently" do
      expect { updated_files }.to_not(change { Dir.entries(tmp_path) })
    end

    it "returns DependencyFile objects" do
      updated_files.each { |f| expect(f).to be_a(Dependabot::DependencyFile) }
    end

    it { expect { updated_files }.to_not output.to_stdout }
    its(:length) { is_expected.to eq(1) }

    describe "the updated elm_package_file" do
      subject(:updated_elm_package_file_content) do
        updated_files.find { |f| f.name == "elm-package.json" }.content
      end

      it "updates the right dependency" do
        expect(updated_elm_package_file_content).
          to include(%("rtfeldman/elm-css": "14.0.0 <= v <= 14.0.0",))
        expect(updated_elm_package_file_content).
          to include(%("NoRedInk/datetimepicker": "3.0.1 <= v <= 3.0.1"))
      end

      context "when the requirements haven't changed" do
        let(:dependency) do
          Dependabot::Dependency.new(
            name: "rtfeldman/elm-css",
            version: "14.0.0",
            requirements: [{
              file: "elm-package.json",
              requirement: "13.1.1 <= v <= 13.1.1",
              groups: [],
              source: nil
            }],
            previous_version: "13.1.1",
            previous_requirements: [{
              file: "elm-package.json",
              requirement: "13.1.1 <= v <= 13.1.1",
              groups: [],
              source: nil
            }],
            package_manager: "elm"
          )
        end

        it "raises a runtime error" do
          expect { updated_elm_package_file_content }.
            to raise_error("No files have changed!")
        end
      end
    end

    describe "the elm.json file" do
      subject(:updated_elm_json_file_content) do
        updated_files.find { |f| f.name == "elm.json" }.content
      end

      let(:dependency) do
        Dependabot::Dependency.new(
          name: "elm/regex",
          version: "1.1.0",
          requirements: [{
            file: "elm.json",
            requirement: "1.1.0",
            groups: [],
            source: nil
          }],
          previous_version: "1.0.0",
          previous_requirements: [{
            file: "elm.json",
            requirement: "1.0.0",
            groups: [],
            source: nil
          }],
          package_manager: "elm"
        )
      end

      it "updates the right dependency" do
        expect(updated_elm_json_file_content).
          to include(%("elm/regex": "1.1.0"))
        expect(updated_elm_json_file_content).
          to include(%("elm/html": "1.0.0"))
      end
    end
  end
end
