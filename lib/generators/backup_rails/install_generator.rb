require 'rails/generators'
module BackupRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Generates configurations for backup and whenever"

      # Commandline options can be defined here using Thor-like options:
      # class_option :my_opt, :type => :boolean, :default => false, :desc => "My Option"

      # I can later access that option using:
      # options[:my_opt]


      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end

      # Generator Code. Remember this is just suped-up Thor so methods are executed in order
      def install
        run "bundle exec backup generate:config --config-path=config/backup"  unless File.exists?("config/backup/config.rb")
        template "general.rb", File.join(%w(config backup models general.rb))
        run "bundle exec wheneverize ."  unless File.exists?("config/schedule.rb")
      end


    end
  end
end
