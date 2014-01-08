require "backup/rails/version"
require "rails"

module Backup
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load "tasks/backup.rake"
      end
    end
  end
end
