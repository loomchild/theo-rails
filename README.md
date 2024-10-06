[![Gem Version](https://badge.fury.io/rb/theo-rails.svg)](https://badge.fury.io/rb/theo-rails)

# Theo
Theo is a small and elegant HTML-like template language for Ruby on Rails, featuring natural partials and computed attributes.

> [!WARNING]
> Please note that this software is still experimental - use at your own risk.


## Introduction

Thanks to Hotwire, it's now possible to build sophisticated server-rendered user interfaces in Ruby on Rails. However, ERB, Rails' most popular template language, has unintuitive partial syntax, especially for those used to working with Vue.js or React components.

With Theo, you can render a partial using HTML-like syntax:
```html
<_button size="large" label%="label" />
```


## Installation

Run

    gem install theo-rails

If you are using TailwindCSS, add `.theo` extension to the `content` key in your `tailwind.config.js`:

    './app/views/**/*.{erb,haml,html,slim,theo}'


## Syntax


### Computed attributes

Computing attribute value in ERB feels awkward because angle brackets `<>` clash with the surrounding HTML tag.

In Theo, an attribute with computed value can be expressed using `%=`. For example:
```html
<a href%="root_path">Home</a>
```
is equivalent to:
```erb
<a href="<%= root_path %>">Home</a>
```
> [!TIP]  
> Computed attributes work with partials as well as standard HTML tags.

#### Short form

If value of a dynamic attribute is the same as its name, you can omit the value.

For example
```html
<div style%>Text</div>
```
is equivalent to:
```erb
<div style%="style">Text</div>
```
which in turn is equivalent to:
```erb
<div style="<%= style %>">Text</div>
```

Since `class` is a Ruby keyword, it's treated specially:
```html
<div class%>Text</div>
```
is equivalent to:
```erb
<div class="<%= binding.local_variable_get('class') %>">Text</div>
```

> [!TIP]
> Short form is especially useful when you want to apply a `class` and `style` attribute to a partial root.

### Partials

Rendering a partial in ERB requires switching between HTML markup and Ruby code, and the `render` verb makes it difficult to imagine a page as a component structure.

In Theo, you render a partial by writing a tag with `_` prefix, for example:
```html
<_button size="large" />`
```
is equivalent to:
```erb
<%= render 'button', size: 'large' %>
```

Naturally, partials can also include content, e.g.:
```html
<_button size="large">
  Create
</_button>
```

> [!TIP]
> Rendered partials can be implemented in ERB, Theo or any other template language.


#### Collections

You can render a collection of partials as follows:
```html
<_widget collection="widgets" />
```
which is equivalent to:
```erb
<%= render partial: 'widget', collection: widgets %>
```

You can also customize the local variable name via the `as` attribute, e.g.:
```html
<_widget collection="widgets" as="item" />
```

#### Boolean attributes

If an attribute has no value, you can omit it, for example:
```html
<_button disabled />
```
is equivalent to:
```html
<_button disabled="" />
```


#### Path

To render a partial from another folder, use the 'path' attribute, e.g.:
```html
<_widget path="widgets" />
```
is equivalent to:
```erb
<%= render 'widgets/widget' %>
```


#### `yields` attribute

Partials can yield a value, such as a builder object that can be used by child partials. For example:
```html
<_widget_builder yields="widget">
  <_widget_element widget%="widget" />
</_widget_builder>
```
is equivalent to:
```erb
<%= render 'widget_builder' do |widget| %>
  <%= render 'widget_element', widget: %>
<% end %>
```

#### `provide` and `inject` helpers

Instead of using `yields` attribute, a parent partial can indirectly pass a variable to its children using the `provide` and `inject` helpers. The example above can be modified as follows:
```html
<_widget_builder>
  <_widget_element />
</_widget_builder>
```

`_widget_builder.html.theo`:
```erb
<% provide(widget:) do %>
  <%= yield %>
<% end %>
```

`_widget_element.html.theo`:
```erb
<% widget = inject(:widget) %>
```

> [!NOTE]
> This technique is used by [form partials](#form-partials). Use it sparingly, as implicit variables can reduce code readability. 


### ERB backwards compatibility

You can freely mix ERB and Theo syntax, e.g.:
```erb
<% if total_amount > 100 %>
  <_free_shipping amount%="total_amount" />
<% end %>
```


## Forms

You can build a `<form>` element in ERB using [ActionView form helpers](https://guides.rubyonrails.org/form_helpers.html). Theo provides corresponding partials. For example:
```html
<_form_with model%="widget" data-turbo-confirm="Are you sure?">
  <div>
    <_label name="name" />
    <_text_field name="name" />
  </div>

  <div>
    <_label name="size" />
    <_select name="size" options%="['Big', 'Small']" />
  </div>

  <_submit value="Create" />
</_form_with>
```
is equivalent to:
```erb
<%= form_with model: widget, data: { turbo_confirm: 'Are you sure?' } do |form| %>
  <div>
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <div>
    <%= form.label :size %>
    <%= form.select :size, ['Big', 'Small'] %>
  </div>

  <%= form.submit "Create" %>
<% end %>
```

## ViewComponents

Theo is compatible with [ViewComponent](https://viewcomponent.org/) framework.

Here's a component using Theo template syntax:

```
class ButtonComponent < ViewComponent::Base
  theo_template <<-THEO
    <span class%="@size"><%= content %></span>
  THEO

  def initialize(size:)
    @size = size
  end
end
```

Component can be rendered from Theo template using the following syntax:
```html
<Button size="large" />
```
which is equivalent to:
```erb
<%= render(ButtonComponent.new(size: "large")) %>
```

Components can also include content:
```html
<Button size="large">
  Create
</Button>
```
and yield a value:
```
<Button size="large" yields="component">
  <% component.with_header do %>Icon<% end %>
  Create
</Button>
```

You can also render a component collection as follows:
```html
<Widget collection="widgets" />
```
which is equivalent to:
```erb
<%= render WidgetComponent.with_collection(widgets) %>
```
