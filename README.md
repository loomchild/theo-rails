[![Gem Version](https://badge.fury.io/rb/theo-rails.svg)](https://badge.fury.io/rb/theo-rails)

# Theo
Theo is a small and elegant HTML-like template language for Ruby on Rails, with natural partials and computed attributes.

> Please note that this software is experimental - use at your own risk.


## Why?

Thanks to Hotwire, it's now possible to build sophisticated server-rendered user interfaces without fully-fledged JavaScript framework in Ruby on Rails.
Components are a fundamental building blocks of an user interface.
Using partials in ERB feels awkward, because the syntax is alien to the surrounding HTML.
Also repeating `render` verb makes it harder to think about component hierarchy.

Theo syntax is component-oriented and heavily inspired by Vue.js.

TODO: better examples, maybe with credit card
```
<note-partial note%="note" size="small" disabled />
```

It's especially powerful when combined with light HTML-based front-end technology, such as TailwindCSS or Alpine.js:
```
<button-partial label="Note→" size="small" x-show="!adding" class="border rounded px-4" @click="adding = true" />
```


## Installation
Run

    gem install theo-rails

If you are using TailwindCSS add `.theo` view filetype to the `content` key in your `tailwind.config.js`:

    './app/views/**/*.{erb,haml,html,slim,theo}'


## Syntax


### Computed attributes

Dynamic attributes can be expressed with `%=`.

For example:
```
<span class%="'red-' + 100">Text</span>
```
is equivalent to:
```
<span class="<%= 'red-' + 100 %>">Text</span>
```

They work with partials and standard HTML elements.


### Partials

Partials are rendered by specifying an element with `-partial` suffix. 

For example:
```html
<phone-partial number="+33123456789" />
```
is equivalent to:
```erb
<%= render "phone", number: "+33123456789" %>
```


#### Collections


```
<note-partial collection%="@notes" />
```

```
<%= render partial: 'note', collection: @notes %>
```

You can also specify a custom local variable name by using `as` attribute:
```
<note-partial collection%="@notes" as="item" />
```

```
<%= render partial: 'note', collection: @notes, as: 'item' %>
```


#### Boolean attributes

If an attribute has no value, you can omit it.

For example:
```
<events-partial past />
```
is equivalent to:
```
<events-partial past="" />
```

#### `yields` attribute

TODO: better example.

```
<address-partial yields="address">
  <%= address %>
</address-partial>
```


### ERB backwards compatibility

ERB syntax is supported by Theo and they can be mixed freely:

```
<% a = 2 + 2 %>
<my-partial a="<%= a %>" />
```
TODO: better example
```
<% if @event.bookings.canceled.any? %>
  <%= @event.title %>
<% end %>
```

## Utilities

### Forms
Theo includes partials that correspond to [Action View Form Helpers](https://guides.rubyonrails.org/form_helpers.html).

You can use them as follows:
```
  <form-with-partial model%="note" method="delete" class="inline" data-turbo-confirm="Are you sure?">
     <button class="absolute top-0 right-1 enabled:transition enabled:hover:text-blue-500 disabled:cursor-not-allowed disabled:text-transparent">
       ✕
     </button>
  </form-with-partial>
```

```
<form-with-partial model%="@note" yields="form">
    <text-area-partial form%="form" name="content" rows="3" class="w-full max-w-md text-xs" />

  <button-partial label="Add" size="small" />
</form-with-partial>
```

```
<form-with-partial model%="@user" url%="session_path" class="w-full sm:w-2/3 md:w-1/2 lg:w-1/3 p-4">
```

```
<%= form_with model: @user, url: session_path, class: "w-full sm:w-2/3 md:w-1/2 lg:w-1/3 p-4" do |form| %>
```

```
<%= form_with model: @note do |form| %>
    <%= form.text_area :content, rows: 3, class: 'w-full max-w-md text-xs' %>

  <%= render 'button', label: 'Add', size: :small %>
<% end %>
```

```
<label-partial form%="form" name="email" class="" />
<email-field-partial form%="form" name="email" />
```

```
<form-with-partial data-turbo-confirm="Sure?" yields="form">
  <div>
    <label-partial name="name" />
    <text-field-partial name="name" />
  </div>

  <div>
    <label-partial form%="form" name="select" />
    <select-partial form%="form" name="select" options%="['a', 'b']" />
  </div>
</form-with-partial>
```

```
<form-with-partial model%="@manual_booking" url%="event_manual_bookings_path(@event)" yields="form">
  <div class="flex gap-2 flex-wrap">
    <div>
      <label-partial form%="form" name="name" class="mr-1" />
      <text-field-partial form%="form" name="name" />
    </div>

    <div>
      <label-partial form%="form" name="source" class="mr-1" />
      <select-partial form%="form" name="source" options%="[['Cash', :cash], ['Free', :free]]" x-model="source" />
    </div>

    <div x-show="source === 'cash'">
      <label-partial form%="form" name="price" class="mr-1" />
      <number-field-partial form%="form" name="price" in%="0..100" value%="@event.price.round" class="w-24" />
    </div>

    <div>
      <label-partial form%="form" name="guests" class="mr-1" />
      <number-field-partial form%="form" name="guests" in%="0..9" value%="0" class="w-16" />
    </div>

    <button-partial label="Add" size="big" />
</form-with-partial>
```


### Helpers

#### `provide` and `inject`

As an alternative to `yields`.

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

This technique is used in forms, to avoid passing `form` attribute.
Use sparingly, since implicit variable can make your code less readable.

