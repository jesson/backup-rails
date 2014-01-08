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
end
