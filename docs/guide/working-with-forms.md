---
description: Forms fly business class on StimulusReflex Airways ✈️
---

<script setup>
  import LinkComponent from '../components/LinkComponent.vue'
</script>


# Forms

When developers learn StimulusReflex and re-consider how they approach building reactive user experiences, one of the first questions is how to submit a form using their shiny new hammer.

The simple answer is... you don't! **Form submission in Rails is already really well-designed and powerful**. You get ActiveRecord model validations, the Flash message system, allowed and blocked parameters, HTTP caching and of course, UJS remote form submission. UJS was introduced in Rails 3.2 and provided an easy way to submit forms via Ajax.

## StimulusReflex + mrujs = 🥰

UJS-powered remote forms are great, especially now that we have [mrujs](https://mrujs.com), the spiritual successor to the classic `rails-ujs` library that shipped with Rails until recently. `mrujs` is excellent:

* it provides a nearly 1:1 drop-in replacement for `rails-ujs`
* it makes use of modern browser features like `fetch` (instead of XMLHttpRequest)
* it uses Morphdom - the same library powering StimulusReflex Morphs - to show validation errors on your forms. **This makes the Optimism gem obsolete**, as it was created to provide functionality that was missing in `rails-ujs` 🎉
* it has a great plugin ecosystem... including support for CableReady's [CableCar](https://cableready.stimulusreflex.com/guide/cable-car) operation builder

Don't believe the hype: **UJS is alive and well!**

::: info
When you POST a form to a boilerplate Rails resource controller and your create attempt fails, the URL will appear to show the `new` template _content_ but the URL will appear to be `/` (aka the `index` action). This will make it impossible for StimulusReflex Page Morphs to update the page.

The recommended mitigation for this behaviour is to **use Mrujs**.
:::

## StimulusReflex form processing

StimulusReflex gathers all of the attributes on the element that initiates a Reflex. All of this data gets packed into an object that is made available to your Reflex action method through the `element` accessor. You can even [scoop up the attributes of parent elements](/guide/reflexes#combined-data-attributes-with-stimulate). This is very different from the mechanics of a form submission.

However, if a Reflex is called on a `form` element - or a **child** of that `form` element - then the data for the whole form can **optionally** be serialized and made available to the server-side Reflex action method as the `params` accessor.

::: info
Form serialization will not be enabled by default in StimulusReflex v4.

v3.5 developers will see a deprecation warning suggesting that they explicitly set `serializeForm: true` for forms that they would like to be serialized.
:::

`params` is an instance of `ActionController::Parameters` which you can manipulate the same way you would with a real form submitted via a normal POST action, with `require` and `permit`. This is useful for validating models and setting multiple attributes of a model at the same time, even if it hasn't yet been saved to the datastore.

To enable this form serialization in a Reflex, either set the `serializeForm: true` option when calling `this.stimulate()` or make sure that there's a `data-reflex-serialize-form` data attribute on the element which initiates your Reflex action.

::: code-group
```javascript [JavaScript]
this.stimulate('Example#foo', { serializeForm: true })
```

```html [HTML]
<form data-reflex="submit->Example#foo" data-reflex-serialize-form></form>
```
:::

## When forms are not actually forms

StimulusReflex uses `form` elements as a familiar way to group related elements together. However, a lot of newcomers get attached to the idea that the form they are serializing is being POSTed _as_ an HTML form, which it is **not**.

* forms are usually submitted via a classic POST operation or an Ajax fetch; this is _not the case_ when working with StimulusReflex
* forms usually have action and method attributes; we recommend against them - you really **can** just use `<form></form>` with no other mechanism or configuration required
* forms often have submit buttons; when using StimulusReflex, submit buttons have no effect
* there's no reason to set up a route or controller action for a form intended for StimulusReflex

::: info
You might be wondering why to even use forms at all. One significant reason is that many CSS frameworks like Bootstrap expect forms to be forms.
:::

## Remote forms in Rails 6.1

The behaviour of form helpers changed slightly in Rails 6.1, as forms are no longer automatically set to be `remote: true` by default. This catches many developers off-guard!

We recommend that Rails developers use UJS/mrujs remote forms wherever possible, especially if they are using Turbolinks / Turbo Drive. This allows forms to be submitted without reloading the page, which is not only much faster (no more ugly screen refreshes!) but allows ActionCable Connections to remain open, too. This prevents any interruption that could impact your Reflexes.

```html
<%= form_with model: @foo, local: false %>
<%= form_with model: @foo, data: { remote: "true" } %>
<%= form_for @foo, remote: true %>
<form action="/foo" data-remote="true" method="post"></form>
```

### Firefox considerations

Firefox has a history of quirky behaviour when it comes to form submission with JavaScript. When you submit a form with an HTTP POST, Firefox appears to reload the page, disrupting the WebSocket connection.

Our recommended mitigation for most Firefox form issues is to make sure that you're using `local: false`.

### `.submit` vs `.requestSubmit`

While not directly SR-specific, we've noticed that a lot of developers get tripped up with the subtle differences between these two form submission methods. Many developers have never heard of [`requestSubmit`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/requestSubmit) or have no idea why it exists.

Quoting from MDN:

> &#x20;`submit()` submits the form, but that's all it does. `requestSubmit()`, on the other hand, acts as if a submit button were clicked. The form's content is validated, and the form is submitted only if validation succeeds. Once the form has been submitted, the [`submit`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit_event) event is sent back to the form object.

## Working with the `params` accessor in your Reflex class

The `params` accessor is available to your `before_reflex` `around_reflex` and `after_reflex` callbacks in your server-side Reflex class. You are also free to add additional business logic on the client using the Reflex [life-cycle callbacks](/guide/lifecycle#server-side-reflex-callbacks) in your Stimulus controllers.

The `params` accessor behaves as it does in a Rails controller, so you are free to lock it down and add nested models as you expect:

```ruby
params.require(:post).permit(:name, comments_attributes: [:id, :_destroy, :name])
```

Your `@post` object is instantiated from `params` so if model validations fail, your Post model instance is still in scope when the page re-renders. The model's `errors` collection is available in the view. 🐛

One benefit of this design is that implementing an auto-save feature becomes as simple as adding `data-reflex="change->Post#update"` to each field. Since the field is inside the parent `form` element, all inputs are automatically serialized and sent to your Reflex class.

Working with `has_many` associations? No sweat! Building a new record for a nested model requires **no JavaScript**. Your Reflex calls `@post.comments.build` and because Rails knows about the association, any re-renders populate the empty form field as normal.

Reflex actions called outside of a form will still have a `params` accessor, pointing to an empty `ActionController::Parameters` instance.

::: info
If you call a full-page update Reflex outside of a form that has unsaved data, you will lose the data in the form. You will also lose the data if you throw your laptop into a volcano. 🌋
:::

### A note about file uploads

At the time of this writing, **forms that upload files are unsupported by StimulusReflex**. We suggest that you design your UI in such a way that files can be uploaded directly, making use of the standard Rails UJS form upload techniques. You might need to use `data-reflex-permanent` so that you don't lose UI state when a Reflex is triggered.

You can explore using CableReady and/or mrujs to provide live error handling, and there are excellent tools such as [Dropzone](https://www.dropzonejs.com) which make it possible to upload multiple files, work with ActiveStorage and even upload directly to a cloud storage bucket.

As websockets is a text-based protocol that doesn't guarantee packet delivery or the order of packet arrival, it is not well-suited to uploading binary files. This is an example of a problem best solved with vanilla Rails UJS form handling and [ActiveStorage](https://guides.rubyonrails.org/active_storage_overview.html).

### Resetting a submitted form

If you handle your form with StimulusReflex, and the resulting DOM diff doesn't touch the form, you will end up with stale data in your form `<input>` fields. You're going to need to clear your form so the user can add more data.

One simple technique is to use a Stimulus controller to reset the form after the Reflex completes successfully. We'll call this controller `reflex-form` and we'll use it to set a target on the first text field, as well as an action on the submit button:

```javascript
<%= form_with(model: model, data: { controller: "reflex-form" }) do |form| %>
  <%= form.text_field :name, data: { target: "reflex-form.focus" } %>
  <%= form.button data: {action: "click->reflex-form#submit"} %>
<% end %>
```

This controller will make use of the [Promise](/guide/lifecycle#promises) returned by the `this.stimulate()` method:

::: code-group
```javascript [app/javascript/controllers/reflex_form_controller.js]
import ApplicationController from './application_controller'

export default class extends ApplicationController {
  static targets = ['focus']
  submit (e) {
    e.preventDefault()
    this.stimulate('Reflex#submit').then(() => {
      this.element.reset()
      // optional: set focus on the freshly cleared input
      this.focusTarget.focus()
    })
  }
}
```
:::

## Example: Auto-saving Posts with nested Comments

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

You should **memoize** the resource you'll be mutating in your controller action so that the same form data is available regardless of whether an action is called from a page navigation or a Reflex update:

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
    <ul>
    <% @post.errors.full_messages.each do |message| %>
      <li><%= message %></li>
    <% end %>
    </ul>
  <% end %>

  <div>
    <%= form.label :name %>
    <%= form.text_field :name, data: { reflex: "change->PostReflex#submit", reflex_dataset: "combined" } %>
  </div>

  <%= form.fields_for :comments, @post.comments do |comment_form| %>
    <%= comment_form.hidden :id %>
    <%= comment_form.label :name %>
    <%= comment_form.text_field :name, data: { reflex: "change->PostReflex#submit", reflex_dataset: "combined" } %>
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

## Single source of truth

While stateless form submissions have technically always suffered from the "last update wins" problem, it's only in recent years that developers have created interfaces that need to respond to changing application state in real-time.

There are a few guiding principles that we adhere to when building a technology that can change the page you're on, even while you're busy working on something important. One of the biggest wins associated with keeping the web server as the single source of truth about the state of your application and its data is that you don't have to worry about the synchronization of state with the client. Whatever you see on your screen is the same thing that you would see if you hit refresh. This makes developing applications with StimulusReflex faster and significantly less complicated than equivalent solutions which make use of SPAs like React.

However, **StimulusReflex works hard to ensure morph operations will not overwrite the value of a text input or textarea element if it has active focus in your browser**. This exception is important because there's no compelling UI experience where you want to change the contents of an input element _while the user is typing into it_.

We've worked really hard to make sure that developers can update other aspects of the active text input element. For example, it's possible to change the background color or even mark the element as disabled while you're typing into it. However, all attempts to overwrite the input element's value will be silently suppressed.

If you need to filter or constrain the contents of a text input, consider using a client-side library such as [`cleave.js`](https://nosir.github.io/cleave.js/) instead of trying to circumvent the Single Source of Truth mechanisms, which are there to protect your users from their fellow collaborators.

Note that this concept only applies to the active text input element. Any elements which are marked with `data-reflex-permanent` will not be **morphed** in any way.

::: info
Unfortunately, it's not possible to protect elements from being replaced with a Selector Morph that uses an `inner_html` operation. The client-side logger will show you which operation is being used, and you can [tweak the data](/guide/morph-modes#things-go-wrong) you're sending to make sure it's delivered as a `morph` operation.

Similarly, custom CableReady operations broadcast by the developer do not automatically respect `data-reflex-permanent`. You can set the `permanent_attribute_name` option for the [`morph`](https://cableready.stimulusreflex.com/reference/operations/dom-mutations#morph) operation directly.
:::

## Modifying forms with Morphs

If you need to change form elements in your document based on user input, you will find yourself needing to re-render partials inside of your Reflex. This raises the very good question of how to access the `form` context, since it's not just a simple view helper that you can include.

You will need the controller's view context, as well as the parent resource used to create the form initially:

```ruby
class FormReflex < ApplicationReflex
  delegate :view_context, to: :controller

  def swap
    post = Post.find(123)

    form = ActionView::Helpers::FormBuilder.new(
      :post, post, view_context, {}
    )

    html = render(partial: "path/to/partial", locals: {form: form})

    morph "#form_swap", html
  end
end
```

Depending on how your DOM hierarchy is set up, make sure that you're giving `morph` the HTML content required to successfully update the children of your target element. This requires that the outermost element of the supplied HTML matches the parent element:

```html
<%= form_with model: @post do |form| %>
  <%= form.text_field :title %>
  <div id="form_swap">
    <%= render "path/to/partial", locals: {form: form} %>
  </div>
  <%= form.text_area :body, size: "60x10" %>
  <%= form.submit %>
<% end %>
```

The partial might look something like this:

```html
<%= form.text_field :summary %>
```

Since the partial does not include the parent `div`, in order to successfully replace the contents of `#form_swap` we'll need to wrap it ourselves:

```ruby
    html = render(partial: "path/to/partial", locals: {form: form})

    morph "#form_swap", "<div id='form_swap'>#{html}</div>"
```

You can learn more about why wrapping Morph replacement content is necessary:

<LinkComponent name="Intelligent Defaults" href="/guide/morph-modes#intelligent-defaults"/>

## Modifying `params` before a Reflex

On the client, you can modify `params` in your `beforeReflex` callback by modifying `element.reflexData[reflexId]` before it is sent to the server.

```javascript
export default class extends ApplicationController {
  beforeReflex(element, reflex, noop, reflexId) {
    const { params } = element.reflexData[reflexId]

    element.reflexData[reflexId].params = {
      ...params,
      foo: true,
      bar: false
    }
  }
}
```

Or, if you prefer working with events:

```javascript
document.addEventListener('stimulus-reflex:before', event => {
  const reflexId = event.detail.reflexId
  const { params } = event.target.reflexData[reflexId]

  event.target.reflexData[reflexId].params = {
    ...params,
    foo: true,
    bar: false
  }
})
```
