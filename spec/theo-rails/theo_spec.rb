require 'spec_helper'
require 'erubi/capture_block'

def to_erb(input)
  Theo::Rails::Theo.new.process(input)
end

class ErbContext
  def get_binding(params)
    bind = binding
    params.each { |key, value| bind.local_variable_set(key, value) }

    bind
  end

  def render(*args, **kvargs, &block)
    partial = args[0] || kvargs.delete(:partial)

    if partial.is_a?(Component)
      partial.kvargs.each { |k, v| kvargs[k] = v }
      partial = partial.class.name
    end

    args[1].each { |k, v| kvargs[k] = v } unless args.size < 2

    if kvargs.key?(:locals)
      kvargs[:locals].each { |k,v| kvargs[k] = v }
      kvargs.delete(:locals)
    end

    kvargs = kvargs.empty? ? nil : ' ' + kvargs.map { |k, v| "#{k.to_s}=\"#{v}\"" }.join(' ')

    "<div #{partial}#{kvargs}>#{@_buf.capture(&block) if block_given?}</div>"
  end
end

def to_html(input, **params)
  theo = Theo::Rails::Theo.new.process(input)

  context = ErbContext.new.get_binding(params)

  eval(Erubi::CaptureBlockEngine.new(theo, bufvar: '@_buf', trim: false).src, context).force_encoding('UTF-8')
end

class Component < ViewComponent::Base
  attr_reader :kvargs

  def initialize(**kvargs)
    @kvargs = kvargs
  end

  def self.with_collection(collection)
    new(collection:)
  end
end

class WidgetComponent < Component
end

class Button < Component
end

class Avatar < Component
end

class AvatarComponent < Component
end

