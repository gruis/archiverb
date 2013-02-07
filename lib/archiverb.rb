require "archiverb/stat"
require "archiverb/file"

# Provides a common interface for working with different types of
# archive formats.
#
# @example
#   arc = Archiverb::Ar.new("junk.ar", "a.txt", "b.txt", "c.txt")
#   arc.write("/tmp/junk.ar")  # => creates /tmp/junk.ar with {a,b,c}.txt
class Archiverb
  module Error; end
  class StandarError < ::StandardError; include Error; end
  class ArgumentError < ::ArgumentError; include Error; end
  class InvalidFormat < StandardError; end
  class WrongChksum < StandardError; end
  class AbstractMethod < StandardError; end

  include Enumerable

  attr_accessor :prefix

  def initialize(path_or_io = nil, *files, &blk)
    raise NotImplementedError if self.class == Archiverb
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
      @source = lambda { path_or_io.is_a?(IO) ? path_or_io : ::File.new(path_or_io, "a+").tap{|f| f.rewind } }
    end
    @out = path_or_io
    @files = {}
  end

  def path
    @out
  end

  def files
    @files.values
  end

  def [](file)
    @files[file]
  end

  # Iterate over each file.
  # @yield { |name, file| }
  def each(&blk)
    @files.each(&blk)
  end

  def names
    @files.keys
  end

  def count
    @files.keys.length
  end

  # Pulls each file out of the archive and places them in #files.
  # @todo take a block and yield each file as it's read without storing it in #files
  def read
    return self if @source.nil?
    io = @source.call
    io.binmode
    preprocess(io)
    while (header = next_header(io))
      @files[header[:name]] = File.new(header[:name], read_file(header, io), Stat.new(header))
    end
    io.close
    self
  end

  # Add a file to the archive.
  # @param [String, File, IO]
  # @param [Hash] opts options to pass to Stat.new
  # @param [IO, ::File, String, StringIO] io
  def add(name, opts = {}, io = nil, &blk)
    if block_given?
      @files[name] = File.new(name, *IO.pipe, &blk)
      return self
    end

    if io
      opts, io = io, opts if io.is_a?(Hash)
    elsif !opts.is_a?(Hash)
      opts, io = {}, opts
    end

    if io
      if io.is_a?(String) || io.is_a?(StringIO) || io.is_a?(IO) || io.is_a?(::File)
        @files[name] = File.new(name, io, Stat.new(io, opts))
      else
        raise ArgumentError.new("unsupported data source: #{io.class}")
      end
    else
      case name
      when String
        fio = ::File.exists?(name) ? ::File.new(name, "r") : ""
        @files[name] = File.new(name, fio, Stat.new(fio, opts))
      when ::File
        @files[name.path] = File.new(name.path, name, Stat.new(name, opts))
      else
        opts[:name] = name.respond_to?(:path) ? name.path : name.__id__.to_s if opts[:name].nil?
        @files[opts[:name]] = File.new(opts[:name], name, Stat.new(name, opts))
      end
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
      path.truncate
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
end # class::Archiverb
