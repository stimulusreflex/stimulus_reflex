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

When developers learn StimulusReflex and re-consider how they approach building reactive user experiences, one of the first questions is how to submit a form using their shiny new hammer. We recommend that you approach every requirement from [the bottom of the Rails stack and move up](https://docs.stimulusreflex.com/quickstart#before-you-begin), because **form submission in Rails is already really well-designed and powerful**. UJS-powered remote forms are \*great\*, especially with the [Optimism](https://optimism.leastbad.com/) gem delivering validation errors over the wire. 🦸🏽

{% hint style="warning" %}
Seriously, though: if you're thinking of replacing UJS remote forms with StimulusReflex form handling... just stick with Rails!
{% endhint %}

StimulusReflex gathers all of the attributes on the element that initiates a Reflex. All of this data gets packed into an object that is made available to your Reflex action method through the `element` accessor. You can even [scoop up the attributes of parent elements](https://docs.stimulusreflex.com/reflexes#inheriting-data-attributes-from-parent-elements). This leaves form submission in the cold, though... doesn't it? 🥶

### The `params` accessor

_Heck no!_ If a Reflex is called on a `form` element - or a **child** of that `form` element - then the data for the whole form will be properly serialized and made available to the Reflex action method as the `params` accessor. `params` is an instance of `ActionController::Parameters` as it would be if you submitted via a standard form POST or UJS remote submission.

{% hint style="success" %}
You should **memoize** the `params` in your controller action so that the same form data is available regardless of whether an action is called from a page navigation or a Reflex update.

`@post ||= Post.find(params[:id])`
{% endhint %}

One of the most exciting benefits of this design is that autosaving the data in your form becomes as simple as adding `data-reflex="change->Post#update"` to each field. Since the field is inside the parent `form` element, all inputs are automatically serialized and sent to your Reflex class.

The `params` accessor is available to your `before_reflex` and `after_reflex` callbacks in your server-side Reflex class. You are also free to add additional business logic on the client using the Reflex [lifecycle callbacks](https://docs.stimulusreflex.com/lifecycle) in your Stimulus controllers.

The `params` accessor behaves as it does in a Rails controller, so you are free to lock it down and add nested models as you expect:

```ruby
params.require(:post).permit(:name, comments_attributes: [:id, :_destroy, :name])
```

Your `@post` object is instantiated from `params` so if model validations fail, your Post model instance is still in scope when the page re-renders. The model's `errors` collection is available in the view. 🐛

Working with `has_many` associations? No sweat! Building a new record for a nested model requires **no JavaScript**. Your Reflex calls `@post.comments.build` and because Rails knows about the association, any re-renders populate the empty form field as normal.

Reflex actions called outside of a form will still have a `params` accessor, pointing to an empty `ActionController::Parameters` instance.

{% hint style="danger" %}
If you call a full-page update Reflex outside of a form that has unsaved data, you will lose the data in the form. You will also lose the data if you throw your laptop into a volcano. 🌋
{% endhint %}

#### Modifying form data before sending to the server

Should you need to modify the contents of your params before the Reflex sends the data to the server, you can use the `before` callbacks to do so:

```javascript
document.addEventListener('stimulus-reflex:before', event => {
  const { params } = event.target.reflexData
  event.target.reflexData.params = { ...params, foo: true, bar: false }
})
```

```ruby
export default class extends Controller {
  beforeReflex(element) {
    const { params } = element.reflexData
    element.reflexData.params = { ...params, foo: true, bar: false }
  }
}
```

#### A note about &lt;input type="file"&gt; fields

At the time of this writing, **forms that upload files are unsupported by StimulusReflex**. We suggest that you design your UI in such a way that files can be uploaded directly, making use of the standard Rails UJS form upload techniques. You might need to use `data-reflex-permanent` so that you don't lose UI state when a Reflex is triggered.

You can explore using Optimism for live error handling, and there are excellent tools such as [Dropzone](https://www.dropzonejs.com/) which make it possible to upload multiple files, work with ActiveStorage and even upload directly to a cloud storage bucket.

As websockets is a text-based protocol that doesn't guarantee packet delivery or the order of packet arrival, it is not well-suited to uploading binary files. This is an example of a problem best solved with vanilla Rails.

### Example: Auto-saving Posts with nested Comments

We're going to build an example of StimulusReflex form handling for an **edit** action, starting with the ActiveRecord models for a classic Post with Comments relationship:

```ruby
class Post < ApplicationRecord
  validates :name, presence: true
  has_many :comments
  accepts_nested_attributes_for :comments
end

class Comment< ApplicationRecord
  validates :name, presence: true
  belongs_to :post
end
```

We'll need to memoize the `@post` object so that we can access `params` throughout the entire lifecycle of the Reflex.

```ruby
class PostsController < ApplicationController
  def edit
    @post ||= Post.find(params[:id])
  end
end
```

Now, let's create the markup for our form, which will submit to the `Post` Reflex with a [signed global ID](https://github.com/rails/globalid).

```javascript
<%= form_with model: @post, data: { reflex: "submit->PostReflex#submit", signed_id: @post.to_sgid.to_s } do |form| %>

  <% if @post.errors.any? %>
    <% @post.errors.full_messages.each do |message| %>
      <li><%= message %>
    <% end %>
  <% end %>

  <div>
    <%= form.label :name %>
    <%= form.text_field :name, data: { reflex: "change->PostReflex#submit" } %>
  </div>

  <%= form.fields_for :comments, @post.comments do |comment_form| %>
    <%= comment_form.hidden :id %>
    <%= comment_form.label :name %>
    <%= comment_form.text_field :name, data: { reflex: "change->PostReflex#submit" } %>
  <% end %>

  <%= link_to "New comment", "#", data: { reflex: "click->PostReflex#build_comment" } %>

  <%= form.submit %>

<% end %>
```

Finally, let's configure our Reflex class. Since the `@post` object is created from the `params` in the `before_reflex` callback, users can click _New comment_ many times to get new empty comments.

```ruby
class PostReflex < ApplicationReflex
  before_reflex do
    @post = GlobalID::Locator.locate_signed(element.dataset.signed_id)
    @post.assign_attributes(post_params)
  end

  def submit
    @post.save
  end

  def build_comment
    @post.comments.build
  end

  private

  def post_params
    params.require(:post).permit(:name, comments_attributes: [:id, :name])
  end
end
```

Moving actions that traditionally lived in the realm of the ActionDispatch REST controller is not going to be necessary for every project - or every form! However, this functionality is a welcome tool on our belt.

