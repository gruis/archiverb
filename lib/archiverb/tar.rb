require 'archiverb'
require 'etc'

class Archiverb
  # GNU tar implementation
  # @see http://en.wikipedia.org/wiki/Tar_(file_format)
  # @see http://www.gnu.org/software/tar/manual/html_node/Standard.html
  # @see http://www.subspacefield.org/~vax/tar_format.html
  class Tar < Archiverb
    TMAGIC       = 'ustar'
    TVERSION     = "00"
    OLDGNU_MAGIC = "ustar  \0"
    REGTYPE      = '0'  # regular file
    AREGTYPE     = "\0" # regular file
    LNKTYPE      = '1'  # link
    SYMTYPE      = '2'  # reserved (symlink)
    CHRTYPE      = '3'  # character special
    BLKTYPE      = '4'  # block special
    DIRTYPE      = '5'  # directory
    FIFOTYPE     = '6'  # FIFO special
    CONTTYPE     = '7'  # reserved (contiguous file)
    XHDTYPE      = 'x'  # extended header referring to next file in archive
    XGLTYPE      = 'g'  # global extended header


  private

    def write_to(io)
      @files.each do |name, file|
        if name.length > 100
          name, prefix = name[0..99], name[100..-1]
          if prefix > 155
            raise ArgumentError.new("file name cannot exceed 255 characters: #{name}#{prefix}")
          end
        else
          prefix = ""
        end
        header = "#{name}" + ("\0" * (100 - name.length))
        # @todo double check the modes on links
        # input header: data/henryIV.txt0000755000076500000240000000000011706250470015332 2heneryIV.txtustar  calebstaff
        # output header: data/henryIV.txt0050423000076500000240000000001411706305252015333 2heneryIV.txtustar  calebstaff

        # offset 100
        header += sprintf("%.7o\0", file.mode)
        # offset 108
        header += sprintf("%.7o\0", file.uid)
        # offset 116
        header += sprintf("%.7o\0", file.gid)
        # offset 124
        header += sprintf("%.11o\0", file.size)
        # offset 136
        header += sprintf("%.11o\0", file.mtime.to_i)
        # offset 148
        header += " " * 8 # write 8 blanks for the checksum, we'll replace it later

        # offset 156
        if [LNKTYPE, SYMTYPE].include?(type = tar_type(file.stat))
          header += sprintf("%.1o", type)
          raise ArgumentError.new("#{name} link type files' stat objects must contain a readlink") if file.stat.readlink.nil?
          # offset 157
          header += "#{file.stat.readlink}\0" + ("\0" * (99 - file.stat.readlink.length))
        else
          type = DIRTYPE if name[-1] == "/"
          header += sprintf("%.1o", type)
          # offset 157
          header += "\0"*100
        end

        # offset 257
        header += OLDGNU_MAGIC

        uname = file.stat.uname || Etc.getpwuid(file.uid).name
        gname = file.stat.gname || Etc.getgrgid(file.gid).name
        # offset 265
        header += "#{uname}\0" + ("\0" * (31 - uname.length))
        # offset 297
        header += "#{gname}\0" + ("\0" * (31 - gname.length))

        # offset 329
        if type == CHRTYPE || type ==BLKTYPE
          header += sprintf("%.7o\0", file.stat.dev_major)
          header += sprintf("%.7o\0", file.stat.dev_minor)
        else
          header += "\0" * 16
        end

        # offset 345
        header += "#{prefix}" + ("\0" * (155 - (prefix || "").length))

        # offset 500
        header += "\0" * 12

        header = header[0..147] + chksum(header) + header[156..-1]
        io.write(header)
        io.write(file.read).tap do |len|
          unless (overflow = len % 512) == 0
            io.write("\0" * (512 - (overflow)))
          end
        end
      end # name, file

      io.write("\0" * 1024)
      self
    end # write_to(io)

    def next_header(io)
      return nil if io.eof?
      if (raw = io.read(512)).strip == ""
        return nil if(raw = io.read(512)).strip == ""
      end # raw.strip == ""

      header            = {}
      header[:name]     = raw[0..99].strip
      check             = chksum(raw)
      header[:chksum]   = raw[148..155]
      raise WrongChksum.new("#{header[:name]}: #{header[:chksum]} expected to be #{check}") unless header[:chksum] == check
      header[:mode]     = raw[100..107].to_i(8)
      header[:uid]      = Integer(raw[108..115].strip)
      header[:gid]      = Integer(raw[116..123].strip)
      header[:size]     = Integer(raw[124..135].strip)
      header[:mtime]    = raw[136..147].strip
      header[:mtime]    = "0#{header[:mtime]}" if header[:mtime].length == 11
      header[:mtime]    = Time.at(Integer(header[:mtime]))
      # @todo check for XHDTYPE, or XGLTYPE
      header[:ftype]     = stat_type(raw[156])
      header[:readlink]  = raw[157..256].strip
      header[:magic]     = raw[257..262].strip
      header[:version]   = raw[263..264].strip
      header[:uname]     = raw[265..296].strip
      header[:gname]     = raw[297..328].strip
      header[:dev_major] = raw[329..336].strip
      header[:dev_minor] = raw[337..344].strip
      header[:prefix]    = raw[345..500].strip
      header.merge!(pull_ustar(raw)) if header[:magic] == TMAGIC
      header
    end

    def tar_type(stat)
      case stat.ftype
      when 'file'
        REGTYPE
      when 'directory'
        DIRTYPE
      when 'characterSpecial'
        CHRTYPE
      when 'blockSpecial'
        BLKTYPE
      when 'fifo'
        FIFOTYPE
      when 'link'
        #LNKTYPE
        SYMTYPE
      else
        warn "file type: #{stat.ftype} is not supported; treating it as a regular file"
        REGTYPE
      end
    end # tar_type(stat)

    def stat_type(bit)
      case bit
      when REGTYPE, AREGTYPE
        'file'
      when LNKTYPE, SYMTYPE
        'link'
      when CHRTYPE
        'characterSpecial'
      when BLKTYPE
        'blockSpecial'
      when DIRTYPE
        'directory'
      when FIFOTYPE
        'fifo'
      when CONTTYPE, XHDTYPE, XGLTYPE
        'unknown'
      else
        warn "file type #{bit} is not supported; treating it as a regular file"
        'regular'
      end
    end # stat_type(bit)
    def read_file(header, io)
      io.read(header[:size]).tap do |raw|
        if (diff = header[:size] % 512) != 0
          io.read(512 - diff)
        end
      end # raw
    end

    def pull_ustar(raw)
      header              = {}
      header[:prefix]     = raw[345].strip
      header[:fill2]      = raw[346].strip
      header[:fill3]      = raw[347..354].strip
      header[:isextended] = raw[355]
      header[:sparse]     = raw[356..451].strip
      header[:realsize]   = raw[452..463].strip
      header[:offset]     = raw[464..475].strip
      header[:atime]      = raw[476..487].strip
      header[:ctime]      = raw[488..499].strip
      header[:mfill]      = raw[500..507].strip
      header[:xmagic]     = raw[508..511].strip
      header
    end # pull_ustar(header)

    # The checksum is calculated by taking the sum of the unsigned byte
    # values of the header block with the eight checksum bytes taken to
    # be ascii spaces (decimal value 32). It is stored as a six digit
    # octal number with leading zeroes followed by a NUL and then a
    # space.
    def chksum(header)
      sprintf("%.6o\0 ", (header[0..147] + header[156..500]).each_byte.inject(256) { |s,b| s+b })
    end

  end # class::Tar < Archiverb
end # class::Archiverb
