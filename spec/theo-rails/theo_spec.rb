require 'spec_helper'

RSpec.shared_examples 'theo to erb' do |name, input, output|
  let(:theo) { Theo::Rails::Theo.new }

  it "translates Theo to ERB: #{name}" do
    expect(theo.process(input)).to eq output
  end
end

RSpec.describe Theo::Rails::Theo do
  context 'dynamic attribute' do
    include_examples 'theo to erb', 'leaves normal attributes unchanged',
                     %(<a href="/even">Link</a>),
                     %(<a href="/even">Link</a>)

    include_examples 'theo to erb', 'evaluates dynamic attribute',
                     %(<a href%="2 % 2 == 0 ? '/even' : '/odd'">Link</a>),
                     %(<a href="<%= 2 % 2 == 0 ? '/even' : '/odd' %>">Link</a>)
  end

  context 'partial' do
    include_examples 'theo to erb', 'evaluates simple self-closing partial',
                     %(<_partial />),
                     %(<%= render partial: 'partial', locals: {} %>)

    include_examples 'theo to erb', 'evaluates self-closing partial with attributes',
                     %(<_partial attr1="value1" attr2="value2"/>),
                     %(<%= render partial: 'partial', locals: {'attr1': 'value1', 'attr2': 'value2'} %>)

    include_examples 'theo to erb', 'evaluates self-closing partial with dynamic attribute',
                     %(<_partial attr1%="1 + 1"/>),
                     %(<%= render partial: 'partial', locals: {'attr1': 1 + 1} %>)
  end
end
