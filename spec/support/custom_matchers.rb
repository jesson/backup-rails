require 'mysql2'
require 'mongoid'
require 'dotenv'
require 'fog'
require 'pg'

class Post
  include Mongoid::Document
  field :title
end

module CustomMatchers
  def assert_file(relative, *contents)
    absolute = File.expand_path(relative, tmp_path + "/test_generator")
    expect(File).to be_exists(absolute), "Expected file #{relative.inspect} to exist, but does not"

    read = File.read(absolute) if block_given? || !contents.empty?
    yield read if block_given?

    contents.each do |content|
      case content
        when String
          expect(content).to eq read
        when Regexp
          expect(content).to match read
      end
    end
  end

  def sameFile path1, path2
    return File.stat(path1).size == File.stat(path2).size
  end

  def compare_dirs dir1, dir2
    return false  unless File.exists?(dir1) && File.exists?(dir2)
    Dir.foreach(dir1) do |item|
      next if item == "." or item == ".."
      path1 = File.join(dir1, item)
      path2 = File.join(dir1, item)
      if File.directory?(path1)
        next  if File.symlink? path1
        return false  unless File.directory? path2

        compare_dirs(path1, path2)
      else
        return false  unless File.file? path2
        return false  unless sameFile(path1, path2)
      end
    end
    true
  end

  def check_database database_type
    case database_type
    when 'mysql'
      client = Mysql2::Client.new(:host => "localhost", :username => "backup_rails", database: "backup_rails")
      return client.query("select * from posts").count == 10
    when 'mongodb'
      Mongoid.configure.connect_to("backup_rails")
      return Post.count == 10
    when 'postgresql'
      conn = PG::Connection.new(dbname: "backup_rails", user: "backup_rails")
      return conn.exec("select * from posts").values.size == 10
    end
  end

  def restore_database database_type
    output = ""
    case database_type
    when 'mysql'
      output += %x(echo \"drop database backup_rails\" | mysql -u backup_rails)
      output += %x(echo \"create database backup_rails\" | mysql -u backup_rails)
      output += %x(cd #{tmp_path}/test_generator && mysql -u backup_rails backup_rails < mysqldump.sql)
    when 'mongodb'
      output += %x(cd #{tmp_path}/test_generator && mongorestore --db backup_rails mongodump/backup_rails)
    when 'postgresql'
      output += %x(dropdb -Ubackup_rails backup_rails)
      output += %x(createdb -Ubackup_rails backup_rails)
      output += %x(cd #{tmp_path}/test_generator && psql -Ubackup_rails backup_rails < pgsqldump.sql)
    end
  end

  def drop_database database_type
    output = ""
    case database_type
    when 'mysql'
      output += %x(echo \"drop database backup_rails\" | mysql -u backup_rails)
    when 'mongodb'
      output += %x(cd #{tmp_path}/test_generator && mongo backup_rails --eval "db.dropDatabase()")
    when 'postgresql'
      output += %x(dropdb -Ubackup_rails backup_rails)
    end
  end

  def write_env storage_type, with_crypt
    Dotenv.load
    File.open(tmp_path + "/test_generator/.env", "w") do |f|
      f.write("SSL_PASSWORD=#{ssl_password}\n")  if with_crypt
      case storage_type
      when 'local'
        f.write("LOCAL_PATH=#{backup_path}")
      when 'S3'
        f.write("S3_ACCESS_KEY_ID=\"#{ENV['S3_ACCESS_KEY_ID']}\"\n")
        f.write("S3_SECRET_ACCESS_KEY=\"#{ENV['S3_SECRET_ACCESS_KEY']}\"\n")
        f.write("S3_REGION=\"#{ENV['S3_REGION']}\"\n")
        f.write("S3_BUCKET=\"#{ENV['S3_BUCKET']}\"\n")
        f.write("S3_PATH=\"#{ENV['S3_PATH']}\"\n")
      end
    end
  end

  def check_remote_storage storage_type
    case storage_type
    when 'S3'
      connection = Fog::Storage.new({
        :provider                 => 'AWS',
        :aws_access_key_id        => ENV['S3_ACCESS_KEY_ID'],
        :aws_secret_access_key    => ENV['S3_SECRET_ACCESS_KEY']
      })
      dir = connection.directories.detect { | dir | dir.key == ENV["S3_BUCKET"] }
      file = dir.files.max_by {|f| f.last_modified }
      file_path = File.expand_path(file.key, tmp_path)
      path = File.dirname(file_path)
      %x(mkdir -p #{path})
      File.open(file_path, "wb") do |f|
        f.write file.body
      end
    end
  end

  def restore_project with_crypt
    %x(cd #{tmp_path} && rm -fr test_generator_restore)
    if with_crypt
      archive_path = Dir[backup_path + "/general/*/general.tar.enc"].first
      %x(cd #{tmp_path} && ../bin/backup_rails restore #{archive_path} #{tmp_path}/test_generator_restore --ssl_password=#{ssl_password})
    else
      archive_path = Dir[backup_path + "/general/*/general.tar"].first
      %x(cd #{tmp_path} && ../bin/backup_rails restore #{archive_path} #{tmp_path}/test_generator_restore)
    end
  end

  def prepare_project
    %x(cd #{tmp_path} && rm -fr test_generator && cp -r #{test_rails_project_path} test_generator)
    %x(cd #{tmp_path} && cd test_generator && rails generate backup_rails:install)
  end
end
