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

> [!IMPORTANT]
> For rendering partials, you can also use PascalCase:
> ```html
> <Button size="large" label%="label" />
> ```


## Getting started

### Install

Run

    bundle add theo-rails

> [!NOTE]
> If you are using TailwindCSS version 3, add `.theo` extension to the `content` key in your `tailwind.config.js`: `./app/views/**/*.{erb,haml,html,slim,theo}`.

### Try

Create a new view named `hello.html.theo` (note the `.theo` suffix), with the following content:
```html
<span style%="'background-color: ' + 'yellow'">Hello from Theo!</span>
```

Visit the URL corresponding to this view and you should see a highlighed text.


## Syntax


### Computed attributes

Computing attribute value in ERB feels awkward because angle brackets `<>` clash with the surrounding HTML tag.

In Theo, an attribute with computed value can be expressed using `%=`. For example:
```html
<a href%="root_path">Home</a>
```
is roughly equivalent[\*](#erasing-falsy-attributes) to:
```erb
<a href="<%= root_path %>">Home</a>
```
> [!TIP]
> Computed attributes work with partials as well as standard HTML tags.

#### Short form

If value of a dynamic attribute is the same as its name, you can omit the value.

For example:
```html
<img src%>
```
is equivalent to:
```erb
<img src%="src">
```
which in turn is equivalent to:
```erb
<img src="<%= src %>">
```

#### <a id="erasing-failsy-attributes"></a>Erasing falsy attributes from HTML tags

If value of attribute is falsy (`false` or `nil`), then it will be omitted from the resulting markup. This is achieved by wrapping each attribute in a condition.

For example:
```html
<input name="login" disabled%>
```
is equivalent to:
```erb
<input name="login" <% if (_val = disabled) %>disabled="<%= _val %>"<% end %>>
```

> [!NOTE]
> It only affects attributes of standard HTML tags, falsy attributes are passed to partials as-is.


### Partials

Rendering a partial in ERB requires context-switching between HTML markup and Ruby code, and the `render` verb makes it difficult to imagine a page as a component structure.

In Theo, you render a partial by writing a tag with '_' prefix, followed by kebab-cased partial name, for example:
```html
<_special-button size="large" />
```
is equivalent to:
```erb
<%= render 'special_button', size: 'large' %>
```

> [!TIP]
> Alternatively, you can also use PascalCase, for example:
> ```html
> <SpecialButton size="large" />
> ```
> The benefit is that this form is recognized as valid HTML by most parsers.

Naturally, partials can also include content, e.g.:
```html
<_button size="large">
  Create
</_button>
```

> [!TIP]
> Rendered partials can be implemented in ERB, Theo or any other template language.

#### Boolean partial attributes

If a partial attribute has no value, you can omit it, for example:
```html
<_button disabled />
```
is equivalent to:
```html
<_button disabled="" />
```


### Special attributes

Special attributes always start with `%` and their value is always dynamic.


#### Collections

You can render a collection of partials using `%collection` special attribute:
```html
<_widget %collection="widgets" />
```
which is equivalent to:
```erb
<%= render partial: 'widget', collection: widgets %>
```

You can also customize the local variable name via the `%as` special attribute, e.g.:
```html
<_widget %collection="widgets" %as="item" />
```

#### Path

To render a partial from another folder, use the `%path` special attribute, e.g.:
```html
<_widget %path="widgets" />
```
is equivalent to:
```erb
<%= render 'widgets/widget' %>
```

#### Yields

Partials can yield a value, such as a builder object that can be used by child partials. For example:
```html
<_widget-builder %yields="widget">
  <_widget-element widget%="widget" />
</_widget-builder>
```
is equivalent to:
```erb
<%= render 'widget_builder' do |widget| %>
  <%= render 'widget_element', widget: %>
<% end %>
```

#### Conditionals

You can omit the tag conditionally using `%if` special attribute:
```
<span %if="content"><%= content %></span>
```
is equivalent to:
```erb
<% if content %>
  <span><%= content %></span>
<% end %>
```

It also works with partials, so this will skip rendering unless the condition is met:
```
<_special-button %if="count > 3" size="large" />
```

> [!NOTE]
> Conditionals can't yet be applied to nested tags (e.g. `div` inside `div`). Please use ERB conditions in such cases.


### ERB backwards compatibility

You can freely mix ERB and Theo syntax, e.g.:
```erb
<% if total_amount > 100 %>
  <_free-shipping amount%="total_amount" />
<% end %>
```

### Utilities

#### Merging `class` and `style` attributes
You can specify both static and dynamic version of `class` and `style` attribute on a tag, and they will be merged.

For example:
```html
<div class% class="big" style% style="color: red">Text</div>
```
is equivalent to:
```erb
<div class="<%= binding.local_variable_get('class').to_s + ' big' %>" style="<%= style.to_s + '; color: red' %>">Text</div>
```

This is especially useful when you want to apply a `class` and `style` attribute to a partial root and merge the dynamic local with default value. For example, if you have the following partial:
```erb
<%# locals: (class: nil) -%>
<button class% class="big">Button</button>
```
that is used as follows:
```html
<_button class="blue" />
```
it will render:
```html
<button class="big blue">Button</button>
```

> [!NOTE]
> Since reserved ruby keywords such as `class` can't be used as variable names but still can be passed as locals to a partial, they are retrieved from a binding.
> 
> For example:
> ```html
> <div class%>Content</div>
> ```
> is equivalent to:
> ```erb
> <div class="<%= binding.local_variable_get('class') %>">Content</div>
> ```

#### `provide` and `inject` helpers

Instead of using `%yields` attribute, a parent partial can indirectly pass a variable to its children using the `provide` and `inject` helpers. The example above can be modified as follows:
```html
<_widget-builder>
  <_widget-element />
</_widget-builder>
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


#### Forms

You can build a `<form>` element in ERB using [ActionView form helpers](https://guides.rubyonrails.org/form_helpers.html). Theo provides corresponding partials. For example:
```html
<_form-with model%="widget" data-turbo-confirm="Are you sure?">
  <div>
    <_label name="name" />
    <_text-field name="name" />
  </div>

  <div>
    <_label name="size" />
    <_select name="size" options%="['Big', 'Small']" />
  </div>

  <_submit value="Create" />
</_form-with>
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

If a component exists, and you use PascalCase syntax, Theo automatically renders it instead of a partial. Therefore:
```html
<Button size="large" />
```
is equivalent to:
```erb
<%= render(ButtonComponent.new(size: "large")) %>
```

Components can yield a value:
```html
<Button size="large" %yields="component">
  <% component.with_header do %>Icon<% end %>
  Create
</Button>
```

You can also render a component collection as follows:
```html
<Widget %collection="widgets" />
```
which is equivalent to:
```erb
<%= render WidgetComponent.with_collection(widgets) %>
```
