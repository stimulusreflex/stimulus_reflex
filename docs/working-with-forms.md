---
description: Forms fly business class on StimulusReflex Airways ✈️
---

# Working with HTML Forms

This is a work in progress. Nothing to see, here.

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

