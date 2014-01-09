require "spec_helper"
require "generators/backup_rails/install_generator"

describe BackupRails::Generators::InstallGenerator do
  let(:tmp_path) { File.expand_path("../../../../../tmp", __FILE__) }
  let(:ssl_password) { "123123123" }
  let(:backup_path) { tmp_path + "/backups" }

  [false].each do |with_crypt|
    %w(postgresql).each do |database_type|
      %w(local).each do |storage_type|
        context "Code + #{database_type.capitalize} => #{storage_type.capitalize} => With#{!with_crypt ? "out":""} crypt" do
          rails_versions = %w(3.2.16)

          rails_versions.each do |rails_version|
            context "(rails #{rails_version})" do
              context "backup" do
                let(:test_rails_project_path) { "test_#{rails_version}_#{database_type}" }
                
                it "backups & restores" do
                  # prepare project
                  prepare_project

                  # restore database
                  restore_database(database_type)

                  write_env(storage_type, with_crypt)

                  assert_file "Gemfile", /gem 'backup_rails'/
                  assert_file "config/backup/config.rb"
                  assert_file "config/backup/models/general.rb"
                  assert_file "config/schedule.rb"

                  # remove backup dir
                  %x(rm -fr #{backup_path})

                  # backup
                  output = %x(cd #{tmp_path} && cd test_generator && bundle exec rake backup:backup)
                  expect(output).to_not match /\[warn\]/
                  expect(output).to_not match /\[error\]/

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
end
