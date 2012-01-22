require "ostruct"
class Archiver
  class Stat < OpenStruct
    @@reqdatrs = [ :dev    , :dev_major , :dev_minor  , :ino        , :mode  , :nlink   ,
                   :gid    , :uid       , :rdev_major , :rdev_minor , :size  , :blksize ,
                   :blocks , :atime     , :mtime      , :ctime      , :ftype , :pipe?   ,
                   :rdev   , :symlink?
                 ]
    def initialize(io, start = {})
      return super(Hash[@@reqdatrs.map{|m| [m, false]}].merge(io)) if io.is_a?(Hash)
      return super(stat_hash(io).merge(start)) if io.is_a?(::File::Stat)

      statm = [:lstat, :stat].find{|m| io.respond_to?(m)}
      return super(Hash[@@reqdatrs.map{|m| [m, false]}].merge(start)) if statm.nil?

      hash = stat_hash(io.send(statm))
      hash[:readlink] = ::File.readlink(io) if hash[:symlink?]
      return super(hash.merge(start))
    end

    # ASCII representation of the owner and group of the file respectively.
    # In TAR, if found, the user and group IDs are used rather than the values
    # in the uid and gid fields.
    attr_accessor :uname, :gname


  private

    def stat_hash(stat)
      @@reqdatrs.inject({})  do |h , meth|
          h[meth] = stat.respond_to?(meth) ? stat.send(meth) : false
          h
      end
    end # stat_hash(stat, syms
  end # class::Stat < Openstruct
end # class::Archiver
