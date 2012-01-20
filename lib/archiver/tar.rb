require 'archiver'

class Archiver
  # GNU tar implementation
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


    def preprocess(io)

    end # preprocess(io)

    def next_header(io)
      return nil if io.eof?
      raw               = io.read(512)
      header            = {}
      header[:name]     = raw[0..99].strip
      header[:mode]     = raw[100..107].strip
      header[:uid]      = raw[108..115].strip
      header[:gid]      = raw[116..123].strip
      header[:size]     = raw[124..135].strip.to_i
      header[:mtime]    = raw[136..147].strip.to_i
      header[:chksum]   = raw[148..155].strip.to_i
      header[:typeflag] = raw[156]
      header[:linkname] = raw[157..256].strip
      header[:magic]    = raw[257..262].strip
      header[:version]  = raw[263..264].strip
      header[:uname]    = raw[265..296].strip
      header[:gname]    = raw[297..328].strip
      header[:devmajor] = raw[329..336].strip
      header[:devminor] = raw[337..344].strip
      header[:prefix]   = raw[345..500].strip
      header
    end

    def read_file(header, io)
      io.read(header[:size])
    end
  end # class::Tar < Archiver
end # class::Archiver
