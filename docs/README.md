---
description: Build reactive applications with the Rails tooling you already know and love.
---

# StimulusReflex

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

## Why StimulusReflex?

**The traditional Rails request/response cycle is a thing of beauty.** Every Rails programmer who came from another development technology remembers the awe and disbelief they felt when they first watched David Heinemeier-Hansson's [original Rails promo video](https://www.youtube.com/watch?v=Gzj723LkRJY).

It didn't seem possible that someone had made web development that easy. It was so productive that it was __fun__. [The gap between it and other technologies was embarrassing](https://www.youtube.com/watch?v=SWEts0rlezA&t=3m23s). It's incredible how many features and aspects of __literally every modern framework__ people take for granted today that all came from the first version of Rails.

And yet, __little by little__, things came undone as web apps got more ambitious. The pursuit of "native" UI speeds led to an ever-growing stack of increasingly complex front-end JavaScript frameworks. Instead of serving a full HTML response, developers gradually rationalized booting their app with an empty page and some JavaScript that would make JSON API requests. We moved the traditional responsibilities of rendering the UI into the client.

Facebook and Google released React and Angular right at the moment when NodeJS was the cool new thing and there were suddenly countless web development bootcamps teaching people that JavaScript frameworks were the new default. **The combination of brand recognition and shameless cash grab made for a perfect storm.** There were fewer and fewer people left to question why our profession decided to trade fun and productive for the insane complexity that comes with maintaining state on the client.

For those who spend their time bikeshedding JS build systems and rebuilding React apps to use "hooks", we have an important Public Service Announcement: **The cost of learning yet another tool/language/framework vs actually spending your finite spare time building something (or with your loved ones, or reading, or sleeping, or making art) is so profoundly large that it is rarely justified.** Nobody will look back from their deathbed and wish that they'd spent more time comparing the use cases of Redux vs. the Context API.

**Frankly, we're angry.** It feels like an entire generation of young developers has been lied to. 95% of the projects that are built with rich JavaScript libraries don't approach the complexity that justifies them. Teams form and argue over which library to use instead of asking if you need a library at all. If you're not a huge company, you probably don't need the specialty tools that huge companies made to solve their huge company problems.

## How Do We Fix This?

We're glad you asked! [Chris McCord](https://twitter.com/chris_mccord), creator of the [Phoenix](http://www.phoenixframework.org/) framework for [Elixir](https://elixir-lang.org/), demonstrated a technology he calls [LiveView](https://github.com/phoenixframework/phoenix_live_view). The [video](https://www.youtube.com/watch?v=8xJzHq8ru0M) managed to capture the same feeling of promise and excitement that made Rails feel so exciting in the early days.

Reality check: Phoenix is awesome. Elixir is awesome. They were made by people who used to be on the Rails core team. There's no question that Elixir hits a sweet spot for people who want Rails-like conventions baked into a functional language running on the Erlang VM. But realistically, __Elixir and Phoenix are niche communities compared to the massive number of Rails developers around the world__.

StimulusReflex started as an interpretation of LiveView for Rails, but today the project is charting its own course. We are proud to say we think it's even easier to build interactive, real-time apps using StimulusReflex with Rails.

## The Sell

With StimulusReflex, **you will ship projects faster, with smaller teams**. Also, you will know the joy of development again. It's a big deal. This is real.

StimulusReflex is designed to work perfectly with the technologies you already know: [server rendered HTML](https://guides.rubyonrails.org/action_view_overview.html), [Russian Doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), [Stimulus](https://stimulusjs.org/) and [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA). We strive to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/). We believe that we can show the world a better way forward.

You will be able to build your ideas using an architecture pattern that is simple but powerful because there is no concept of client state. We provide a full set of lifecycle callbacks to handle edge-case scenarios, but many developers will not need them.

Developers create a set of server-side Reflex actions which mutate your data before your interface is recomputed and the client is updated.

For most applications, the entire end-to-end update cycle takes as little as 50ms.

## Behind the Scenes

Here's what happens whenever a `StimulusReflex::Reflex` is invoked:

1. The page that triggered the reflex is re-rerendered.
2. The re-rendered HTML is sent to the client over the ActionCable socket.
3. The page is updated via fast DOM diffing courtesy of [morphdom](https://github.com/patrick-steele-idem/morphdom).

Since all communication happens via websocket, we can avoid the overhead of traditional HTTP connections. The controller action is invoked directly, skipping framework overhead like the middleware chain. Finally, DOM diffing is used to update the page, provides faster rendering and less jitter. **It's like using a React app that has no client code.**

{% hint style="success" %}
All instance variables created in a Reflex action method are made available to the Rails controller and view.
{% endhint %}

## Example Applications

* [TodoMVC](https://stimulus-reflex-todomvc.herokuapp.com) - An implementation of [TodoMVC](http://todomvc.com/) using [Ruby on Rails](https://rubyonrails.org/), [StimulusJS](https://stimulusjs.org/), and [StimulusReflex](https://github.com/hopsoft/stimulus_reflex)
