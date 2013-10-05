require 'browser/dom/element/position'
require 'browser/dom/element/offset'
require 'browser/dom/element/scroll'

module Browser; module DOM

class Element < Node
  def self.create(*args)
    $document.create_element(*args)
  end

  include Event::Target

  target {|value|
    # FIXME: oneline rescue

    begin
      DOM(value)
    rescue
      nil
    end
  }

  alias_native :id

  def add_class(*names)
    `#@native.className = #{(class_names + names).uniq.join ' '}`

    self
  end

  def remove_class(*names)
    `#@native.className = #{(class_names - names).join ' '}`

    self
  end

  alias_native :class_name, :className

  def class_names
    `#@native.className`.split(/\s+/).reject(&:empty?)
  end

  alias attribute attr

  def attribute_nodes
    Native::Array.new(`#@native.attributes`, get: :item) { |e| DOM(e) }
  end

  def attributes(options = {})
    Attributes.new(self, options)
  end

  def get(name, options = {})
    if namespace = options[:namespace]
      `#@native.getAttributeNS(#{namespace.to_s}, #{name.to_s}) || nil`
    else
      `#@native.getAttribute(#{name.to_s}) || nil`
    end
  end

  def set(name, value, options = {})
    if namespace = options[:namespace]
      `#@native.setAttributeNS(#{namespace.to_s}, #{name.to_s}, #{value})`
    else
      `#@native.setAttribute(#{name.to_s}, #{value.to_s})`
    end
  end

  alias [] get
  alias []= set

  alias attr get
  alias attribute get

  alias get_attribute get
  alias set_attribute set

  def key?(name)
    !!self[name]
  end

  def keys
    attributes_nodesmap(&:name)
  end

  def values
    attribute_nodes.map(&:value)
  end

  def each(options = {}, &block)
    return enum_for :each, options unless block

    attributes(options).each(&block)
  end

  def remove_attribute(name)
    `#@native.removeAttribute(name)`
  end

  def size(*inc)
    Size.new(`#@native.offsetWidth`, `#@native.offsetHeight`)
  end

  def position
    Position.new(self)
  end

  def offset(*values)
    off = Offset.new(self)

    if values
      off.set(*values)

      self
    else
      off
    end
  end

  def offset=(value)
    offset.set(*value)
  end

  def scroll
    Scroll.new(self)
  end

  def scroll(to = nil)
    if to
      if x = to[:x]
        `#@native.scrollLeft = #{x}`
      end

      if y = to[:y]
        `#@native.scrollTop = #{y}`
      end
    else
      Position.new(`#@native.scrollLeft`, `#@native.scrollTop`)
    end
  end

  def /(*paths)
    paths.map { |path| xpath(path) }.flatten.uniq
  end

  def at(path)
    xpath(path).first || css(path).first
  end

  def at_css(*rules)
    rules.each {|rule|
      found = css(rule).first

      return found if found
    }

    nil
  end

  def at_xpath(*paths)
    paths.each {|path|
      found = xpath(path).first

      return found if found
    }

    nil
  end

  def search(*selectors)
    NodeSet.new document, selectors.map {|selector|
      xpath(selector).to_a.concat(css(selector).to_a)
    }.flatten.uniq
  end

  def css(path)
    NodeSet.new(document, Native::Array.new(`#@native.querySelectorAll(path)`))
  end

  def xpath(path)
    result = []

    begin
      %x{
        var tmp = (#@native.ownerDocument || #@native).evaluate(
          path, #@native, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);

        result = #{Native::Array.new(`tmp`, get: :snapshotItem, length: :snapshotLength)};
      }
    rescue; end

    NodeSet.new(document, result)
  end

  def style(data = nil, &block)
    style = CSS::Declaration.new(`#@native.style`)

    return style unless data || block

    if data.is_a?(String)
      style.replace(data)
    elsif data.is_a?(Enumerable)
      style.assign(data)
    end

    if block
      style.apply(&block)
    end

    self
  end

  def style!
    CSS::Declaration.new(`#{window.to_n}.getComputedStyle(#@native, null)`)
  end

  def matches?(selector)
    `#@native.matches(#{selector})`
  end

  def window
    document.window
  end

  def inspect
    "#<DOM::Element: #{name}>"
  end

  class Attributes
    include Enumerable

    attr_reader :namespace

    def initialize(element, options)
      @element   = element
      @namespace = options[:namespace]
    end

    def each(&block)
      return enum_for :each unless block_given?

      @element.attribute_nodes.each {|attr|
        yield attr.name, attr.value
      }

      self
    end

    def [](name)
      @element.get_attribute(name, namespace: @namespace)
    end

    def []=(name, value)
      @element.set_attribute(name, value, namespace: @namespace)
    end

    def merge!(hash)
      hash.each {|name, value|
        self[name] = value
      }

      self
    end
  end
end

end; end
