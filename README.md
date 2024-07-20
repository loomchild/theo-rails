[![Gem Version](https://badge.fury.io/rb/theo-rails.svg)](https://badge.fury.io/rb/theo-rails)

# Theo
Theo is a small and elegant HTML-like template language for Ruby on Rails, featuring natural partials and computed attributes.

> [!WARNING]
> Please note that this software is still experimental - use at your own risk.


## Introduction

Thanks to Hotwire, it's now possible to build sophisticated server-rendered user interfaces in Ruby on Rails. However, ERB, Rails' most popular template language, has unintuitive partial syntax, especially for those used to working with Vue.js or React components.

With Theo, you can render a partial using HTML-like syntax:
```html
<button-partial size="large" label%="label" />
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


### Partials

Rendering a partial in ERB requires switching between HTML markup and Ruby code, and the `render` verb makes it difficult to imagine a page as a component structure.

In Theo, you render a partial by writing a tag with `-partial` suffix, for example:
```html
<button-partial size="large" />`
```
is equivalent to:
```erb
<%= render 'button', size: 'large' %>
```

Naturally, partials can also include content, e.g.:
```html
<button-partial size="large">
  Create
</button-partial>
```

> [!TIP]
> Rendered partials can be implemented in ERB, Theo or any other template language.


#### Collections

You can render a collection of partials as follows:
```html
<widget-partial collection%="widgets" />
```
which is equivalent to:
```erb
<%= render partial: 'widget', collection: widgets %>
```

You can also customize the local variable name via the `as` attribute, e.g.:
```html
<widget-partial collection%="widgets" as="item" />
```

#### Boolean attributes

If an attribute has no value, you can omit it, for example:
```html
<button-partial disabled />
```
is equivalent to:
```html
<button-partial disabled="" />
```


#### Path

To render a partial from another folder, use the 'path' attribute, e.g.:
```html
<widget-partial path="widgets" />
```
is equivalent to:
```erb
<%= render 'widgets/widget' %>
```


#### `yields` attribute

Partials can yield a value, such as a builder object that can be used by child partials. For example:
```html
<widget-builder-partial yields="widget">
  <widget-element-partial widget%="widget" />
</widget-builder-partial>
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
<widget-builder-partial>
  <widget-element-partial />
</widget-builder-partial>
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
  <free-shipping-partial amount%="total_amount" />
<% end %>
```


## Forms

You can build a `<form>` element in ERB using [ActionView form helpers](https://guides.rubyonrails.org/form_helpers.html).

In Theo, you can use partials that correspond to the form helpers, for example:
```html
<form-with-partial model%="widget" data-turbo-confirm="Are you sure?">
  <div>
    <label-partial name="name" />
    <text-field-partial name="name" />
  </div>

  <div>
    <label-partial name="size" />
    <select-partial name="size" options%="['Big', 'Small']" />
  </div>

  <submit-partial value="Create" />
</form-with-partial>
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
