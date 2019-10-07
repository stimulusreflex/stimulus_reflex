---
description: Build reactive applications with the Rails tooling you already know and love.
---

# Welcome

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

## Rails: A Little History

**We love Rails.** Most Rails veterans remember the feeling of awe and disbelief after watching David Heinemeier-Hansson's [Build a Blog in 15 minutes](https://www.youtube.com/watch?v=Gzj723LkRJY) video. It didn't seem possible that web development could be so easy, productive, and fun. We're talking [exponential gains in developer efficiency](https://www.youtube.com/watch?v=SWEts0rlezA&t=3m23s) and happiness. Rails has been so successful that almost every modern framework in use today has borrowed ideas, patterns, and features from it.

The landscape has changed a lot since those early days. Applications have become more ambitious. The pursuit of native UI speeds has spawned a new breed of increasingly complex technologies. The introduction of **Single Page Apps** has delegated many of the server's responsibilities to the client. But it's starting to feel like we've traded **fun and productive** for colossal complexity... and only marginal gains. The harsh reality is that many developers aren't even aware of the tradeoffs.

**There has to be a better way.**

## Phoenix LiveView: A New Hope

In his 2018 ElixirConf keynote, [Chris McCord](https://twitter.com/chris_mccord) _\(creator of the_ [_Phoenix_](http://www.phoenixframework.org/) _framework for_ [_Elixir_](https://elixir-lang.org/)_\)_ introduced a technology called [LiveView](https://github.com/phoenixframework/phoenix_live_view). His [presentation](https://www.youtube.com/watch?v=8xJzHq8ru0M) captures some of the same promise and excitement that Rails had in the early days.

We love Elixir and Phoenix. There's no question that Elixir hits a sweet spot for people who want Rails-like conventions in a functional language that runs on the Erlang VM. The Elixir and Phoenix community is terrific, but it's still small and somewhat niche.

Also, we still **love Ruby and Rails**. 

StimulusReflex was originally inspired by LiveView, but we are charting our own course. We hope to make building real-time apps with Rails and StimulusReflex the most productive and enjoyable option available.

## StimulusReflex: Real-Time Benefits

**You will ship projects faster, with smaller teams** and re-discover the joy of programming. It's a big deal and it's real.

StimulusReflex is designed to work perfectly with the Rails technologies you already know... like [server rendered HTML](https://guides.rubyonrails.org/action_view_overview.html), [Russian Doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), [Stimulus](https://stimulusjs.org/) and [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA). We strive to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/) and hope to show a better way of building modern web applications.

We welcome everyone... from junior to gray beard. Come with us and learn how StimulusReflex can help you **focus on product** instead of periphery.

### Overview: How it's Done

1. Build a typical Rails app with the elegant simplicity of server rendered HTML.
2. Then create small server side Reflex objects to update data.
3. Next, wire up interactive behavior to your HTML via data attributes.
4. Finally, optionally enhance the user experience with Stimulus controllers as desired.

## Demo Applications

A list of demo applications built with StimulusReflex that you can try live right now.

* [StimulusReflex TodoMVC](http://todomvc.stimulusreflex.com) - An implementation of [TodoMVC](http://todomvc.com/) using Ruby on Rails and StimulusReflex.

