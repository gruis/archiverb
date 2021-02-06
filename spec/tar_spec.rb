require File.expand_path("../spec_helper.rb", __FILE__)

require 'archiverb/tar'

describe Archiverb::Tar do
  include Archiverb::Test
  it "should correctly unarchive text data" do
    tar = nil
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read
    tar.files.size.should == 3
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")
    tar["data/henryIV.txt"].should_not be_nil
    tar["data/henryIV.txt"].stat.ftype.should == "link"
    tar["data/henryIV.txt"].stat.readlink.should == "heneryIV.txt"
  end # should correctly unarchive text data

  it "should unarchive only files selected by glob" do
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read("data/henery*")
    tar.files.size.should == 2
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")

    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read("*westmore*")
    tar.files.size.should == 1
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")
  end

  it "should unarchive only files selected by regexp" do
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(%r|data/henery.*|)
    tar.files.size.should == 2
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")

    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(/westmore/)
    tar.files.size.should == 1
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")
  end

  it "should raise error on unsupported filter" do
    filter = 123
    lambda {
      Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(filter)
    }.should raise_error(ArgumentError, "unsupported filter type: #{filter.class}")
  end

  it "should correctly tar text data" do
    Dir.chdir(File.join(File.dirname(__FILE__), "data")) do
      Archiverb::Tar.new.tap do |archive|
        archive.add("heneryIV-westmoreland.txt", :mtime => 1360125714)
        archive.add("heneryIV.txt", :mtime => 1360125720)
        archive.count.should == 2
        archive.files.should_not be_empty
        archive.names == ['heneryIV-westmoreland.txt', 'heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "e3682cc31ca37afab9924f6272e2045b"
        end # raw
      end # archive
    end
  end # should correctly tar text data

  it "should correctly tar text data and directory" do
    Dir.chdir(File.dirname(__FILE__)) do
      Archiverb::Tar.new.tap do |archive|
        archive.add("data/", :mtime => 1360125720)
        archive.add("data/heneryIV-westmoreland.txt", :mtime => 1360125714)
        archive.add("data/heneryIV.txt", :mtime => 1360125720)
        archive.count.should == 3
        archive.files.should_not be_empty
        archive.names == ['data/heneryIV-westmoreland.txt', 'data/heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "06b6734045acbfb54dd7160518b6807e"
        end # raw
      end # archive
    end
  end # should correctly tar text data and directory

  it "should add non-existent directories" do
    Dir.chdir(File.dirname(__FILE__)) do
      Archiverb::Tar.new.tap do |archive|
        archive.add("tmp_dir/", :mtime => 1360125720)
        archive.add("tmp_dir/heneryIV-westmoreland.txt",
                    File.new("data/heneryIV-westmoreland.txt"),
                    :mtime => 1360125714)
        archive.add("tmp_dir/heneryIV.txt",
                    File.new("data/heneryIV.txt"),
                    :mtime => 1360125720)
        archive.count.should == 3
        archive.files.should_not be_empty
        archive.names == ['data/heneryIV-westmoreland.txt', 'data/heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "9c2ab6a0f54ea19ddf3c605d42f4418a"
        end # raw
      end # archive
    end
  end

  it "should correctly tar links" do
    pending
  end # should correctly tar links
end # Archiverb::Tar
