# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'backup/rails/version'

Gem::Specification.new do |gem|
  gem.name          = "backup-rails"
  gem.version       = Backup::Rails::VERSION
  gem.authors       = ["Oleg Bavaev"]
  gem.email         = ["jesoba7@gmail.com"]
  gem.description   = %q{Backup rails project with backup & whenever gems}
  gem.summary       = %q{Backup rails project}
  gem.homepage      = "https://github.com/jesson/capistrano3-nginx_unicorn"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('backup', '>= 3.2.0')
  gem.add_dependency('whenever')
end

