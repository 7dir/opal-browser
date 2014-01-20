require 'spec_helper'

describe 'Kernel' do
  describe '.DOM()' do
    html <<-HTML
      <div class="spec"></div>
      <div class="sock"></div>
    HTML

    it "parses HTML" do
      $document['.spec'].element?.should be_truthy
      $document['.sock'].element?.should be_truthy
    end
  end
end
