module Browser

class Screen
  include Native
  include DOM::Event::Target

  target {|value|
    Screen.new(value) if Native.is_a?(value, `window.Screen`)
  }

  alias_native :width
  alias_native :height

  def size
    Size.new(width, height)
  end

  alias_native :x, :top
  alias_native :y, :left

  def position
    Position.new(x, y)
  end

  alias_native :color_depth, :colorDepth
  alias_native :pixel_depth, :pixelDepth

  alias_native :orientation
end

class Window
  # Get the {Screen} for this window.
  #
  # @return [Screen]
  def screen
    Screen.new(`#@native.screen`)
  end
end

end