RSpec.describe Theo::Rails::Theo do
  let(:theo_processor) { Theo::Rails::Theo.new }

  context 'Dynamic attributes' do
    it 'leaves normal attributes unchanged' do
      theo = %(<a href="/even">Link</a>)

      expect(to_erb(theo)).to eq %(<a href="/even">Link</a>)
      expect(to_html(theo)).to eq %(<a href="/even">Link</a>)
    end

    it 'evaluates dynamic attribute' do
      theo = %(<a href%="2 % 2 == 0 ? '/even' : '/odd'">Link</a>)

      expect(to_erb(theo)).to eq %(<a <% unless (_val = 2 % 2 == 0 ? '/even' : '/odd').nil? %>href="<%= _val %>"<% end %>>Link</a>)
      expect(to_html(theo)).to eq %(<a href="/even">Link</a>)
    end

    it 'evaluates shortened dynamic attribute' do
      theo = %(<a href%>Link</a>)

      expect(to_erb(theo)).to eq %(<a <% unless (_val = href).nil? %>href="<%= _val %>"<% end %>>Link</a>)
      expect(to_html(theo, href: '/one')).to eq %(<a href="/one">Link</a>)
    end

    it 'evaluates shortened reserved dynamic attribute' do
      theo = %(<div class%>Content</div>)

      expect(to_erb(theo)).to eq %(<div <% unless (_val = binding.local_variable_get('class')).nil? %>class="<%= _val %>"<% end %>>Content</div>)
      expect(to_html(theo, class: 'red')).to eq %(<div class="red">Content</div>)
    end

    it 'merges class attribute' do
      theo = %(<span class="red" data="dummy" class%="1 + 1">Text</span>)

      expect(to_erb(theo)).to eq %(<span data="dummy" <% unless (_val = (1 + 1).to_s + ' red').nil? %>class="<%= _val %>"<% end %>>Text</span>)
      expect(to_html(theo)).to eq %(<span data="dummy" class="2 red">Text</span>)
    end

    it 'merges style attribute' do
      theo = %(<span style="color: red" data="dummy" style%="'opacity: ' + (1.0/2).to_s">Text</span>)

      expect(to_erb(theo)).to eq %(<span data="dummy" <% unless (_val = ('opacity: ' + (1.0/2).to_s).to_s + '; color: red').nil? %>style="<%= _val %>"<% end %>>Text</span>)
      expect(to_html(theo)).to eq %(<span data="dummy" style="opacity: 0.5; color: red">Text</span>)
    end

    it 'erases dynamic attribute with nil value in normal tags' do
      theo = %(<div title%="nil">Content</div>)

      expect(to_erb(theo)).to eq %(<div <% unless (_val = nil).nil? %>title=\"<%= _val %>\"<% end %>>Content</div>)
      expect(to_html(theo)).to eq %(<div >Content</div>)
    end

    it 'ignores trim symbols' do
      theo = %(<%= variable -%>)

      expect(to_erb(theo)).to eq %(<%= variable -%>)
      expect(to_html(theo, variable: 1)).to eq %(1)
    end
  end

  context 'if special attribute' do
    it 'surrounds tag with if conditional' do
      theo = %(<span %if="condition">Text</span>)

      expect(to_erb(theo)).to eq %(<% if condition %>\n<span>Text</span>\n<% end %>)
      expect(to_html(theo, condition: true)).to eq %(\n<span>Text</span>\n)
    end

    it 'surrounds tag with if conditional and interprets dynamic attributes' do
      theo = %(<span %if="condition" class%="cls">Text</span>)

      expect(to_erb(theo)).to eq %(<% if condition %>\n<span <% unless (_val = cls).nil? %>class=\"<%= _val %>\"<% end %>>Text</span>\n<% end %>)
      expect(to_html(theo, condition: true, cls: 'red')).to eq %(\n<span class="red">Text</span>\n)
    end

    it 'surrounds void tag with if conditional' do
      theo = %(<img %if="condition" src="one.jpg">)

      expect(to_erb(theo)).to eq %(<% if condition %>\n<img src="one.jpg">\n<% end %>)
      expect(to_html(theo, condition: true)).to eq %(\n<img src="one.jpg">\n)
    end

    it 'surrounds nested tag with if conditional', skip: 'not supported' do
      theo = %(<span %if="condition">Text <span>nested</span></span>)

      expect(to_erb(theo)).to eq %(<% if condition %>\n<span>Text <span>nested</span></span>\n<% end %>)
      expect(to_html(theo, condition: true)).to eq %(\n<span>Text <span>nested</span></span>\n)
    end

  end

  context 'partial' do
    context 'self-closing partial' do
      it 'evaluates simple partial' do
        theo = %(<_partial />)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partial' %>)
        expect(to_html(theo)).to eq %(<div partial></div>)
      end

      it 'evaluates multi-word partial' do
        theo = %(<_some-partial />)

        expect(to_erb(theo)).to eq %(<%= render partial: 'some_partial' %>)
        expect(to_html(theo)).to eq %(<div some_partial></div>)
      end

      it 'evaluates partial with attributes' do
        theo = %(<_partial attr1="value1" attr2="value2"/>)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partial', locals: {'attr1': 'value1', 'attr2': 'value2'} %>)
        expect(to_html(theo)).to eq %(<div partial attr1="value1" attr2="value2"></div>)
      end

      it 'evaluates partial with dynamic attribute' do
        theo = %(<_partial attr1%="1 + 1"/>)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partial', locals: {'attr1': 1 + 1} %>)
        expect(to_html(theo)).to eq %(<div partial attr1="2"></div>)
      end

      it 'evaluates partial with attribute starting with funny character, like : or @' do
        theo = %(<_partial :attr="val" @click="onClick"/>)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partial', locals: {':attr': 'val', '@click': 'onClick'} %>)
        expect(to_html(theo)).to eq %(<div partial :attr="val" @click="onClick"></div>)
      end
    end

    context 'partial with content block' do
      it 'evaluates simple partial' do
        theo = %(<_partial>Content <span>text</span></_partial>)

        expect(to_erb(theo)).to eq %(<%= render 'partial' do %>Content <span>text</span><% end %>)
        expect(to_html(theo)).to eq %(<div partial>Content <span>text</span></div>)
      end

      it 'evaluates partial with attributes' do
        theo = %(<_partial attr1="value1" attr2="value2">Content <span>text</span></_partial>)

        expect(to_erb(theo)).to eq %(<%= render 'partial', {'attr1': 'value1', 'attr2': 'value2'} do %>Content <span>text</span><% end %>)
        expect(to_html(theo)).to eq %(<div partial attr1="value1" attr2="value2">Content <span>text</span></div>)
      end

      it 'evaluates partial with dynamic attribute' do
        theo = %(<_partial attr1%="1 + 1">Content <span>text</span></_partial>)

        expect(to_erb(theo)).to eq %(<%= render 'partial', {'attr1': 1 + 1} do %>Content <span>text</span><% end %>)
        expect(to_html(theo)).to eq %(<div partial attr1="2">Content <span>text</span></div>)
      end

      it 'evaluates partial with multiline content' do
        theo = %(<_partial>
                 Content
                 <span>text</span>
               </_partial>)
        erb  = %(<%= render 'partial' do %>
                 Content
                 <span>text</span>
               <% end %>)
        html = %(<div partial>
                 Content
                 <span>text</span>
               </div>)

        expect(to_erb(theo)).to eq erb
        expect(to_html(theo)).to eq html
      end

      it 'evaluates partial with yields attribute' do
        theo = %(<_partial %yields="item">Content</_partial>)

        expect(to_erb(theo)).to eq %(<%= render 'partial' do |item| %>Content<% end %>)
        expect(to_html(theo)).to eq %(<div partial>Content</div>)
      end
    end

    context 'partial collection' do
      it 'evaluates partial collection' do
        theo = %(<_partial %collection="items" />)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partial', collection: items %>)
        expect(to_html(theo, items: [])).to eq %(<div partial collection="[]"></div>)
      end

      it 'evaluates partial collection with custom variable' do
        theo = %(<_partial %collection="items" %as="element" />)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partial', collection: items, as: 'element' %>)
        expect(to_html(theo, items: [])).to eq %(<div partial collection="[]" as="element"></div>)
      end
    end

    context 'partial boolean attribute' do
      it 'evaluates partial' do
        theo = %(<_partial attr/>)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partial', locals: {'attr': ''} %>)
        expect(to_html(theo)).to eq %(<div partial attr=""></div>)
      end
    end

    context 'partial from a custom path' do
      it 'evaluates partial' do
        theo = %(<_partial %path="partials" />)

        expect(to_erb(theo)).to eq %(<%= render partial: 'partials/partial' %>)
        expect(to_html(theo)).to eq %(<div partials/partial></div>)
      end
    end

    context 'partial with special attribute' do
      it 'surrounds partial tag with if conditional' do
        theo = %(<_partial %path="partials" />)

        expect(to_erb(theo)).to eq %(<% if condition %>\n<%= render 'partial' do %>Content<% end %>\n<% end %>)
        expect(to_html(theo, condition: true)).to eq %(<div partial>Content</div>)
      end

      it 'surrounds self-closing partial tag with if conditional' do
        theo = %(<_partial %if="condition" />)

        expect(to_erb(theo)).to eq %(<% if condition %>\n<%= render partial: 'partial' %>\n<% end %>)
        expect(to_html(theo, condition: true)).to eq %(\n<div partial></div>\n)
      end
    end
  end

  context 'component' do
    context 'self-closing component' do
      it 'evaluates simple component' do
        theo = %(<Widget />)

        expect(to_erb(theo)).to eq %(<%= render WidgetComponent.new() %>)
        expect(to_html(theo)).to eq %(<div WidgetComponent></div>)
      end

      it 'evaluates component with attributes' do
        theo = %(<Widget attr1="value1" attr2="value2"/>)

        expect(to_erb(theo)).to eq %(<%= render WidgetComponent.new('attr1': 'value1', 'attr2': 'value2') %>)
        expect(to_html(theo)).to eq %(<div WidgetComponent attr1="value1" attr2="value2"></div>)
      end

      it 'evaluates component with dynamic attribute' do
        theo = %(<Widget attr1%="1 + 1"/>)

        expect(to_erb(theo)).to eq %(<%= render WidgetComponent.new('attr1': 1 + 1) %>)
        expect(to_html(theo)).to eq %(<div WidgetComponent attr1="2"></div>)
      end
    end

    context 'component with content block' do
      it 'evaluates simple component' do
        theo = %(<Widget>Content <span>text</span></Widget>)

        expect(to_erb(theo)).to eq %(<%= render WidgetComponent.new() do %>Content <span>text</span><% end %>)
        expect(to_html(theo)).to eq %(<div WidgetComponent>Content <span>text</span></div>)
      end

      it 'evaluates component with attributes' do
        theo = %(<Widget attr1="value1" attr2="value2">Content <span>text</span></Widget>)

        expect(to_erb(theo)).to eq %(<%= render WidgetComponent.new('attr1': 'value1', 'attr2': 'value2') do %>Content <span>text</span><% end %>)
        expect(to_html(theo)).to eq %(<div WidgetComponent attr1="value1" attr2="value2">Content <span>text</span></div>)
      end

      it 'evaluates partial with yields attribute' do
        theo = %(<Widget %yields="component">Content <span>text</span></Widget>)

        expect(to_erb(theo)).to eq %(<%= render WidgetComponent.new() do |component| %>Content <span>text</span><% end %>)
        expect(to_html(theo)).to eq %(<div WidgetComponent>Content <span>text</span></div>)
      end
    end

    context 'component collection' do
      it 'evaluates partial collection' do
        theo = %(<Widget %collection="widgets" />)

        expect(to_erb(theo)).to eq %(<%= render WidgetComponent.with_collection(widgets) %>)
        expect(to_html(theo, widgets: [])).to eq %(<div WidgetComponent collection="[]"></div>)
      end
    end

    context 'component without "Component" suffix' do
      it 'evaluates simple component' do
        theo = %(<Button />)

        expect(to_erb(theo)).to eq %(<%= render Button.new() %>)
        expect(to_html(theo)).to eq %(<div Button></div>)
      end
    end

    context 'competing component names' do
      it 'evaluates direct match' do
        theo = %(<Avatar />)

        expect(to_erb(theo)).to eq %(<%= render Avatar.new() %>)
        expect(to_html(theo)).to eq %(<div Avatar></div>)
      end

      it 'evaluates direct match with "Component" suffix' do
        theo = %(<AvatarComponent />)

        expect(to_erb(theo)).to eq %(<%= render AvatarComponent.new() %>)
        expect(to_html(theo)).to eq %(<div AvatarComponent></div>)
      end
    end
  end

  context 'erb compatibility' do
    it 'allows mixing Theo with ERB' do
      theo = %(<% if value > 100 %>
                 <Partial />
               <% end %>)
      erb  = %(<% if value > 100 %>
                 <%= render partial: 'partial' %>
               <% end %>)

      expect(to_erb(theo)).to eq erb
      expect(to_html(theo, value: 101).strip).to eq %(<div partial></div>)
    end
  end
end
