---
description: How to restrict DOM updates
---

# Scoping

By default, StimulusReflex updates your entire page. It uses the amazing [morphdom](https://github.com/patrick-steele-idem/morphdom) library to do the smallest number of DOM modifications necessary to refresh your UI in just a few milliseconds. For many developers, this will be a perfect solution and they can stop reading here.

Some applications are more sophisticated. You might want to think of your site in terms of components, or you might need to interact with legacy JavaScript plugins on your page that don't play nicely with modern techniques. Heck, you might just need to make sure we don't reload the same 3rd party ad tracker every time someone clicks a button.

Great news: we have you covered.

## Partial DOM updates

You can add the following attribute to any element in your DOM that has a `data-reflex` attribute:

`data-reflex-root=".class, #id, [attribute]"`

In this case, instead of updating the entire DOM, we can pass a comma-delimited list of CSS selectors. Each selector will retrieve one DOM element; if there are no elements that match, the selector will be ignored.

Here is a simple example: the user is presented with a text box. Anything they type into the text box will be echoed back in two div elements, forwards and backwards.

{% code-tabs %}
{% code-tabs-item title="index.html.erb" %}
```text
<div data-controller="example">
  <input type="text" value="<%= @words %>" data-reflex-root="[forward],[backward]" data-reflex="keyup->ExampleReflex#words">
  <div forward><%= @words || rand(1000) %></div>
  <div backward><%= @words&.reverse || rand(1000) %></div>
</div>
```
{% endcode-tabs-item %}

{% code-tabs-item title="example\_reflex.rb" %}
```ruby
  def words
    @words = element[:value]
  end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% hint style="info" %}
One interesting detail of this example is that by assigning the root to `[forward],[backward]` we are implicitly telling StimulusReflex to **not** update the text input itself. This prevents resetting the input value while the user is typing.
{% endhint %}

## Persisting Elements

Perhaps you just don't want a section of your DOM to be updated by StimulusReflex, even if you're using the full document body default.

Just add `data-reflex-permanent` to any element in your DOM, and it will be left unchanged.

{% code-tabs %}
{% code-tabs-item title="index.html.erb" %}
```markup
<div data-reflex-permanent>
  <iframe src="https://ghbtns.com/github-btn.html?user=hopsoft&repo=stimulus_reflex&type=star&count=true" frameborder="0" scrolling="0" class="ghbtn"></iframe>
  <iframe src="https://ghbtns.com/github-btn.html?user=hopsoft&repo=stimulus_reflex&type=fork&count=true" frameborder="0" scrolling="0" class="ghbtn"></iframe>
</div>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% hint style="warning" %}
This is especially important for 3rd-party elements such as ad tracking scripts, Google Analytics, and any other widget that renders itself such as a React component or legacy jQuery plugin.
{% endhint %}

{% hint style="danger" %}
Beware of GEMs that implicitly inject HTML into the body as it might be removed from the DOM when a Reflex is invoked. For example, consider the [intercom-rails gem](https://github.com/intercom/intercom-rails) which automatically injects the Intercom chat into the body. GEMs like this often provide [instructions](https://github.com/intercom/intercom-rails#manually-inserting-the-intercom-javascript) for explicitly including their markup. We recommend using the explicit option whenever possible so you can wrap the content with `data-reflex-permanent`.
{% endhint %}

