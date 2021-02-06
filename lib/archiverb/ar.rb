require 'archiverb'

class Archiverb
  class Ar < Archiverb

  private

    def write_to(io)
      io.write("!<arch>\n")
      @files.each do |_, file|
        normal         = [:name, :mtime, :uid, :gid, :mode].inject({}){|n,k| n.tap{ n[k] = file.send(k) } }
        normal[:mtime] = normal[:mtime].to_i
        normal[:raw]   = file.read
        if normal[:name].length > 16
          normal[:name]   = "#1/#{file.name.length + 3}"
          normal[:raw]    = "#{file.name}\0\0\0" + normal[:raw]
          normal[:size]  = file.name.length + 3
        end
        normal[:size]  = normal[:raw].length
        printf(io, "%-16s%-12u%-6d%-6d%-8o%-10u`\n", *[:name, :mtime, :uid, :gid, :mode, :size].map{|k| normal[k]})
        io.write(normal[:raw])
        io.write("\n") if io.pos % 2 == 1
      end
      io.close
      self
    end

    def next_header(io)
      return nil if io.eof?
      io.read(1) if io.pos % 2 == 1
      header = {}
      header[:name]  = io.read(16) || (return nil)
      header[:name].strip!
      header[:mtime]  = io.read(12) || (return nil)
      header[:uid] = io.read(6).to_i
      header[:gid] = io.read(6).to_i
      header[:mode]  = io.read(8).to_i(8)
      header[:size] = io.read(10).to_i
      header[:magic] = io.read(2)
      raise InvalidFormat unless header[:magic] == "`\n"
      if header[:name][0..2] == "#1/"
        # bsd format extended file name
        header[:name] = io.read(header[:name][3..-1].to_i)
        header[:size] -= header[:name].length
        header[:name] = header[:name][0..-4]
        # @todo support gnu format for extended file name
      end
      header
    end # next_header(io)

    def preprocess(io)
      raise InvalidFormat unless io.read(8) == "!<arch>\n"
    end

    def read_file(header, io)
      io.read(header[:size])
    end

    def skip_file(header, io)
      io.seek(header[:size], IO::SEEK_CUR)
    end

  end # class::Ar
end # class::Archiverb
