require "stringio"

class Archiver
  class File
    # the basename of the file
    attr_reader :name
    # the directory path leading to the file
    attr_reader :dir
    # the path and name of the file
    attr_reader :path
    # octal mode
    attr_accessor :mode
    # @return [Fixnum]
    attr_reader :uid, :gid
    # @return [Time] modification time
    attr_reader :mtime

    # the raw io object, you can add to it prior to calling read
    attr_reader :io
    attr_reader :stat

    def initialize(name, io, stat = io.stat)
      #stat   = io.stat if stat.nil? && io.respond_to?(:stat)
      @name  = ::File.basename(name)
      @dir   = ::File.dirname(name)
      @path  = name
      @mtime = stat.mtime.is_a?(Fixnum) ? Time.at(stat.mtime) : stat.mtime
      @uid   = stat.uid
      @gid   = stat.gid
      @mode  = stat.mode
      @bytes = stat.size
      @io    = io.is_a?(String) ? StringIO.new(io) : io
      @io.binmode
      @stat  = stat
    end # initialize(io, stat)

    def read
      @raw ||= @io.tap{ @io.rewind }.read.tap do |r|
        @bytes = r.length
        @io.close
      end
    end # read

  end # class::File
end # class::Archiver
