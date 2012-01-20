$: << File.expand_path("../../lib/", __FILE__)
require "digest/md5"

module Archiver
  module Test
    extend self

    def md5s
      @md5s ||= {
        'batman.jpg'    => 'a123e1670f263cde3e771adfd7093daa',
        'Tsuru Kage.jp' => 'b5b2d62ac65dffcdfa5b844c5020903f',
        'heneryIV.txt'   => 'b08bb71cab467ee9824b64ca073b3a7f',
        'heneryIV-westmoreland.txt' => '214038a0abed0806489ca8d67daeaece'
      }
    end

    def data_dir
      @data_dir ||= File.expand_path("../data/", __FILE__)
    end
  end # module::Test
end # module::Archiver

RSpec::Matchers.define :unar_as do |original|
  match do |unared|
    unared.is_a?(Hash) && !unared[:raw].nil? && Digest::MD5.hexdigest(unared[:raw]) == Archiver::Test.md5s[original]
  end # unared

  failure_message_for_should do |unared|
    "expected #{unared[:name]} (#{Digest::MD5.hexdigest(unared[:raw])}) to be the same as the #{original} (#{Archiver::Test.md5s[original]})."
  end # unared

  failure_message_for_should_not do |unared|
    "expected #{unared[:name]} (#{Digest::MD5.hexdigest(unared[:raw])}) to be the different from #{original} (#{Archiver::Test.md5s[original]})."
  end # unared
end # original
