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
    Dir.chdir(File.dirname(__FILE__)) do
      Archiver::Tar.new.tap do |archive|
        archive.add("data/heneryIV.txt")
        archive.add("data/heneryIV-westmoreland.txt")
        archive.add("data/henryIV.txt")
        archive.count.should == 3
        archive.files.should_not be_empty
        archive.names == ['data/heneryIV.txt', 'data/heneryIV-westmoreland.txt', 'data/henryIV.txt']
        archive.write do |raw|
          #Digest::MD5.hexdigest(raw).should == "428500d94224b52844b0499af60da8d4"
        end # raw
      end # archive
    end
  end # should correctly tar text data

  it "should correctly tar links" do
    pending
  end # should correctly tar links
end # Archiver::Tar
