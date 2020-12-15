---
description: Build reactive applications with the Rails tooling you already know and love
---

# Welcome

## What is StimulusReflex?

**StimulusReflex is a new way to craft modern, reactive web interfaces with Ruby on Rails.**

We extend the capabilities of both [Rails](https://rubyonrails.org) and [Stimulus](https://stimulusjs.org) by intercepting user interactions and passing them to Rails over real-time websockets. These interactions are processed by _Reflex actions_ that change application state. The current page is quickly re-rendered and the changes are sent to the client using [CableReady](https://cableready.stimulusreflex.com). The page is then [morphed](https://github.com/patrick-steele-idem/morphdom) to reflect the new application state. This entire round-trip allows us to update the UI in 20-30ms without flicker or expensive page loads.

This architecture eliminates the complexity imposed by full-stack frontend frameworks without abandoning [high-performance reactive user experiences](https://www.youtube.com/watch?v=SWEts0rlezA&t=214s). With StimulusReflex, small teams can do big things faster than ever before. We invite you to explore **a fresh alternative to the Single Page App** \(SPA\).

{% hint style="success" %}
**Get Involved.** We are stronger together! Please join us on [Discord.![](https://img.shields.io/discord/629472241427415060)](https://discord.gg/XveN625)

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)
{% endhint %}

## New \(PRE\)Release: v3.4 - Developer Happiness Edition

#### NOTE: This beta documentation for the pre-release of v3.4. All of the new features below are only accessible if you are helping us test.

Developer happiness is not a catch-phrase. We are actively working to improve the quality of life for the more than [12,000](https://www.npmjs.com/package/stimulus_reflex) people downloading StimulusReflex every week, because happy developers enjoy a [great surplus](https://www.youtube.com/watch?v=4PVViBjukAE).

As with all major StimulusReflex releases, v3.4 is [packed full of new features](https://github.com/hopsoft/stimulus_reflex/blob/master/CHANGELOG.md) from 52 contributors that are directly inspired by the questions, requests and grievances of the 800+ people on the [SR Discord](https://discord.gg/XveN625):

* we completely overhauled the [client-side Reflex logging](troubleshooting.md#client-side-logging) with per-Morph granularity
* a brand new and shockingly customizable [server-side Reflex](troubleshooting.md#stimulusreflex-logging) **colorized logging** module
* a new `finalize` [life-cycle stage](lifecycle.md#client-side-reflex-callbacks) that occurs after all DOM mutations are complete
* support for lazily evaluated [signed and unsigned](reflexes.md#signed-and-unsigned-global-id-accessors) Global ID to model instances
* a special `cable_ready` method that [automatically broadcasts](reflexes.md#using-cableready-inside-a-reflex-action) to the current user
* speaking of CableReady, the new v4.4 means operation and broadcast **method chaining**
* an optional \(but recommended\) "[tab isolation](reflexes.md#tab-isolation)" mode to restrict Reflexes to the current tab
* major improvements behind the scenes to better handle \(many\) concurrent Reflex actions
* `render` is now automatically delegated to the current page's controller
* StimulusReflex library configuration courtesy of our new [initializer](setup.md#upgrading-package-versions-and-sanity) system
* opt-in Rack middleware support for Page Morphs
* automatic support for mirroring DOM events with [jQuery events](lifecycle.md#jquery-events-1), if jQuery is present
* drop-in [Stimulus 2](https://github.com/stimulusjs/stimulus/releases/tag/v2.0.0) support
* warnings to alert you if your caching is off or your gem+npm versions [don't match](setup.md#upgrading-package-versions-and-sanity)
* JS [bundle size](https://bundlephobia.com/result?p=stimulus_reflex@3.4.0-pre7) drops from 43kb to **11.1kb** - _including_ CableReady, morphdom and ActionCable

More than anything, StimulusReflex v3.4 feels fast and incredibly solid. We didn't take any shortcuts when it came to killing bugs and doing things right. We owe that to our users as we use our surplus to build the world we want to live in, together. 🌲

### Upgrading to v3.4.0

* make sure that you update `stimulus_reflex` **both** your Gemfile and package.json
* it's **very important** to remove any `include CableReady::Broadcaster` statements from your Reflex classes
* you can enable [isolation mode](reflexes.md#tab-isolation) by adding `isolate: true` to the initialize options
* you can generate an initializer with `rails g stimulus_reflex:config`

## Morphs

v3.3 introduced the concept of **Morphs** to StimulusReflex.

{% embed url="https://www.youtube.com/watch?v=utxCm3uLhIE" caption="" %}

**Page** Morphs provide a full-page [morphdom](https://github.com/patrick-steele-idem/morphdom) refresh with controller processing as an intelligent default.

**Selector** Morphs allow you to intelligently update target elements in your DOM, provided by regenerated partials or [ViewComponents](https://github.com/github/view_component).

**Nothing** Morphs provide a lightning-fast RPC mechanism to launch ActiveJobs, initiate CableReady broadcasts, call APIs and emit signals to external processes.

There's a [handy chart](https://app.lucidchart.com/documents/view/e83d2cac-d2b1-4a05-8a2f-d55ea5e40bc9/0_0) showing how the different Morphs work. Find all of the documentation and examples behind the link below.

{% page-ref page="morph-modes.md" %}

## Why should I use StimulusReflex?

Wouldn't it be great if you could **focus on your product** instead of the technical noise introduced by modern JavaScript? With StimulusReflex, you'll **ship projects faster, with smaller teams** and re-discover the joy of programming.

### Goals

* [x] Enable small teams to do big things, faster 🏃🏽‍♀️
* [x] Increase developer happiness ❤️❤️❤️
* [x] Facilitate simple, concise, and clear code 🤸
* [x] Integrate seamlessly with Ruby on Rails 🚝

## Faster UIs, smaller downloads and longer battery life

Our over-the-wire JavaScript payload size is a tiny [**11.1kb** gzipped](https://bundlephobia.com/result?p=stimulus_reflex@3.4.0-pre7)... and that _includes_ StimulusReflex, ActionCable, morphdom and CableReady.

While StimulusReflex is a radically different approach that makes it hard to do a direct comparison to the popular SPA frameworks, the one thing everyone seems to agree on is how small their Todo List implementation is. Here's the numbers:

| Tool | Wire Size |
| :--- | :--- |
| [StimulusReflex](http://expo.stimulusreflex.com/demos/todo/) | **54kb** |
| [React](http://todomvc.com/examples/react/) | 268kb |
| [Angular](http://todomvc.com/examples/angularjs/) | 290kb |
| [Vue](http://todomvc.com/examples/vue/) | 78kb |
| [Ember](http://todomvc.com/examples/emberjs/) | 169kb |

Not everyone has the latest iPhone in their pocket. We're delivering HTML to the client, which every device can display without a framework rendering a UI from JSON. We reduce complexity for developers while making it easier for people with slower connections and less-powerful devices to access your site without draining their battery.

## Live demo

[StimulusReflex Expo](http://expo.stimulusreflex.com/) is a growing collection of like examples showing different use-cases alongside the [source code](https://github.com/hopsoft/stimulus_reflex_expo) behind them.

Some of our favorite demos include:

* [Tabular](https://expo.stimulusreflex.com/demos/tabular): filtering, sorting and pagination without any client JavaScript
* [Todo](https://expo.stimulusreflex.com/demos/todo): our take on the [classic](http://todomvc.com/), with a wire size 2-15x smaller than every other solution

## Build the next Twitter in just 9 minutes \(or less\) 😉

{% embed url="https://www.youtube.com/watch?v=F5hA79vKE\_E" caption="" %}

## First-class ViewComponent support

When you have [ViewComponent ](https://github.com/github/view_component)installed in your project, you can use [componentized views](https://www.youtube.com/watch?v=YVYRus_2KZM) in your Reflexes **without any configuration required**. 💯

If you install the amazing [ViewComponentReflex](https://github.com/joshleblanc/view_component_reflex) as well, you will be able to persist the state of your components into the user's session. Every instance of your components will maintain their own local state. This provides seamless continuity for your UI - even when doing full-page Reflex updates. _Hand, meet glove._ 🖐️+🧤

Some things just have to be seen: check out the [ViewComponentReflex Expo](http://view-component-reflex-expo.grep.sh/) for live demos.

## How we got here

**We love Rails.** Veterans of the framework remember the feeling of awe and disbelief after seeing David Heinemeier Hansson's [Build a Blog in 15 minutes](https://www.youtube.com/watch?v=Gzj723LkRJY) video. It didn't seem possible that web development could be so easy, productive, and fun. We're talking [exponential gains in developer efficiency](https://www.youtube.com/watch?v=SWEts0rlezA&t=3m23s) and happiness. Rails has become so successful that nearly every framework since has borrowed ideas, patterns, and features from it.

The landscape has changed a lot since those early days. Applications are more ambitious now. The pursuit of native UI speeds spawned a new breed of increasingly complex technologies. Modern **Single Page Apps** have pushed many of the server's responsibilities to the client. Unfortunately this new approach trades _a developer experience_ that was once **fun and productive** for an alternative of high complexity and only marginal gains.

**There must be a better way.**

## The revolution begins

In his 2018 ElixirConf keynote, [Chris McCord](https://twitter.com/chris_mccord) _\(creator of the_ [_Phoenix_](http://www.phoenixframework.org/) _framework for_ [_Elixir_](https://elixir-lang.org/)_\)_ introduced [LiveView](https://github.com/phoenixframework/phoenix_live_view), an alternative to the SPA. His [presentation](https://www.youtube.com/watch?v=8xJzHq8ru0M) captures the same promise and excitement that Rails had in the early days.

We love Elixir and Phoenix. Elixir hits a sweet spot for people who want Rails-like conventions in a functional language. The community is terrific, but it's still small and comparatively niche.

Also, we just really enjoy using **Ruby and Rails**.

StimulusReflex was originally inspired by LiveView, but we are charting our own course. Our goal has always been to make building modern apps with Rails the most productive and enjoyable option available. We want to inspire our friends working with other tools and technologies to evaluate how concepts like StimulusReflex could work in their ecosystems and communities.

So far, it's working! Not only do we now have 20+ developers actively contributing to StimulusReflex, but we've inspired projects like [SockPuppet](https://github.com/jonathan-s/django-sockpuppet) for **Django**.

We are truly stronger together.

