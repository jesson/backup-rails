# Backup::Rails

Backup rails project with backup & whenever gems

## Installation

Add this line to your application's Gemfile:

    gem 'backup-rails'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install backup-rails

## Usage

Generate configuration files:

    $ rails g backup:rails:install
    
And change .env file in the root of the project.

If you don't use [capistrano with whenever](https://github.com/javan/whenever#capistrano-v3-integration) run:

    $ whenever -w
    
for set crontab configuration.

## Restore

Run command for archive file (general.tar or general.tar.enc):

    $ backup_rails restore <path to archive> <destination path> [--ssl_password=<password>]
    
This command restore code to destination path and database according with database.yml in code.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
