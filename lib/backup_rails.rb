require "backup_rails/version"
require "rails"

module BackupRails
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/backup.rake"
    end
  end
end
