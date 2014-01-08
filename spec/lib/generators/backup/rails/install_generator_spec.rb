require "spec_helper"
require "generators/backup/rails/install_generator"

describe Backup::Rails::Generators::InstallGenerator do
  let(:tmp_path) { File.expand_path("../../../../../../tmp", __FILE__) }

  context "Code + Sqlite3 => Local" do
    rails_versions = %w(3.2.16)

    rails_versions.each do |rails_version|
      test_rails_project_path = "test_#{rails_version}_sqlite"

      context "(rails #{rails_version})" do
        context "backup" do
          it "creates a backup config.rb" do
            %x(cd #{tmp_path} && rm -fr test_generator && cp -r #{test_rails_project_path} test_generator)
            %x(cd #{tmp_path} && cd test_generator && rails generate backup:rails:install)

            assert_file "Gemfile", /gem 'backup-rails'/
            assert_file "config/backup/config.rb"
            assert_file "config/backup/models/general.rb"
            assert_file "config/schedule.rb"
          end
        end

        context "restore" do
          it "archives as file" do
            # remove backup dir
            %x(cd #{tmp_path} && rm -fr backup)

            # backup
            output = %x(cd #{tmp_path} && cd test_generator && bundle exec rake backup:backup)
            expect(output).to_not match /\[warn/
            expect(output).to_not match /\[error/

            # restore
            %x(cd #{tmp_path} && rm -fr test_generator_old && cp -r test_generator test_generator_old)
            backup_path = Dir[tmp_path + "/backup/general/*/general.tar"].first
            %x(cd #{tmp_path} && ../bin/backup_rails restore #{backup_path} #{tmp_path}/test_generator)

            # compare
            expect(compare_dirs(tmp_path + '/test_generator_old', tmp_path + '/test_generator')).to be_true
          end
        end
      end
    end
  end
end
