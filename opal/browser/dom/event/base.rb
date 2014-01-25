module Browser; module DOM

class Event
  include Native

  class Definition
    include Native

    def self.new(&block)
      data = super(`{ bubbles: true, cancelable: true }`)
      block.call(data) if block

      data.to_n
    end

    def bubbles=(value)
      `#@native.bubbles = #{value}`
    end

    def cancelable=(value)
      `#@native.cancelable = #{value}`
    end
  end

  module Target
    def self.converters
      @converters ||= []
    end

    def self.register(&block)
      converters << block
    end

    def self.convert(value)
      return value unless native?(value)

      converters.each {|block|
        if result = block.call(value)
          return result
        end
      }

      nil
    end

    def self.included(klass)
      klass.instance_eval {
        def self.target(&block)
          DOM::Event::Target.register(&block)
        end
      }
    end

    class Callback
      attr_reader :target, :name, :selector

      def initialize(target, name, selector = nil, &block)
        %x{
          #@function = function(event) {
            event = #{::Browser::DOM::Event.new(`event`, `this`, `self`)};

            if (!#{`event`.stopped?}) {
              #{block.call(`event`, *`event`.arguments)};
            }

            return !#{`event`.stopped?};
          }
        }

        @target   = target
        @name     = name
        @selector = selector
      end

      def event
        Event.class_for(@name)
      end

      def off
        target.off(self)
      end

      def to_n
        @function
      end
    end

    class Delegate
      def initialize(target, name, pair)
        @target = target
        @name   = name
        @pair   = pair
      end

      def off
        delegate = @target.delegated[@name]
        delegate.last.delete(@pair)

        if delegate.last.empty?
          delegate.first.off
          delegate.delete(@name)
        end
      end
    end

    Delegates = Struct.new(:callback, :handlers)

    def on(name, selector = nil, &block)
      raise ArgumentError, 'no block has been given' unless block

      name = Event.name_for(name)

      if selector
        unless delegate = delegated[name]
          delegate = delegated[name] = Delegates.new

          if %w[blur focus].include?(name)
            delegate.callback = on! name do |e|
              delegate(delegate, e)
            end
          else
            delegate.callback = on name do |e|
              delegate(delegate, e)
            end
          end

          pair = [selector, block]
          delegate.handlers = [pair]

          Delegate.new(self, name, pair)
        else
          pair = [selector, block]
          delegate.handlers << pair

          Delegate.new(self, name, pair)
        end
      else
        callback = Callback.new(self, name, selector, &block)
        callbacks.push(callback)

        attach(callback)
      end
    end

    def on!(name, &block)
      raise ArgumentError, 'no block has been given' unless block

      name = Event.name_for(name)
      callback = Callback.new(self, name, selector, &block)
      callbacks.push(callback)

      attach!(callback)
    end

    if Browser.supports? 'Event.addListener'
      def attach(callback)
        `#@native.addEventListener(#{callback.name}, #{callback.to_n})`

        callback
      end

      def attach!(callback)
        `#@native.addEventListener(#{callback.name}, #{callback.to_n}, true)`

        callback
      end
    elsif Browser.supports? 'Event.attach'
      def attach(callback)
        if callback.event == Custom
        else
          `#@native.attachEvent("on" + #{callback.name}, #{callback.to_n})`
        end

        callback
      end

      def attach!(callback)
        case callback.name
        when :blur
          `#@native.attachEvent("onfocusout", #{callback.to_n})`

        when :focus
          `#@native.attachEvent("onfocusin", #{callback.to_n})`

        else
          warn "attach: capture doesn't work on this browser"
          attach(callback)
        end

        callback
      end
    else
      # @todo implement polyfill
      def attach(*)
        raise NotImplementedError
      end

      # @todo implement polyfill
      def attach!(*)
        raise NotImplementedError
      end
    end

    def off(what = nil)
      case what
      when Callback
        callbacks.delete(what)
        detach(what)

      when String
        if what.include?(?*) or what.include?(??)
          off(Regexp.new(what.gsub(/\*/, '.*?').gsub(/\?/, ?.)))
        else
          what = Event.name_for(what)

          callbacks.delete_if {|callback|
            if callback.name == what
              detach(callback)

              true
            end
          }
        end

      when Regexp
        callbacks.delete_if {|callback|
          if callback.name =~ what
            detach(callback)

            true
          end
        }

      else
        callbacks.each {|callback|
          detach(callback)
        }

        callbacks.clear
      end
    end

    if Browser.supports? 'Event.removeListener'
      def detach(callback)
        `#@native.removeEventListener(#{callback.name}, #{callback.to_n}, false)`
      end
    elsif Browser.supports? 'Event.detach'
      def detach(callback)
        `#@native.detachEvent("on" + #{callback.name}, #{callback.to_n})`
      end
    else
      # @todo implement internal handler thing
      def detach(callback)
        raise NotImplementedError
      end
    end

    def trigger(event, *args, &block)
      if event.is_a? String
        event = Event.create(event, *args, &block)
      end

      dispatch(event)
    end

    # Trigger the event without bubbling.
    def trigger!(event, *args, &block)
      trigger event, *args do |e|
        block.call(e) if block
        e.bubbles = false
      end
    end

    if Browser.supports? 'Event.dispatch'
      def dispatch(event)
        `#@native.dispatchEvent(#{event.to_n})`
      end
    elsif Browser.supports? 'Event.fire'
      def dispatch(event)
        if Custom === event
          `#@native.fireEvent("ondataavailable", #{event.to_n})`
        else
          `#@native.fireEvent("on" + #{event.name}, #{event.to_n})`
        end
      end
    else
      # @todo implement polyfill
      def dispatch(*)
        raise NotImplementedError
      end
    end

  private
    def callbacks
      %x{
        if (!#@native.$callbacks) {
          #@native.$callbacks = [];
        }

        return #@native.$callbacks;
      }
    end

    def delegated
      %x{
        if (!#@native.$delegated) {
          #@native.$delegated = #{{}};
        }

        return #@native.$delegated;
      }
    end

    def delegate(delegates, event, element = event.target)
      return if element.nil? || element == event.element

      delegates.handlers.each {|selector, block|
        if element.matches? selector
          new         = event.dup
          new.element = element

          block.call new, *new.arguments
        end
      }

      delegate(delegates, event, element.parent)
    end
  end
end

end; end
