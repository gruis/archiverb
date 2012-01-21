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
  class WrongChksum < StandardError; end
  class AbstractMethod < StandardError; end

  include Enumerable

  def initialize(path_or_io = nil, *files, &blk)
    raise NotImplementedError if self.class == Archiver
    @opts = files.last.is_a?(Hash) ? files.pop : {}
    files.each { |file|  add(file) }
    if block_given?
      r, w = IO.pipe
      @source = lambda do
        blk.call(w)
        w.close unless w.closed?
        r
      end
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
    io = @source.call
    io.binmode
    preprocess(io)
    while (header = next_header(io))
      @files[header[:name]] = File.new(header[:name], read_file(header, io), OpenStruct.new(header))
    end
    io.close
    self
  end

  # Add a file to the archive.
  # @param [String, File, IO]
  def add(name, opts = {}, &blk)
    if block_given?
      r, w = IO.pipe
      @files[name] = File.new(name, r, r.stat, w, &blk)
    elsif name.is_a?(String)
      @files[name] = File.new(name, ::File.open(name, "r+"))
    else
      opts[:name] = name.respond_to?(:path) ? name.path : name.__id__.to_s if opts[:name].nil?
      @files[opts[:name]] = File.new(opts[:name], name)
    end
    self
  end

  def write(path = @out, &blk)
    if block_given?
      # use a pipe instead?
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
    raise AbstractMethod
  end

  # Abstract method
  # Get the next header for the next file
  def next_header(io)
    raise AbstractMethod
  end

  # Abstract method
  # Perform any preprocessing and validation on the archive.
  # Inheriting classes aren't requried to implement this method.
  def preprocess(io)
  end

  # Abstract method
  # Given a file header and an IO that is the archive retrieve the file.
  def read_file(header, io)
    raise AbstractMethod
  end

end # class::Archiver
