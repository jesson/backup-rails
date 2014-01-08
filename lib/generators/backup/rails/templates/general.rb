# encoding: utf-8

##
# Backup Generated: general
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t general [-c <path_to_configuration_file>]
#
Backup::Model.new(:general, 'Description for general') do

  <% root_path = Rails.root.split[0..-2].join("/") %>
  <% source_name = Rails.root.split.last %>
  archive :code do |archive|
    archive.root "<%= root_path %>"
    archive.add "<%= source_name %>"
    archive.exclude "<%= source_name %>/log"
    archive.exclude "<%= source_name %>/tmp"
  end

  compress_with Gzip do

  end

  store_with Local do |local|
    local.path = '../backup/'
    local.keep = 5
  end


end
