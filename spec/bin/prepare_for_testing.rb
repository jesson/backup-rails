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
        #%w(sqlite3 mysql mongodb postgresql).each do |database_type|
        %w(mongodb).each do |database_type|
          path = "test_#{rails_version}_#{database_type}"
          remove_dir path
          run "gem install rails -v #{rails_version} --conservative"
          case database_type
          when 'sqlite3'
            run "rails _#{rails_version}_ new #{path} -d sqlite3 -B"
          when 'mysql'
            run "rails _#{rails_version}_ new #{path} -d mysql -B"
            inside path do
              gsub_file "config/database.yml", /username: root/, "username: backup_rails"
              gsub_file "config/database.yml", /database: (.+)$/, "database: backup_rails"
            end
          when 'postgresql'
            run "rails _#{rails_version}_ new #{path} -d postgresql -B"
          when 'mongodb'
            run "rails _#{rails_version}_ new #{path} -O -B"
          end
          inside path do
            gsub_file "config/environments/development.rb", "config.action_mailer", "# config.action_mailer" 
            append_file "Gemfile", "gem 'backup_rails', path: '../../'\n"
            append_file "Gemfile", "gem 'mongoid'\n"  if database_type == "mongodb"
            run "bundle install"
            run "rails generate mongoid:config"  if database_type == "mongodb"
            if database_type == 'mongodb'
              gsub_file "config/mongoid.yml", /database: (.+)$/, "database: backup_rails"
              append_file "config/mongoid.yml", 
<<-eos
production:
  sessions:
    default:
      hosts:
        - localhost:27017
      database: backup_rails
eos
            end
            run "rails generate scaffold post title:string body:text published_at:datetime"
            run "rake db:drop"
            run "rake db:create"
            run "rake db:migrate"
            remove_file "db/seeds.rb"
            create_file "db/seeds.rb", "10.times.each {|i| Post.create!(title: 'Title!', body: 'fjasdfhiwue72h3jh', published_at: Time.now)}"
            run "rake db:seed"

            # dump
            case database_type
            when 'mysql'
              run "mysqldump -ubackup_rails backup_rails > mysqldump.sql"
            when 'postgresql'
            when 'mongodb'
              run "mongodump --db backup_rails --out mongodump"
            end
          end
        end
      end
    end
  end

end

PrepareForTesting.start
