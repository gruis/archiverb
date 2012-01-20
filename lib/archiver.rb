module Archiver
  module Error; end
  class StandarError < ::StandardError; include Error; end
  class InvalidFormat < StandardError; end
end
