require 'mysql2'
require 'mongoid'

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
      output += %x(cd #{tmp_path}/test_generator && mongorestore --db backup_rails mongodump)
    end
  end

  def drop_database database_type
    output = ""
    case database_type
    when 'mysql'
      output += %x(echo \"drop database backup_rails\" | mysql -u backup_rails)
    when 'mongodb'
      output += %x(cd #{tmp_path}/test_generator && mongo backup_rails --eval "db.dropDatabase()")
    end
  end
end
