---
description: How to restrict DOM updates
---

# Scoping

By default, StimulusReflex updates your entire page. It uses the amazing [morphdom](https://github.com/patrick-steele-idem/morphdom) library to do the smallest number of DOM modifications necessary to refresh your UI in just a few milliseconds. For many developers, this will be a perfect solution and they can stop reading here.

Some applications are more sophisticated. You might want to think of your site in terms of components, or you might need to interact with legacy JavaScript plugins on your page that don't play nicely with modern techniques. Heck, you might just need to make sure we don't reload the same 3rd party ad tracker every time someone clicks a button.

Great news: we have you covered.

## Partial DOM updates

Instead of updating your entire page, you can specify exactly which parts of the DOM will be updated using the `data-reflex-root` attribute.

`data-reflex-root=".class, #id, [attribute]"`

Simply pass a comma-delimited list of CSS selectors. Each selector will retrieve one DOM element; if there are no elements that match, the selector will be ignored.

StimulusReflex will decide which element's children to replace by evaluating three criteria in order:

1. Is there a `data-reflex-root` on the element with the `data-reflex`?
2. Is there a `data-reflex-root` on an ancestor element with a `data-controller` above the element in the DOM? It could be the element's immediate parent, but it doesn't have to be.
3. Just use the `body` element.

Here is a simple example: the user is presented with a text box. Anything they type into the text box will be echoed back in two div elements, forwards and backwards.

{% tabs %}
{% tab title="index.html.erb" %}
```text
<div data-controller="example" data-reflex-root="[forward],[backward]">
  <input type="text" value="<%= @words %>" data-reflex="keyup->ExampleReflex#words">
  <div forward><%= @words %></div>
  <div backward><%= @words&.reverse %></div>
</div>
```
{% endtab %}

{% tab title="example\_reflex.rb" %}
```ruby
  def words
    @words = element[:value]
  end
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
One interesting detail of this example is that by assigning the root to `[forward],[backward]` we are implicitly telling StimulusReflex to **not** update the text input itself. This prevents resetting the input value while the user is typing.
{% endhint %}

{% hint style="warning" %}
In StimulusReflex, morphdom is called with the **childrenOnly** flag set to _true_.

This means that &lt;body&gt; or the custom parent selector\(s\) you specify are not updated. For this reason, it's necessary to wrap anything you need to be updated in a div, span or other bounding tag so that it can be swapped out without confusion.

If you're stuck with an element that just won't update, make sure that you're not attempting to update the attributes on an &lt;a&gt;.
{% endhint %}

{% hint style="info" %}
It's completely valid to for an element with a data-reflex-root attribute to reference itself via a CSS class or other mechanism. Just always remember that the parent itself will not be replaced! Only the children of the parent are modified.
{% endhint %}

## Persisting Elements

Perhaps you just don't want a section of your DOM to be updated by StimulusReflex, even if you're using the full document body default.

Just add `data-reflex-permanent` to any element in your DOM, and it will be left unchanged.

{% tabs %}
{% tab title="index.html.erb" %}
```markup
<div data-reflex-permanent>
  <iframe src="https://ghbtns.com/github-btn.html?user=hopsoft&repo=stimulus_reflex&type=star&count=true" frameborder="0" scrolling="0" class="ghbtn"></iframe>
  <iframe src="https://ghbtns.com/github-btn.html?user=hopsoft&repo=stimulus_reflex&type=fork&count=true" frameborder="0" scrolling="0" class="ghbtn"></iframe>
</div>
```
{% endtab %}
{% endtabs %}

{% hint style="warning" %}
This is especially important for 3rd-party elements such as ad tracking scripts, Google Analytics, and any other widget that renders itself such as a React component or legacy jQuery plugin.
{% endhint %}

{% hint style="danger" %}
Beware of GEMs that implicitly inject HTML into the body as it might be removed from the DOM when a Reflex is invoked. For example, consider the [intercom-rails gem](https://github.com/intercom/intercom-rails) which automatically injects the Intercom chat into the body. GEMs like this often provide [instructions](https://github.com/intercom/intercom-rails#manually-inserting-the-intercom-javascript) for explicitly including their markup. We recommend using the explicit option whenever possible so you can wrap the content with `data-reflex-permanent`.
{% endhint %}

