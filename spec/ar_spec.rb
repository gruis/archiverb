require File.expand_path("../spec_helper.rb", __FILE__)

require "archiverb/ar"

describe Archiverb::Ar do
  include Archiverb::Test
  it "should correctly unarchive text data" do
    ar = nil
    ar = Archiverb::Ar.new(::File.join(data_dir, 'txt.ar')).read
    ar.files.to_a.should_not be_empty
    ["heneryIV.txt", "heneryIV-westmoreland.txt"].each do |name|
      ar[name].should_not be_nil
      ar[name].should unar_as(name)
    end # name
  end # should correctly unarchive

  it "should correctly unarchive text data with glob filter" do
    ["heneryIV.txt", "heneryIV-westmoreland.txt"].each do |name|
      ar = Archiverb::Ar.new(::File.join(data_dir, 'txt.ar')).read(:filter => name.sub(/txt$/,"*"))
      ar.files.size.should == 1
      ar[name].should_not be_nil
      ar[name].should unar_as(name)
    end
  end

  it "should correctly unarchive text data with glob filter and limit" do
    name = "heneryIV-westmoreland.txt"
    ar = Archiverb::Ar.new(::File.join(data_dir, 'txt.ar')).read(:filter => "*.txt", :limit => 1)
    ar.files.size.should == 1
    ar[name].should_not be_nil
    ar[name].should unar_as(name)
  end

  it "should correctly unarchive text data with regexp filter" do
    ["heneryIV.txt", "heneryIV-westmoreland.txt"].each do |name|
      ar = Archiverb::Ar.new(::File.join(data_dir, 'txt.ar')).read(:filter => Regexp.new(name.sub(/txt$/,"[tx]+")))
      ar.files.size.should == 1
      ar[name].should_not be_nil
      ar[name].should unar_as(name)
    end
  end

  it "should correctly unarchive text data with regexp filter and limit" do
    name = "heneryIV-westmoreland.txt"
    ar = Archiverb::Ar.new(::File.join(data_dir, 'txt.ar')).read(:filter => /\.txt$/, :limit => 1)
    ar.files.size.should == 1
    ar[name].should_not be_nil
    ar[name].should unar_as(name)
  end

  it "should correctly unarchive binary data" do
    ar = Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read
    ar.files.to_a.should_not be_empty
    ar.files.map(&:name).should == ['batman.jpg', 'Tsuru Kage.jp']
    ar['batman.jpg'].should_not be_nil
    ar['batman.jpg'].should unar_as('batman.jpg')
    ar['Tsuru Kage.jp'].should_not be_nil
    ar['Tsuru Kage.jp'].should unar_as('Tsuru Kage.jp')
  end # should correctly unarchive binary data

  it "should correctly unarchive binary data with glob filter" do
    ["batman.jpg", "Tsuru Kage.jp"].each do |name|
      ar = Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read(:filter => name.sub(/jpg?$/,"*"))
      ar.files.size.should == 1
      ar[name].should_not be_nil
      ar[name].should unar_as(name)
    end
    ar = Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read(:filter => "foo")
    ar.files.size.should == 0
  end

  it "should correctly unarchive binary data with glob filter and limit" do
    name = "batman.jpg"
    ar = Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read(:filter => "*.jp*", :limit => 1)
    ar.files.size.should == 1
    ar[name].should_not be_nil
    ar[name].should unar_as(name)
  end

  it "should correctly unarchive binary data with regexp filter" do
    ["batman.jpg", "Tsuru Kage.jp"].each do |name|
      ar = Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read(:filter => Regexp.new(name.sub(/jpg?$/,"+")))
      ar.files.size.should == 1
      ar[name].should_not be_nil
      ar[name].should unar_as(name)
    end
    ar = Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read(:filter => /foo/)
    ar.files.size.should == 0
  end

  it "should correctly unarchive binary data with regexp filter and limit" do
    name = "batman.jpg"
    ar = Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read(:filter => /\.jp/, :limit => 1)
    ar.files.size.should == 1
    ar[name].should_not be_nil
    ar[name].should unar_as(name)
  end

  it "should raise error on unsupported filter" do
    filter = 123
    lambda {
      Archiverb::Ar.new(::File.join(data_dir, 'bin.ar')).read(:filter => filter)
    }.should raise_error(ArgumentError, "unsupported filter type: #{filter.class}")
  end

  it "should correctly ar text data" do
    Archiverb::Ar.new.tap do |archive|
      archive.add(::File.expand_path("../data/heneryIV-westmoreland.txt", __FILE__), :mtime => 1327073962)
      archive.add(::File.expand_path("../data/heneryIV.txt", __FILE__), :mtime => 1327110498)
      archive.count.should == 2
      archive.files.should_not be_empty
      archive.files.map(&:name).should == ['heneryIV-westmoreland.txt', 'heneryIV.txt']
      archive.write do |raw|
        Digest::MD5.hexdigest(raw).should == "428500d94224b52844b0499af60da8d4"
      end # raw
    end # archive
  end # should correctly ar text data

  it "should correctly ar binary data" do
    pending "the filename for Tsuru Kage.jp in the orignal is stored as an extended file name"
    Archiverb::Ar.new.tap do |archive|
      ['batman.jpg', 'Tsuru Kage.jp'].each do |file|
        archive.add(File.expand_path("../data/#{file}", __FILE__))
      end # file
      archive.count.should == 2
      archive.files.to_a.should_not be_empty
      archive.names.should == ['batman.jpg', 'Tsuru Kage.jp']
      archive.write do |raw|
        Digest::MD5.hexdigest(raw).should == "82c9ac68eb07f256bbaf52244d73e522"
      end
    end # archive
  end # should correctly ar binary data

  it "should correctly duplicate an ar file" do
    contents = IO.read(::File.join(data_dir, 'txt.ar'))
    archive  = Archiverb::Ar.new(::File.join(data_dir, 'txt.ar')).read
    archive.write do |raw|
      raw.should == contents
    end # raw
  end # should correctly duplicate an ar file

end # Archiverb::Ar
