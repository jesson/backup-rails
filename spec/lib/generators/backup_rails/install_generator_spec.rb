require "spec_helper"
require "generators/backup_rails/install_generator"

describe BackupRails::Generators::InstallGenerator do
  let(:tmp_path) { File.expand_path("../../../../../tmp", __FILE__) }

  let(:dbname) { "backup_rails" }
  let(:username) { "backup_rails" }
  let(:password) { "123123123" }

  let(:ssl_password) { "123123123" }
  let(:backup_path) { tmp_path + "/backups" }

  # Crypt variants
  [false, true].each do |with_crypt|

    # Database type variants
    %w(sqlite3 mysql mongodb postgresql).each do |database_type|

      # Storage type variants
      %w(local S3).each do |storage_type|
        context "Code + #{database_type.capitalize} => #{storage_type.capitalize} => With#{!with_crypt ? "out":""} crypt" do

          # Rails version variants
          %w(3.2.16).each do |rails_version|
            context "(rails #{rails_version})" do
              let(:test_rails_project_path) { "test_#{rails_version}_#{database_type}" }
              
              it "backups & restores" do
                # prepare project
                prepare_project

                # rails generate backup_rails:install
                install_config

                # restore database
                restore_database(database_type)

                assert_file "Gemfile", /gem 'backup_rails'/
                assert_file "config/backup/config.rb"
                assert_file "config/backup/models/general.rb"
                assert_file "config/schedule.rb"
                assert_file ".env"

                # fill .env
                write_env(storage_type, with_crypt)

                # backup
                backup_project

                # drop database
                drop_database(database_type)

                # check remote storage
                check_remote_storage(storage_type)

                # restore
                restore_project(with_crypt)

                # check code
                expect(compare_dirs(tmp_path + '/test_generator', tmp_path + '/test_generator_restore')).to be_true

                # check database
                expect(check_database(database_type)).to be_true
              end
            end
          end
        end
      end
    end
  end
end
