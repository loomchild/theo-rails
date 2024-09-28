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
    context 'self-closing partial' do
      include_examples 'theo to erb', 'evaluates simple partial',
                       %(<_partial />),
                       %(<%= render partial: 'partial' %>)

      include_examples 'theo to erb', 'evaluates partial with attributes',
                       %(<_partial attr1="value1" attr2="value2"/>),
                       %(<%= render partial: 'partial', locals: {'attr1': 'value1', 'attr2': 'value2'} %>)

      include_examples 'theo to erb', 'evaluates partial with dynamic attribute',
                       %(<_partial attr1%="1 + 1"/>),
                       %(<%= render partial: 'partial', locals: {'attr1': 1 + 1} %>)
    end

    context 'partial with content block' do
      include_examples 'theo to erb', 'evaluates simple partial',
                       %(<_partial>Content <span>text</span></_partial>),
                       %(<%= render 'partial' do %>Content <span>text</span><% end %>)

      include_examples 'theo to erb', 'evaluates partial with attributes',
                       %(<_partial attr1="value1" attr2="value2">Content <span>text</span></_partial>),
                       %(<%= render 'partial', {'attr1': 'value1', 'attr2': 'value2'} do %>Content <span>text</span><% end %>)

      include_examples 'theo to erb', 'evaluates partial with dynamic attribute',
                       %(<_partial attr1%="1 + 1">Content <span>text</span></_partial>),
                       %(<%= render 'partial', {'attr1': 1 + 1} do %>Content <span>text</span><% end %>)

      include_examples 'theo to erb', 'evaluates partial with multiline content',
                       %(<_partial>
                          Content
                          <span>text</span>
                        </_partial>),
                       %(<%= render 'partial' do %>
                          Content
                          <span>text</span>
                        <% end %>)

      include_examples 'theo to erb', 'evaluates partial with yields attribute',
                       %(<_partial yields="item">Content</_partial>),
                       %(<%= render 'partial' do |item| %>Content<% end %>)
    end

    context 'partial collection' do
      include_examples 'theo to erb', 'evaluates partial collection',
                       %(<_partial collection="items" />),
                       %(<%= render partial: 'partial', collection: 'items' %>)

      include_examples 'theo to erb', 'evaluates partial collection with custom variable',
                       %(<_partial collection="items" as="element" />),
                       %(<%= render partial: 'partial', collection: 'items', as: 'element' %>)
    end

    context 'partial boolean attribute' do
      include_examples 'theo to erb', 'evaluates partial',
                       %(<_partial attr/>),
                       %(<%= render partial: 'partial', locals: {'attr': ''} %>)
    end

    context 'partial from a custom path' do
      include_examples 'theo to erb', 'evaluates partial',
                       %(<_partial path="partials" />),
                       %(<%= render partial: 'partials/partial' %>)
    end
  end

  context 'erb compatibility' do
    include_examples 'theo to erb', 'allows mixing Theo with ERB',
                     %(<% if value > 100 %>
                         <_partial />
                      <% end %>),
                     %(<% if value > 100 %>
                         <%= render partial: 'partial' %>
                      <% end %>)
  end
end
