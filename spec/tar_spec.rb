require File.expand_path("../spec_helper.rb", __FILE__)

require 'archiver/tar'

describe Archiver::Tar do
  include Archiver::Test
  it "should correctly unarchive text data" do
    tar = nil
    tar = Archiver::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read
    tar.files.to_a.should_not be_empty
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")
    tar["data/henryIV.txt"].should_not be_nil
    tar["data/henryIV.txt"].stat.ftype.should == "link"
    tar["data/henryIV.txt"].stat.readlink.should == "heneryIV.txt"
  end # should correctly unarchive text data

  it "should correctly tar text data" do
    Dir.chdir(File.join(File.dirname(__FILE__), "data")) do
      Archiver::Tar.new.tap do |archive|
        archive.add("heneryIV-westmoreland.txt", :mtime => 1360125714)
        archive.add("heneryIV.txt", :mtime => 1360125720)
        archive.count.should == 2
        archive.files.should_not be_empty
        archive.names == ['heneryIV-westmoreland.txt', 'heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "9ad8fa828d8298325b336d4a6acc3fbd"
        end # raw
      end # archive
    end
  end # should correctly tar text data

  it "should correctly tar text data and directory" do
    Dir.chdir(File.dirname(__FILE__)) do
      Archiver::Tar.new.tap do |archive|
        archive.add("data/", :mtime => 1360125720)
        archive.add("data/heneryIV-westmoreland.txt", :mtime => 1360125714)
        archive.add("data/heneryIV.txt", :mtime => 1360125720)
        archive.count.should == 3
        archive.files.should_not be_empty
        archive.names == ['data/heneryIV-westmoreland.txt', 'data/heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "28c5865a733a1d21054aeb94b293a32a"
        end # raw
      end # archive
    end
  end # should correctly tar text data and directory

  it "should add non-existent directories" do
    Dir.chdir(File.dirname(__FILE__)) do
      Archiver::Tar.new.tap do |archive|
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
          Digest::MD5.hexdigest(raw).should == "e5db8963e9fd2b98af05e9015ce7e660"
        end # raw
      end # archive
    end
  end

  it "should correctly tar links" do
    pending
  end # should correctly tar links
end # Archiver::Tar
