---
description: Build reactive applications with the Rails tooling you already know and love.
---

# StimulusReflex

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

## History

**The traditional Rails request/response cycle is a thing of beauty.** Many verteran Rails programmers remember the awe and disbelief they felt after watching David Heinemeier-Hansson's [original Rails promo video](https://www.youtube.com/watch?v=Gzj723LkRJY).

It didn't seem possible that web development could be that easy. It was so productive that it was __fun__. Rails delivered [exponential gains in developer efficiency](https://www.youtube.com/watch?v=SWEts0rlezA&t=3m23s) and showed us a better way. Almost every modern framework in use today has borrowed ideas, patterns, and features from Rails.

And yet, __little by little__, things came undone as web apps got more ambitious. The pursuit of "native" UI speeds led to a new breed of increasingly complex technologies. This shift resulted in moving many of the server's responsibilities to the client. It feels like the industry traded "fun and productive" for collosal complexity and marginal gains. But, the "Modern JavaScript" mindset is pervasive. Unfortunately, many developers aren't even aware of the tradeoffs they've made.

## Phoenix LiveView: a New Hope

[Chris McCord](https://twitter.com/chris_mccord), creator of the [Phoenix](http://www.phoenixframework.org/) framework for [Elixir](https://elixir-lang.org/), recently introduced a technology named [LiveView](https://github.com/phoenixframework/phoenix_live_view). His [intro video](https://www.youtube.com/watch?v=8xJzHq8ru0M) captures the same feeling of promise and excitement that Rails had in the early days.

Phoenix is awesome. Elixir is awesome. They were made by former Rails core team members. There's no question that Elixir hits a sweet spot for people who want Rails-like conventions baked into a functional language running on the Erlang VM. But realistically, the Elixir and Phoenix communities are much much smaller than the Ruby and Rails communities.

StimulusReflex is inspired by LiveView, but we're charting our own course. We aim to make the experience of building interactive real-time apps with Rails the most productive and enjoyable choice available.

## Benefits

**You will ship projects faster, with smaller teams**. Also, you will re-discover the joy of development. It's a big deal and it's real.

StimulusReflex is designed to work perfectly with the Rails technologies you already know: [server rendered HTML](https://guides.rubyonrails.org/action_view_overview.html), [Russian Doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), [Stimulus](https://stimulusjs.org/) and [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA). We strive to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/). We believe that we can help show the industry a better way forward.

StimulusReflex welcomes everyone, from junior programmers to those with decades of industry experience. We hope all will discover the joy of employing simple architectural patterns that allow you to focus on product rather than periphery.

### Steps Involved

1. Build a typical Rails app with the elegant simplicity of server rendered HTML.
2. Then create small server side objects that update data.
3. Next wire up interactive behavior to your HTML via data attributes.
4. Finally, enhance the user experience with Stimulus controllers as desired.

## Demo Applications

A list of demo applications built with StimulusReflex.

* [TodoMVC](https://stimulus-reflex-todomvc.herokuapp.com) - An implementation of [TodoMVC](http://todomvc.com/) using [Ruby on Rails](https://rubyonrails.org/), [StimulusJS](https://stimulusjs.org/), and [StimulusReflex](https://github.com/hopsoft/stimulus_reflex)
