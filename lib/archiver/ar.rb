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
      @files = {}
    end

    def files
      @files.to_enum
    end

    def [](file)
      @files[file]
    end

    def names
      @files.keys
    end

    def count
      @files.keys.length
    end

    def read
      return nil if @source.nil?
      @source.call.tap do |io|
        io.binmode
        preprocess(io)
        while (header = next_header(io))
          @files[header[:name]] = header.tap{ header[:raw] = read_file(header, io) }
        end
      end
      self
    end

    def add_file(name, opts = {}, &blk)
      if block_given?
        raw  = blk.call
        stat = Struct.new(:mode, :mtime, :uid, :gid).new(0660, Time.new, Process.uid, Process.gid)
      elsif name.is_a?(String)
        f    = File.open(name, "r")
        f.binmode
        stat = f.stat
        raw  = f.read
        f.close
      else
        raw  = name.read
        stat = name.stat
      end
      file                = {:name => name, :raw => raw, :mode => stat.mode, :mtime => stat.mtime, :uid => stat.uid, :gid => stat.gid}.merge(opts)
      file[:bytes]        = file[:raw].length
      # Ar doesn't appear to record the name with its path
      file[:name]         = File.basename(file[:name])
      @files[file[:name]] = file
      self
    end

    def write(path = @out, &blk)
      if block_given?
        yield StringIO.new.tap { |io| write_to(io) }.string
      elsif path.is_a?(String)
        File.open(path, "w") { |io| write_to(io) }
      else
        write_to(path)
      end
      self
    end


  private

    def write_to(io)
      io.write("!<arch>\n")
      @files.each do |_, file|
        normal         = file.clone
        normal[:mtime] = normal[:mtime].to_i
        if file[:name].length > 16
          normal[:name]   = "#1/#{file[:name].length + 3}"
          normal[:raw]    = "#{file[:name]}\0\0\0" + file[:raw]
          normal[:bytes] += file[:name].length + 3
        end

        io.write(sprintf("%-16s%-12u%-6d%-6d%-8o%-10u`\n", *[:name, :mtime, :uid, :gid, :mode, :bytes].map{|k| normal[k]}))
        io.write(normal[:raw])
        io.write("\n") if io.pos % 2 == 1
      end
      io.close
      self
    end

    def read_file(header, io)
      io.read(header[:bytes])
    end

    def next_header(io)
      return nil if io.eof?
      io.read(1) if io.pos % 2 == 1
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
      raise InvalidFormat unless header[:magic] == "`\n"
      if header[:name][0..2] == "#1/"
        # bsd format extended file name
        header[:name] = io.read(header[:name][3..-1].to_i)
        header[:bytes] -= header[:name].length
        header[:name] = header[:name][0..-4]
        # @todo support gnu format for extended file name
      end
      header
    end # next_header(io)

    def preprocess(io)
      raise InvalidFormat unless io.read(8) == "!<arch>\n"
    end # preprocess(io)
  end # class::Ar
end # module::Archiver
