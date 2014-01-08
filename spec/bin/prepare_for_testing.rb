#!/usr/bin/env ruby
require 'thor'

class PrepareForTesting < Thor
  include Thor::Actions

  def self.source_root
    File.dirname(__FILE__)
  end

  desc "Generate", "Generate rails apps for testing"
  def generate
    destination_root = File.dirname(__FILE__) + "/../../tmp"
    inside destination_root do
      rails_versions = %w(3.2.16)
      rails_versions.each do |rails_version|
        path = "test_#{rails_version}_sqlite"
        remove_dir path
        run "gem install rails -v #{rails_version} --conservative"
        run "rails _#{rails_version}_ new #{path} -d sqlite3 -B"
        inside path do
          gsub_file "config/environments/development.rb", "config.action_mailer", "# config.action_mailer" 
          append_file "Gemfile", "gem 'backup_rails', path: '../../'\n"
          run "bundle install"
        end
      end
    end
  end

end

PrepareForTesting.start
