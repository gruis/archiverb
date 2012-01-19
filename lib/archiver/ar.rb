require "stringio"
require "archiver"

module Archiver
  class Ar

    def initialize(path_or_io, *files, &blk)
      if block_given?
        @source = lambda { StringIO.new(blk.call) }
      elsif files.empty?
        @source = lambda { path_or_io.is_a?(IO) ? path_or_io : File.new(path_or_io, "r") }
      else
        @out = path_or_io
      end
      @files = []
    end

    def files
      @files.to_enum
    end

    def read
      return nil if @source.nil?
      @source.call.tap do |io|
        io.binmode
        raise ParseError unless io.read(8) == "!<arch>\n"
        while (header = next_header(io))
          @files.push( header.tap{header[:raw] = io.read(header[:bytes])} )
        end
      end
      self
    end

    def add_file(name, opts = {}, &blk)
      blk = lambda { IO.read(name) } unless block_given?
      @files.push( opts.merge({:raw => blk.call, :mode => 0660, :owner => Process.uid, :group => Process.gid}) )
      self
    end

    def write(path = @out, &blk)
      return nil unless @raw
      if block_given?
        yield(write_to(StringIO.new))
      elsif path.is_a?(IO)
        write_to(path)
      else
        File.open(path, "w") { |io| write_to(io) }
      end
      self
    end


  private

    def write_to(io)
      io.write("!<arch>\n")
      @files.each do |file|
        if file[:name] > 16
          io.write(sprintf("%-16s","#1/#{file[:name].length}"))
          io.write(sprintf("%-12lu%-6d%-6d%-8d%-10lu`\n", *[:mtime, :owner, :group, :mode, :bytes].map{|k| file[k]}))
          io.write(file[:name])
          io.write(file[:raw])
        else
          io.write(sprintf("%-16s%-12lu%-6d%-6d%-8d%-10lu`\n", *[:name, :mtime, :owner, :group, :mode, :bytes].map{|k| file[k]}))
          io.write(file[:raw])
        end
      end
      io.close
      self
    end

    def next_header(io)
      return nil if io.eof?
      header = {}
      header[:name]  = io.read(16) || (return nil)
      header[:name].strip!
      header[:mtime]  = io.read(12) || (return nil)
      header[:mtime]  = Time.at(header[:mtime].to_i)
      header[:owner] = io.read(6).to_i
      header[:group] = io.read(6).to_i
      header[:mode]  = io.read(8).to_i(8)
      header[:bytes] = io.read(10).to_i
      header[:magic] = io.read(2)
      #raise ParseError unless header[:magic] == "`\n"
      if header[:name][0..2] == "#1/"
        # bsd format extended file name
        header[:name] = io.read(header[:name][3..-1].to_i)

        # @todo support gnu format for extended file name
      end
      header
    end # next_header(io)

  end # class::Ar
end # module::Archiver
