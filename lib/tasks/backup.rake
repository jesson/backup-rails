namespace "backup" do
  task "backup" => :environment do
    system "bundle exec backup perform -t general -c config/backup/config.rb -l tmp/backup/log -d tmp/backup/data --tmp-path=tmp/backup/tmp --cache-path=tmp/backup/cache"
  end

  task "restore" => :environment do
    Backup::Config.load Rails.root.join + 'config/backup/config.rb'
  end
end
