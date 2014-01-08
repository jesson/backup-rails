# encoding: utf-8
require 'dotenv'
require "rails"

##
# Backup Generated: general
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t general [-c <path_to_configuration_file>]
#
Backup::Model.new(:general, 'Description for general') do
  Dotenv.load

  root_path = File.dirname(__FILE__)
  archive :code do |archive|
    archive.root root_path
    archive.add "."
    archive.exclude root_path + '/log'
    archive.exclude root_path + '/tmp'
  end

  compress_with Gzip do

  end

  if ENV['SSL_PASSWORD']
    encrypt_with OpenSSL do |encryption|
      encryption.password = ENV['SSL_PASSWORD']
      encryption.base64   = true
      encryption.salt     = true
    end
  end

  store_with Local do |local|
    local.path = '../backup/'
    local.keep = 5
  end


end
