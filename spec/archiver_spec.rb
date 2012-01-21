require File.expand_path("../spec_helper.rb", __FILE__)

require "archiver/ar"
require "archiver/tar"

# @todo move all of these into shared behavior for implementing classes
describe Archiver do
  describe "#new" do
    it "should support reading from the filesystem" do
      pending
    end # should support reading from the filesystem
    it "should support reading from an open File" do
      pending
    end # should support reading from an open File
    it "should support reading from a pipe" do
      pending
    end # should support reading from a pipe
    it "should support reading from a yielded pipe" do
      pending
    end # should support reading from a yielded pipe
    it "should support reading from a StringIO" do
      pending
    end # should support reading from a StringIO
  end # #new

  describe "#write" do
    it "should support yielding contents to a block" do
      pending
    end # should support yielding contents to a block
    it "should support writing to a pipe" do
      pending
    end # should support writing to a pipe
    it "should support writing to a File object" do
      pending
    end # should support writing to a File object
    it "should support writing to the file system" do
      pending
    end # should support writing to the file system
  end # #write

  describe "#add" do
    let(:filepath) { ::File.expand_path("../data/heneryIV.txt", __FILE__) }
    let(:contents) { IO.read(::File.expand_path("../data/heneryIV.txt", __FILE__)) }
    let(:archive) { Archiver::Ar.new }

    it "should support adding files from the file system" do
      archive[filepath].should be_nil
      archive.add(filepath)
      archive[filepath].should_not be_nil
      archive.write { |raw| raw.should include(contents) }
    end # should support adding files from the file system

    it "should support adding files from a pipe" do
      archive[filepath].should be_nil
      r, w = IO.pipe
      w.write(contents)
      w.close
      archive.add(r, :name => filepath)
      archive[filepath].should_not be_nil
      archive.write { |raw| raw.should include(contents) }
      r.should be_closed
    end # should support adding files from a pipe

    it "should support adding files from a File object" do
      archive[filepath].should be_nil
      archive.add(File.open(filepath))
      archive[filepath].should_not be_nil
      archive.write { |raw| raw.should include(contents) }
    end # should support adding files from a File object

    it "should support streaming add via yielded pipe" do
      archive[filepath].should be_nil
      archive.add('henryIV.txt') { |io| io.write(contents) }
      archive['henryIV.txt'].should_not be_nil
      archive.write { |raw| raw.should include(contents) }
    end # should support streaming add via yielded pipe
  end # #add
end # description
