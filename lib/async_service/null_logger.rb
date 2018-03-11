require 'logger'


module AsyncService
  class NullLogger < Logger
    def initialize
    end

    def add(severity, message = nil, progname = nil)
    end
  end
end
