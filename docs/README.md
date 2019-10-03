---
description: Build reactive applications with the Rails tooling you already know and love.
---

# StimulusReflex

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

**Build reactive applications with the Rails tooling you already know and love.** StimulusReflex is designed to work perfectly with [server rendered HTML](https://guides.rubyonrails.org/action_view_overview.html), [Russian doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), [Stimulus](https://stimulusjs.org/), [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA), etc... and strives to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/).

> Ship projects faster... with smaller teams.

## Before you Begin

A great user experience can be created with Rails alone. Tools like [UJS remote elements](https://guides.rubyonrails.org/working_with_javascript_in_rails.html#remote-elements) , [Stimulus](https://stimulusjs.org/), and [Turbolinks](https://github.com/turbolinks/turbolinks) are incredibly powerful when combined. Try building your application using these tools before introducing StimulusReflex.

{% hint style="info" %}
See the [Stimulus TodoMVC](https://github.com/hopsoft/stimulus_todomvc) example application if you are unsure how to do this.
{% endhint %}

## Benefits

StimulusReflex offers 3 primary benefits over the traditional Rails request/response cycle.

1. **All communication happens via web socket** - avoids the overhead of traditional HTTP connections
2. **The controller action is invoked directly** - skips framework overhead like the middleware chain
3. **DOM diffing is used to update the page** - provides faster rendering and less jitter

## How it Works

Here's what happens whenever a `StimulusReflex::Reflex` is invoked.

1. The page that triggered the reflex is re-rerendered.
2. The re-rendered HTML is sent to the client over the ActionCable socket.
3. The page is updated via fast DOM diffing courtesy of morphdom.

{% hint style="success" %}
All instance variables created in the reflex are made available to the Rails controller and view.
{% endhint %}

{% hint style="info" %}
**The entire body is re-rendered and sent over the socket.** Smaller scoped DOM updates may come in a future release.
{% endhint %}

## Example Applications

* [TodoMVC](https://stimulus-reflex-todomvc.herokuapp.com) - An implementation of [TodoMVC](http://todomvc.com/) using [Ruby on Rails](https://rubyonrails.org/), [StimulusJS](https://stimulusjs.org/), and [StimulusReflex](https://github.com/hopsoft/stimulus_reflex). [https://github.com/hopsoft/stimulus\_reflex\_todomvc](https://github.com/hopsoft/stimulus_reflex_todomvc)

