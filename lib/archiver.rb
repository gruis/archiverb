require "ostruct"
require "archiver/file"

# Provides a common interface for working with different types of
# archive formats.
#
# @example
#   arc = Archiver::Ar.new("junk.ar", "a.txt", "b.txt", "c.txt")
#   arc.write("/tmp/junk.ar")  # => creates /tmp/junk.ar with {a,b,c}.txt
#
class Archiver
  module Error; end
  class StandarError < ::StandardError; include Error; end
  class InvalidFormat < StandardError; end
  class AbstractMethod < StandardError; end

  include Enumerable

  def initialize(path_or_io = nil, *files, &blk)
    raise NotImplementedError if self.class == Archiver
    @opts = files.last.is_a?(Hash) ? files.pop : {}
    files.each do |file|
      case file
      when String
        @files[file] = File.new(file, (io = File.new(file, "r")), io.stat)
      when ::File
        @files[file.path] = File.new(file.path, file, file.stat)
      when IO
        @files[file.__id__] = File.new(file.__id__, file, file.stat)
      else
        raise ArgumentError.new("can't use #{file} as an input")
      end
    end # file

    if block_given?
      @source = lambda { StringIO.new(blk.call) }
    else
      @source = lambda { path_or_io.is_a?(IO) ? path_or_io : ::File.new(path_or_io, "r") }
    end
    @out = path_or_io
    @files = {}
  end

  def files
    @files.values
  end

  def [](file)
    @files[file]
  end

  def each(&blk)
    @files.each(&blk)
  end # each(&blk)

  def names
    @files.keys
  end

  def count
    @files.keys.length
  end

  def read
    return self if @source.nil?
    @source.call.tap do |io|
      io.binmode
      preprocess(io)
      while (header = next_header(io))
        @files[header[:name]] = File.new(header[:name], read_file(header, io), OpenStruct.new(header))
      end
    end
    self
  end

  def add(name, opts = {}, &blk)
    if block_given?
      io   = blk.call
      stat = Struct.new(:mode, :mtime, :uid, :gid).new(0660, Time.new, Process.uid, Process.gid)
    elsif name.is_a?(String)
      io   = ::File.open(name, "r")
      stat = io.stat
    else
      io   = name
      stat = name.stat
    end
    @files[name] = File.new(name, io, OpenStruct.new({:name => name, :mode => stat.mode, :mtime => stat.mtime, :uid => stat.uid, :gid => stat.gid}.merge(opts)))
    self
  end

  def write(path = @out, &blk)
    if block_given?
      yield StringIO.new.tap { |io| write_to(io) }.string
    elsif path.is_a?(String)
      ::File.open(path, "w") { |io| write_to(io) }
    else
      write_to(path)
    end
    self
  end

private

  # Abstract method
  # Write all files in the archive, in the archive format, to the given IO
  # @return [Hash] must have :name, :mtime, :uid, :gid, and mode
  def write_io(io)
    raise NotImplementedError
  end

  # Abstract method
  # Get the next header for the next file
  def next_header(io)
    raise NotImplementedError
  end

  # Abstract method
  # Perform any preprocessing and validation on the archive
  def preprocess(io)
    raise NotImplementedError
  end

  # Abstract method
  # Given a file header and an IO that is the archive retrieve the file.
  def read_file(header, io)
    raise NotImplementedError
  end

end # class::Archiver
