$: << File.expand_path("../../lib/", __FILE__)
require "digest/md5"

class Archiverb
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
      @data_dir ||= ::File.expand_path("../data/", __FILE__)
    end
  end # module::Test
end # class::Archiverb

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end

RSpec::Matchers.define :unar_as do |original|
  match do |unared|
    !unared.nil? && !unared.read.nil? && Digest::MD5.hexdigest(unared.read) == Archiverb::Test.md5s[original]
  end # unared

  failure_message_when_negated do |unared|
    "expected #{unared.name} (#{Digest::MD5.hexdigest(unared.read)}) to be the same as the #{original} (#{Archiverb::Test.md5s[original]})."
  end # unared

  failure_message_when_negated do |unared|
    "expected #{unared.name} (#{Digest::MD5.hexdigest(unared.read)}) to be the different from #{original} (#{Archiverb::Test.md5s[original]})."
  end # unared
end # original

RSpec::Matchers.define :untar_as do |original|
  match do |untared|
    !untared.nil? && !untared.read.nil? && Digest::MD5.hexdigest(untared.read) == Archiverb::Test.md5s[original]
  end # unared

  failure_message do |untared|
    "expected #{untared.name} (#{Digest::MD5.hexdigest(untared.read)}) to be the same as the #{original} (#{Archiverb::Test.md5s[original]})."
  end # unared

  failure_message_when_negated do |untared|
    "expected #{untared.name} (#{Digest::MD5.hexdigest(untared.read)}) to be the different from #{original} (#{Archiverb::Test.md5s[original]})."
  end # unared
end # original
