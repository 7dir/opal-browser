require 'promise'

require 'browser/compatibility/immediate'

module Browser

# FIXME: drop the method_defined? checks when require order is fixed
class Immediate
  def initialize(func, args, &block)
    @aborted   = false
    @function  = func
    @arguments = args
    @block     = block
  end

  def dispatch
    raise NotImplementedError
  end unless method_defined? :dispatch

  def prevent
    raise NotImplementedError
  end unless method_defined? :prevent

  def abort
    return if aborted?

    @aborted = true
    prevent

    self
  end

  def aborted?
    @aborted
  end
end

end

class Proc
  # Defer the function to be called as soon as possible.
  def defer(*args, &block)
    Browser::Immediate.new(self, args, &block).tap(&:dispatch)
  end
end

class Promise
  def self.defer(*args, &block)
    new.tap {|promise|
      proc {
        begin
          promise.resolve(block.call(*args))
        rescue Exception => e
          promise.reject(e)
        end
      }.defer
    }
  end
end
