require File.expand_path("../spec_helper.rb", __FILE__)

require "archiverb/ar"
require "archiverb/tar"

# @todo move all of these into shared behavior for implementing classes
describe Archiverb do
  describe "#new" do
    it "should support reading from the filesystem"
    it "should support reading from an open File"
    it "should support reading from a pipe"
    it "should support reading from a yielded pipe"
    it "should support reading from a StringIO"

    describe "when given a list of" do
      describe "files names" do
        it "should create an archive of those files"
      end
      describe "Files" do
        it "should create an archive of those Files"
      end
      describe "Files and file names" do
        it "should create an archive of those Files"
      end
    end # when given a list of
  end # #new

  describe "#write" do
    it "should support yielding contents to a block"
    it "should support writing to a pipe"
    it "should support writing to a File object"
    it "should support writing to the file system"
  end # #write

  describe "#add" do
    let(:filepath) { ::File.expand_path("../data/heneryIV.txt", __FILE__) }
    let(:contents) { IO.read(::File.expand_path("../data/heneryIV.txt", __FILE__)) }
    let(:archive) { Archiverb::Ar.new }

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

    it "should support adding files from a StringIO object" do
      archive[filepath].should be_nil
      data = StringIO.new(IO.read(filepath))
      archive.add(filepath, data)
      archive[filepath].should_not be_nil
      archive.write { |raw| raw.should include(contents) }
    end # should support adding files from a StringIO object

    it "should support adding files from a String object" do
      archive[filepath].should be_nil
      contents = IO.read(filepath)
      archive.add(filepath, contents)
      archive[filepath].should_not be_nil
      archive.write { |raw| raw.should include(contents) }
    end # should support adding files from a String object

    it "should support streaming add via yielded pipe" do
      archive[filepath].should be_nil
      archive.add('henryIV.txt') { |io| io.write(contents) }
      archive['henryIV.txt'].should_not be_nil
      archive.write { |raw| raw.should include(contents) }
    end # should support streaming add via yielded pipe
  end # #add
end # description
