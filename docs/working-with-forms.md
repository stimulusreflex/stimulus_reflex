---
description: Forms fly business class on StimulusReflex Airways ✈️
---

# Working with HTML Forms

## Single source of truth

While stateless form submissions have technically always suffered from the "last update wins" problem, it's only in recent years that developers have created interfaces that need to respond to changing application state in real-time.

There are a few guiding principles that we adhere to when building a technology that can change the page you're on, even while you're busy working on something important. One of the biggest wins associated with keeping the web server as the single source of truth about the state of your application and its data is that you don't have to worry about the synchronization of state with the client. Whatever you see on your screen is the same thing that you would see if you hit refresh. This makes developing applications with StimulusReflex faster and significantly less complicated than equivalent solutions which make use of SPAs like React.

However, **StimulusReflex will never overwrite the value of a text input or textarea element if it has active focus in your browser**. This exception is important because there's no compelling UI experience where you want to change the contents of an input element _while the user is typing into it_.

We've worked really hard to make sure that developers can update other aspects of the active text input element. For example, it's possible to change the background color or even mark the element as disabled while you're typing into it. However, all attempts to overwrite the input element's value will be silently suppressed.

If you need to filter or constrain the contents of a text input, consider using a client-side library such as [Cleave.js](https://nosir.github.io/cleave.js/) instead of trying to circumvent the Single Source of Truth mechanisms, which are there to protect your users from their fellow collaborators.

Note that this concept only applies to the active text input element. Any elements which are marked with `data-reflex-permanent` will not be morphed in any way.

## Form submission

{% hint style="danger" %}
This is a work in progress! Please disregard.
{% endhint %}

```ruby
class Post < ApplicationRecord
  validates :name, presence: true
  has_many :categories
  accepts_nested_attributes_for :categories
end

class Category < ApplicationRecord
  validates :name, presence: true
  belongs_to :post
end
```

```ruby
class PostsController < ApplicationController
  def edit
    # Memoizing means the instance set in the reflex (from params) will be reused
    # when the page re-renders from SR, this is an important part of the magic.
    @post ||= Post.find(params[:id])
  end
end
```

```javascript
<%= form_with model: @post, data: { reflex: "submit->PostReflex#submit", signed_id: @post.to_sgid.to_s } do |form| %>
  <% if @post.errors.any? %>
    <!-- keep in mind, if you have error CSS classes defined, they will automatically pick up, too -->
    <% @post.errors.full_messages.each do |message| %>
      <li><%= message %>
    <% end %>
  <% end %>
  <div>
    <%= f.label :name %>
    <!-- changing this field will trigger the autosave
            if the field is changed while you have invalid categories, 
            they will stick around on re-render, but will show validation errors 
            because of accepts_nested_attributes and the category validations --> 
    <%= f.text_field :name, data: { reflex: "change->PostReflex#submit" } %>
  </div>
  <%= form.fields_for :categories, @post.categories do |category_form| %>
    <%= category_form.hidden :id %>
    <%= category_form.label :name,  %>
    <!-- changing this doesnt autosave, it's the responibility of either the submit button
            or the autosave that happens on name above.
            this is a bit silly of an example I've made, but it's to show how both autosaving
            and regular "form submission" can work together. -->
    <%= category_form.text_field :name
  <% end %>
  <%= link_to "New category", "#", data: { reflex: "click->PostReflex#build_category" } %>
  <%= form.submit %>
<% end %>
```

```ruby
class PostReflex < ApplicationReflex
  before_reflex do
    @post = GlobalID::Locator.locate_signed(element.dataset.dig("signed-id")
    @post.assign_attributes(post_params)
  end

  def submit
    @post.save
  end

  # Triggers re-render with new category.
  # Since we're building the object from params in the callback above, we can
  # click this as many times as we want to keep getting new categories.
  def build_category
    @post.categories.build
  end

  private

  def post_params
    params.require(:post).permit(:name, categories_attributes: [:id, :name])
  end
end
```

