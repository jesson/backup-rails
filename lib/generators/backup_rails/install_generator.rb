require 'rails/generators'

module BackupRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Generates configurations for backup and whenever"

      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end

      # Generator Code. Remember this is just suped-up Thor so methods are executed in order
      def install
        run "bundle exec backup generate:config --config-path=config/backup"  unless File.exists?("config/backup/config.rb")
        template "general.rb", "config/backup/models/general.rb"
        if File.exists? ".env"
          append_file ".env" do
            File.read(File.expand_path(find_in_source_paths('.env')))
          end
        else
          template ".env"
        end
        run "bundle exec wheneverize ."  unless File.exists?("config/schedule.rb")
        append_file "config/schedule.rb" do
          File.read(File.expand_path(find_in_source_paths('schedule.rb')))
        end
      end
    end
  end
end
