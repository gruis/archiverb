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
    # The user id and group id of the file. Set #stat.uname and #stat.gname
    # to force ownership by name rather than id.
    attr_reader :uid, :gid
    # @return [Time] modification time
    attr_reader :mtime

    attr_reader :size
    alias :bytes :size

    # the raw io object, you can add to it prior to calling read
    attr_reader :io
    # [Archiver::Stat]
    attr_reader :stat

    def initialize(name, io, buff=io, stat=nil, &blk)
      buff,stat = stat, buff if buff.is_a?(Stat) || buff.is_a?(::File::Stat)
      stat = Stat.new(io) if stat.nil?

      @name  = ::File.basename(name)
      @dir   = ::File.dirname(name)
      @path  = name
      @mtime = stat.mtime.is_a?(Fixnum) ? Time.at(stat.mtime) : stat.mtime
      @uid   = stat.uid
      @gid   = stat.gid
      @mode  = stat.mode
      @size = stat.size

      @readbuff = buff
      @readback = blk unless blk.nil?
      @io       = io.is_a?(String) ? StringIO.new(io) : io
      @io.binmode
      if @io.respond_to?(:path) && ::File.directory?(@io.path)
        @size     = 0
      end
      @stat     = stat
    end # initialize(io, stat)

    def read
      return @raw if @raw

      if @readback && @readbuff
        @readback.call(@readbuff)
        @readbuff.close_write
      end

      @io.rewind unless @stat.pipe?

      if @io.respond_to?(:path) && ::File.directory?(@io.path)
        @raw  = ""
      else
        @raw    = @io.read
        @size  = @raw.length
      end
      @io.close
      @raw
    end # read

    # Prevents future access to the contents of the file and hopefully frees up memory.
    def close
      @raw = nil
    end # close

  end # class::File
end # class::Archiver
