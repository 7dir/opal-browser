module Browser; module DOM

class Node < Native
  ELEMENT_NODE                = 1
  ATTRIBUTE_NODE              = 2
  TEXT_NODE                   = 3
  CDATA_SECTION_NODE          = 4
  ENTITY_REFERENCE_NOCE       = 5
  ENTITY_NODE                 = 6
  PROCESSING_INSTRUCTION_NODE = 7
  COMMENT_NODE                = 8
  DOCUMENT_NODE               = 9
  DOCUMENT_TYPE_NODE          = 10
  DOCUMENT_FRAGMENT_NODE      = 11
  NOTATION_NODE               = 12

  def self.new(value = undefined)
    if value && self == Node
      @classes ||= [nil, Element, Attribute, Text, CDATA, nil, nil, nil, Comment, Document]

      if klass = @classes[`value.nodeType`]
        klass.new(value)
      else
        raise ArgumentError, 'cannot instantiate a non derived Node object'
      end
    elsif self == Node
      raise ArgumentError, 'cannot instantiate a non derived Node object'
    else
      super
    end
  end

  def ==(other)
    `#@native === #{Native.try_convert(other)}`
  end

  def <<(node)
    add_child(node)
  end

  def <=>(other)
    raise NotImplementedError
  end

  def >(selector)
    css "> #{selector}"
  end

  def add_child(node)
    if NodeSet === node
      node.each {|node|
        add_child(node)
      }
    else
      `#@native.appendChild(#{Native.try_convert(node)})`
    end
  end

  def add_next_sibling(node)
    `#@native.parentNode.insertBefore(node, #@native.nextSibling)`
  end

  def add_previous_sibling(node)
    `#@native.parentNode.insertBefore(node, #@native)`
  end

  alias after add_next_sibling

  def ancestors(expression = nil)
    return NodeSet.new(document) unless respond_to?(:parent) && parent

    parents = [parent]

    while parents.last.respond_to?(:parent)
      break unless parent = parents.last.parent

      parents << parent
    end

    return NodeSet.new(document, parents) unless expression

    root = parents.last

    NodeSet.new document, parents.select {|parent|
      root.search(selector).include?(parent)
    }
  end

  alias before add_previous_sibling

  def blank?
    raise NotImplementedError
  end

  def cdata?
    node_type == CDATA_SECTION_NODE
  end

  def child
    children.first
  end

  def children
    NodeSet.new(document, Array(`#@native.childNodes`))
  end

  def children=(node)
    raise NotImplementedError
  end

  def comment?
    node_type == COMMENT_NODE
  end

  def content
    `#@native.nodeValue`
  end

  def content=(value)
    `#@native.nodeValue = value`
  end

  def document
    DOM(`#@native.ownerDocument`)
  end

  def document?
    node_type == DOCUMENT_NODE
  end

  def elem?
    node_type == ELEMENT_NODE
  end

  alias element? elem?

  def element_children
    NodeSet.new(document, children.select { |n| n.element? })
  end

  alias elements element_children

  def first_element_child
    element_children.first
  end

  def fragment?
    node_type == DOCUMENT_FRAGMENT_NODE
  end

  def hash
    # TODO: implement this properly
  end

  def inner_html(*args)
    `#@native.innerHTML`
  end

  def inner_html=(value)
    `#@native.innerHTML = value`
  end

  alias inner_text inner_html

  def last_element_child
    element_children.last
  end

  def matches?(expression)
    ancestors.last.search(expression).include?(self)
  end

  def name
    `#@native.nodeName || nil`
  end

  def name=(value)
    `#@native.nodeName = #{value.to_s}`
  end

  def next
    DOM(`#@native.nextSibling`)
  end

  def next_element
    %x{
      var current = this.nextSibling;

      while (current && current.nodeType != Node.ELEMENT_NODE) {
        current = current.nextSibling;
      }

      return current ? #{DOM(`current`)} : nil;
    }
  end

  alias next_sibling next

  alias node_name name

  alias node_name= name=

  def node_type
    `#@native.nodeType`
  end

  def parent
    DOM(`#@native.parentNode`) if `#@native.parentNode`
  end

  def parent= (node)
    `#@native.parentNode = #{Native.try_convert(node)}`
  end

  def parse (text, options = {})
    raise NotImplementedError
  end

  def path
    raise NotImplementedError
  end

  def previous
    DOM(`#@native.previousSibling`)
  end

  alias previous= add_previous_sibling

  def previous_element
    %x{
      var current = this.previousSibling;

      while (current && current.nodeType != Node.ELEMENT_NODE) {
        current = current.previousSibling;
      }

      return current ? #{DOM(`current`)} : nil;
    }
  end

  alias previous_sibling previous

  # TODO: implement for NodeSet
  def replace(node)
    `#@native.parentNode.replaceChild(#@native, #{Native.try_convert(node)})`

    node
  end

  alias text inner_text

  def text?
    node_type == TEXT_NODE
  end

  def traverse(&block)
    raise NotImplementedError
  end

  alias type node_type
end

end; end
