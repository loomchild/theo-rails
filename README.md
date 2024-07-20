[![Gem Version](https://badge.fury.io/rb/theo-rails.svg)](https://badge.fury.io/rb/theo-rails)

# Theo
Theo is a small and elegant HTML-like template language for Ruby on Rails, with natural partials and computed attributes.

> [!WARNING]
> Please note that this software is still experimental - use at your own risk.


## Introduction

Thanks to Hotwire, it's now possible to build sophisticated server-rendered user interfaces in Ruby on Rails. Yet ERB, Rails' most popular template language, has unintuitive partial syntax, especially for someone used to working with Vue.js or React components.

With Theo, you can render a partial using HTML-like syntax:
```
<button-partial size="small" label%="label" />
```


## Installation

Run

    gem install theo-rails

If you are using TailwindCSS, add `.theo` extension to the `content` key in your `tailwind.config.js`:

    './app/views/**/*.{erb,haml,html,slim,theo}'


## Syntax


### Computed attributes

Computing attribute values in ERB feels awkward, because angle brackets `<>` collide with the surrounding HTML tag.

In Theo an attribute with computed value can be expressed via `%=`.

For example:
```
<a href%="root_path">Home</a>
```
is equivalent to:
```
<a href="<%= root_path%>">Home</a>
```
> [!TIP]  
> Computed attributes work with partials as well as standard HTML tags.


### Partials

Rendering ERB partials feels awkward, because they don't resemble components. 
Require switching context to Ruby.
the syntax containing angle brackets <> collides with the surrounding HTML.
Also repeating `render` verb makes it harder to think about a page as consitting of component hierarchy.
Theo syntax is component-oriented and heavily inspired by Vue.js.

In Theo, you render a partial by writing a tag with `-partial` suffix. 

For example:
```html
<button-partial size="large" />`
```
is equivalent to:
```erb
<%= render "button", size: "large" %>
```

Partials can also hold content, e.g.:
```
<button-partial size="large">
  Create
</button-partial>
```

> [!TIP]
> Partials themselves can be implemented in ERB, Theo or any other template language.


#### Collections

You can render a collection of partials as follows:
```
<widget-partial collection%="widgets" />
```
which is equivalent to:
```
<%= render partial: 'widget', collection: @widgets %>
```

You can also specify a custom local variable name via `as` attribute, e.g.:
```
<widget-partial collection%="@widgets" as="item" />
```


#### Boolean attributes

If an attribute has no value, you can skip it, and only specify its name.

For example:
```
<events-partial past />
```
is equivalent to:
```
<events-partial past="" />
```
which is equivalent to:
```
<%= render 'events', { past: '' } %>
```

#### `yields` attribute

Partials can yield a value, like a builder object that can be used by child partials.

For example:
```
<widget-partial yields="widget">
  <widget-part-partial widget%="widget" />
</wrapper-partial>
```
is equivalent to:
```
```


### ERB backwards compatibility

ERB syntax is supported by Theo and they can be mixed freely:
```
<% if total_amount > 100 %>
  <free-shipping-partial amount%="total_amount" />
<% end %>
```

## Utilities

### Form partials

You can build a `<form>` element in ERB using [ActionView form helpers](https://guides.rubyonrails.org/form_helpers.html). This creates a confusing mix of Ruby code and HTML markup in your templates.

In Theo, you can use partials that correspond to the form helpers instead.

For example:
```
<form-with-partial model%="widget" data-turbo-confirm="Are you sure?">
  <div>
    <label-partial name="name" />
    <text-field-partial name="name" />
  </div>

  <div>
    <label-partial name="size" />
    <select-partial name="size" options%="['Big', 'Small']" />
  </div>

  <submit-partial label="Create" />
</form-with-partial>
```
is equivalent to:
```
<%= form_with model: @widget do |form| %>
    <%= form.text_area :content, rows: 3, class: 'w-full max-w-md text-xs' %>

<% end %>
```


### Helpers

#### `provide` and `inject`

Parent partial can indirectly pass a variable to its children via `provide` and `inject` helpers.

// TODO:convert to widget
`parent.theo`:
```erb
<div>
  <% provide(variable:) do %>
    <%= yield %>
  <% end %>
</div>
```

`child.theo`:
```
<span><%= inject(:variable) %></span>
```

Usage:
```
<parent-partial>
  <child-partial />
</parent-partial>
```

> [!NOTE]
> This technique is used by [form partials](#form-partials), to avoid passing `form` variable via [`yields` attribute](#yields-attribute). Use it sparingly, as implicit variables can reduce code readability. 
