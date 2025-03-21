require 'spec_helper'

class WidgetComponent < ViewComponent::Base
end

class Button < ViewComponent::Base
end

class Avatar < ViewComponent::Base
end

class AvatarComponent < ViewComponent::Base
end

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

    include_examples 'theo to erb', 'evaluates shortened dynamic attribute',
                     %(<a href%>Link</a>),
                     %(<a href="<%= href %>">Link</a>)

    include_examples 'theo to erb', 'evaluates shortened reserved dynamic attribute',
                     %(<div class%>Content</div>),
                     %(<div class="<%= binding.local_variable_get('class') %>">Content</div>)

    include_examples 'theo to erb', 'merges class attribute',
                     %(<span class="red" data="dummy" class%="1 + 1">Text</span>),
                     %(<span data="dummy" class="<%= (1 + 1).to_s + ' red' %>">Text</span>)

    include_examples 'theo to erb', 'merges style attribute',
                     %(<span style="color: red" data="dummy" style%="'opacity: ' + 1/2">Text</span>),
                     %(<span data="dummy" style="<%= ('opacity: ' + 1/2).to_s + '; color: red' %>">Text</span>)

    include_examples 'theo to erb', 'ignores trim symbols',
                     %(<%- variable -%>),
                     %(<%- variable -%>)
  end

  context 'if special attribute' do
    include_examples 'theo to erb', 'surrounds tag with if conditional',
                     %(<span %if="condition">Text</span>),
                     %(<% if condition %>\n<span>Text</span>\n<% end %>)

    include_examples 'theo to erb', 'surrounds tag with if conditional and interprets dynamic attributes',
                     %(<span %if="condition" class%="cls">Text</span>),
                     %(<% if condition %>\n<span class="<%= cls %>">Text</span>\n<% end %>)

    include_examples 'theo to erb', 'surrounds void tag with if conditional',
                     %(<img %if="condition" src="one.jpg">),
                     %(<% if condition %>\n<img src="one.jpg">\n<% end %>)

    #include_examples 'theo to erb', 'surrounds tag with if conditional',
    #                 %(<span %if="condition">Text <span>nested</span></span>),
    #                 %(<% if condition %>\n<span>Text <span>nested</span></span>\n<% end %>)
  end

  context 'partial' do
    context 'self-closing partial' do
      include_examples 'theo to erb', 'evaluates simple partial',
                       %(<_partial />),
                       %(<%= render partial: 'partial' %>)

      include_examples 'theo to erb', 'evaluates multi-word partial',
                       %(<_some-partial />),
                       %(<%= render partial: 'some_partial' %>)

      include_examples 'theo to erb', 'evaluates partial with attributes',
                       %(<_partial attr1="value1" attr2="value2"/>),
                       %(<%= render partial: 'partial', locals: {'attr1': 'value1', 'attr2': 'value2'} %>)

      include_examples 'theo to erb', 'evaluates partial with dynamic attribute',
                       %(<_partial attr1%="1 + 1"/>),
                       %(<%= render partial: 'partial', locals: {'attr1': 1 + 1} %>)

      include_examples 'theo to erb', 'evaluates partial with attribute starting with funny character, like : or @',
                       %(<_partial :attr="val" @click="onClick"/>),
                       %(<%= render partial: 'partial', locals: {':attr': 'val', '@click': 'onClick'} %>)
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
                       %(<_partial %yields="item">Content</_partial>),
                       %(<%= render 'partial' do |item| %>Content<% end %>)
    end

    context 'partial collection' do
      include_examples 'theo to erb', 'evaluates partial collection',
                       %(<_partial %collection="items" />),
                       %(<%= render partial: 'partial', collection: items %>)

      include_examples 'theo to erb', 'evaluates partial collection with custom variable',
                       %(<_partial %collection="items" %as="element" />),
                       %(<%= render partial: 'partial', collection: items, as: 'element' %>)
    end

    context 'partial boolean attribute' do
      include_examples 'theo to erb', 'evaluates partial',
                       %(<_partial attr/>),
                       %(<%= render partial: 'partial', locals: {'attr': ''} %>)
    end

    context 'partial from a custom path' do
      include_examples 'theo to erb', 'evaluates partial',
                       %(<_partial %path="partials" />),
                       %(<%= render partial: 'partials/partial' %>)
    end

    context 'partial with special attribute' do
      include_examples 'theo to erb', 'surrounds partial tag with if conditional',
                       %(<_partial %if="condition">Content</_partial>),
                       %(<% if condition %>\n<%= render 'partial' do %>Content<% end %>\n<% end %>)

      include_examples 'theo to erb', 'surrounds self-closing partial tag with if conditional',
                       %(<_partial %if="condition" />),
                       %(<% if condition %>\n<%= render partial: 'partial' %>\n<% end %>)
    end
  end

  context 'component' do
    context 'self-closing component' do
      include_examples 'theo to erb', 'evaluates simple component',
                       %(<Widget />),
                       %(<%= render WidgetComponent.new() %>)

      include_examples 'theo to erb', 'evaluates component with attributes',
                       %(<Widget attr1="value1" attr2="value2"/>),
                       %(<%= render WidgetComponent.new('attr1': 'value1', 'attr2': 'value2') %>)

      include_examples 'theo to erb', 'evaluates component with dynamic attribute',
                       %(<Widget attr1%="1 + 1"/>),
                       %(<%= render WidgetComponent.new('attr1': 1 + 1) %>)
    end

    context 'component with content block' do
      include_examples 'theo to erb', 'evaluates simple component',
                       %(<Widget>Content <span>text</span></Widget>),
                       %(<%= render WidgetComponent.new() do %>Content <span>text</span><% end %>)

      include_examples 'theo to erb', 'evaluates component with attributes',
                       %(<Widget attr1="value1" attr2="value2">Content <span>text</span></Widget>),
                       %(<%= render WidgetComponent.new('attr1': 'value1', 'attr2': 'value2') do %>Content <span>text</span><% end %>)

      include_examples 'theo to erb', 'evaluates partial with yields attribute',
                       %(<Widget %yields="component">Content <span>text</span></Widget>),
                       %(<%= render WidgetComponent.new() do |component| %>Content <span>text</span><% end %>)
    end

    context 'component collection' do
      include_examples 'theo to erb', 'evaluates partial collection',
                       %(<Widget %collection="widgets" />),
                       %(<%= render WidgetComponent.with_collection(widgets) %>)

      include_examples 'theo to erb', 'evaluates partial collection with attributes',
                       %(<Widget %collection="widgets" attr1="value1" attr2="value2" />),
                       %(<%= render WidgetComponent.with_collection(widgets, 'attr1': 'value1', 'attr2': 'value2') %>)
    end

    context 'component without "Component" suffix' do
      include_examples 'theo to erb', 'evaluates simple component',
                       %(<Button />),
                       %(<%= render Button.new() %>)
    end

    context 'competing component names' do
      include_examples 'theo to erb', 'evaluates direct match',
                       %(<Avatar />),
                       %(<%= render Avatar.new() %>)

      include_examples 'theo to erb', 'evaluates direct match with "Component" suffix',
                       %(<AvatarComponent />),
                       %(<%= render AvatarComponent.new() %>)
    end
  end

  context 'erb compatibility' do
    include_examples 'theo to erb', 'allows mixing Theo with ERB',
                     %(<% if value > 100 %>
                         <Partial />
                      <% end %>),
                     %(<% if value > 100 %>
                         <%= render partial: 'partial' %>
                      <% end %>)
  end
end
