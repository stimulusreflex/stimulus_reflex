# Scoped Reflexes

By default, StimulusReflex updates your entire page. It uses the MorphDom library to do the smallest number of DOM modifications necessary to refresh your UI in just a few milliseconds. For many developers, this will be a perfect solution and they can stop reading here.

Some applications are more sophisticated. You might want to think of your site in terms of components, or you might need to interact with legacy JavaScript plugins on your page that don't play nicely with modern techniques. Heck, you might just need to make sure we don't reload the same 3rd party Google/Facebook tracking modules every time someone clicks a button.

Great news: we have you covered.

## Partial DOM updates

You can add the following attribute to any element in your DOM that has a `data-reflex` attribute:

`data-reflex-root=".class, #id, [attribute]"`

In this case, instead of updating the entire DOM, we can pass a comma-delimited list of CSS selectors. Each selector will retrieve one DOM element; if there are no elements that match, the selector will be ignored.

Here is a simple example: the user is presented with a text box. Anything they type into the text box will be echoed back to them, forwards and backwards.

```
  def words
    @words = element[:value]
    puts @words
  end
```

```
<input type="text" value="<%= @words %>" data-reflex-root="[forward],[backward]" data-reflex="keyup->ExampleReflex#words">
<div forward><%= @words || rand(1000) %></div>
<div backward><%= @words&.reverse || rand(1000) %></div>
```

## Ignoring parts of your DOM

Perhaps you just don't want a section of your DOM to be updated by StimulusReflex, even if you're using the full document body default.

`data-reflex-permanent`

Just add this attribute to any element in your DOM, and it will be left undisturbed.