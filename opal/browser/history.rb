module Browser

class History
  include Native::Base

  alias_native :length

  def back(number = 1)
    `#@native.go(-number)`

    self
  end

  def forward(number = 1)
    `#@native.go(number)`

    self
  end

  def push(url, data = nil)
    data = `null` if data.nil?

    `#@native.pushState(data, null, url)`

    self
  end

  def replace(url, data = nil)
    data = `null` if data.nil?

    `#@native.replaceState(data, null, url)`
  end

  def current
    $window.location.path
  end

  def state
    `#@native.state`
  end
end

class Window
  # Get the {History} object for this window.
  #
  # @return [History]
  def history
    History.new(`#@native.history`) if `#@native.history`
  end
end

end
