module Browser; module DOM; class Element < Node

class Position
  def initialize(element)
    @element = element
    @native  = element.to_n
  end

  def get
    offset        = @element.offset
    position      = offset.get
    parent        = offset.parent
    parent_offset = Browser::Position.new(0, 0)

    if @element.style[:position] == :fixed
      unless parent =~ :html
        parent_offset = parent.offset
      end

      parent_offset.x += parent.style['border-top-width'].to_i
      parent_offset.y += parent.style['border-left-width'].to_i
    end

    Browser::Position.new(position.x - parent_offset.x - @element.style['margin-left'].to_i,
                          position.y - parent_offset.y - @element.style['margin-top'].to_i)
  end

  def x
    get.x
  end

  def y
    get.y
  end
end

end; end; end
