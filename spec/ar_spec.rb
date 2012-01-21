require File.expand_path("../spec_helper.rb", __FILE__)

require "archiver/ar"

describe Archiver::Ar do
  include Archiver::Test
  it "should correctly unarchive text data" do
    ar = nil
    ar = Archiver::Ar.new(::File.join(data_dir, 'txt.ar')).read
    ar.files.to_a.should_not be_empty
    ["heneryIV.txt", "heneryIV-westmoreland.txt"].each do |name|
      ar[name].should_not be_nil
      ar[name].should unar_as(name)
    end # name
  end # should correctly unarchive

  it "should correctly unarchive binary data" do
    ar = Archiver::Ar.new(::File.join(data_dir, 'bin.ar')).read
    ar.files.to_a.should_not be_empty
    ar.files.map(&:name).should == ['batman.jpg', 'Tsuru Kage.jp']
    ar['batman.jpg'].should_not be_nil
    ar['batman.jpg'].should unar_as('batman.jpg')
    ar['Tsuru Kage.jp'].should_not be_nil
    ar['Tsuru Kage.jp'].should unar_as('Tsuru Kage.jp')
  end # should correctly unarchive binary data

  it "should correctly ar text data" do
    Archiver::Ar.new.tap do |archive|
      archive.add(::File.expand_path("../data/heneryIV-westmoreland.txt", __FILE__))
      archive.add(::File.expand_path("../data/heneryIV.txt", __FILE__))
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
    Archiver::Ar.new.tap do |archive|
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

end # Archiver::Ar
