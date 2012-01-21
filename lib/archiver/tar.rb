require 'archiver'

class Archiver
  # GNU tar implementation
  # @see http://en.wikipedia.org/wiki/Tar_(file_format)
  # @see http://www.gnu.org/software/tar/manual/html_node/Standard.html
  class Tar < Archiver
    TMAGIC   = 'ustar'
    TVERSION = "00"
    REGTYPE  = '0'
    AREGTYPE = "\0"
    LNKTYPE  = '1'
    SYMTYPE  = '2'
    CHRTYPE  = '3'
    BLKTYPE  = '4'
    DIRTYPE  = '5'
    FIFOTYPE = '6'
    CONTTYPE = '7'
    XHDTYPE  = 'x'
    XGLTYPE  = 'g'

  private


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
      header[:mode]     = Integer(raw[100..107].strip)
      header[:uid]      = Integer(raw[108..115].strip)
      header[:gid]      = Integer(raw[116..123].strip)
      header[:size]     = Integer(raw[124..135].strip)
      header[:mtime]    = raw[136..147].strip
      header[:mtime]    = "0#{header[:mtime]}" if header[:mtime].length == 11
      header[:mtime]    = Time.at(Integer(header[:mtime]))
      # @todo convert this type to ftype
      # @todo use readlink, symlink?, etc.,.
      header[:ftype]     = raw[156]
      header[:linkname]  = raw[157..256].strip
      header[:magic]     = raw[257..262].strip
      header[:version]   = raw[263..264].strip
      header[:uname]     = raw[265..296].strip
      header[:gname]     = raw[297..328].strip
      header[:dev_major] = raw[329..336].strip
      header[:dev_minor] = raw[337..344].strip
      header[:prefix]    = raw[345..500].strip
      header.merge!(pull_ustar(raw)) if header[:magic] == "ustar"
      header
    end

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

  end # class::Tar < Archiver
end # class::Archiver
