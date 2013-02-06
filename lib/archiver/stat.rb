require "ostruct"
class Archiver
  class Stat < OpenStruct
    @@reqdatrs = [ :dev    , :dev_major , :dev_minor  , :ino        , :mode  , :nlink   ,
                   :gid    , :uid       , :rdev_major , :rdev_minor , :size  , :blksize ,
                   :blocks , :atime     , :mtime      , :ctime      , :ftype , :pipe?   ,
                   :rdev   , :symlink?
                 ]
    def initialize(io, start = {})
      return super(Hash[@@reqdatrs.map{|m| [m, def_v(m)]}].merge(io)) if io.is_a?(Hash)
      return super(stat_hash(io).merge(start)) if io.is_a?(::File::Stat)

      statm = [:lstat, :stat].find{|m| io.respond_to?(m)}
      return super(Hash[@@reqdatrs.map{|m| [m, def_v(m)]}].merge(stat_hash(io)).merge(start)) if statm.nil?

      hash = stat_hash(io.send(statm))
      hash[:readlink] = ::File.readlink(io) if hash[:symlink?]
      return super(hash.merge(start))
    end

    # ASCII representation of the owner and group of the file respectively.
    # In TAR, if found, the user and group IDs are used rather than the values
    # in the uid and gid fields.
    attr_accessor :uname, :gname


  private

    def def_v(attr)
      case attr
      when :atime, :ctime, :mtime
        Time.new
      when :size
        0
      when :gid
        Process.egid
      when :uid
        Process.euid
      when :mode
        16877
      else
        false
      end
    end

    def stat_hash(stat)
      @@reqdatrs.inject({})  do |h , meth|
          h[meth] = stat.respond_to?(meth) ? stat.send(meth) : def_v(meth)
          h
      end
    end # stat_hash(stat, syms
  end # class::Stat < Openstruct
end # class::Archiver
