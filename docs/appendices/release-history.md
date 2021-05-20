# Release History

## New Release: v3.4.1

While this was primarily a bug-fix release, there were some exciting leaps forward, especially on the CableReady side. You should check out the new [graft](https://cableready.stimulusreflex.com/reference/operations/dom-mutations#graft) operation, which seems dry until you realize that you can **move elements on your DOM without losing the internal state of your Stimulus controllers**.

* CableReady v4.5.0 has eight [new operations](https://cableready.stimulusreflex.com/reference/operations): `append`, `graft`, `prepend`, `replace`, `replace_state`, `play_sound`, `go` and `scroll_into_view`
* special Reflex `cable_ready` method now works with [custom operations](https://cableready.stimulusreflex.com/customization#custom-operations)
* responsibility for a Reflex has been moved to the [element holding the controller](../rtfm/reflexes.md#understanding-stimulusreflex-controllers)
* life-cycle callbacks now return the correct element reference
* fixed an issue with form data serialization for characters like `&` and `=`
* fixed `dom_id` which now correctly [prefixes](../rtfm/morph-modes.md#dom_id) with a `#` character
* addressed issue with `morphdom` which interfered with input/select elements losing their value

For those of you who were tired of getting endless warnings about missing controllers when deleting elements via a Reflex, we're thrilled with the way Reflex controller responsibility is now managed.

## v3.4 - Developer Happiness Edition

Developer happiness is not a catch-phrase. We are actively working to improve the quality of life for the more than [13,000](https://www.npmjs.com/package/stimulus_reflex) people downloading StimulusReflex every week, because happy developers enjoy a [great surplus](https://www.youtube.com/watch?v=4PVViBjukAE).

As with all major StimulusReflex releases, v3.4 is [packed full of new features](https://github.com/stimulusreflex/stimulus_reflex/blob/master/CHANGELOG.md) from 52 contributors that are directly inspired by the questions, requests and grievances of the 1000+ people on the [SR Discord](https://discord.gg/stimulus-reflex):

* we completely overhauled the [client-side Reflex logging](troubleshooting.md#client-side-logging) with per-Morph granularity
* a brand new and shockingly customizable [server-side Reflex](troubleshooting.md#stimulusreflex-logging) **colorized logging** module
* a new `finalize` [life-cycle stage](../rtfm/lifecycle.md#client-side-reflex-callbacks) that occurs after all DOM mutations are complete
* support for lazily evaluated [signed and unsigned](../rtfm/reflexes.md#signed-and-unsigned-global-id-accessors) Global ID to model instances
* a special `cable_ready` method that [automatically broadcasts](../rtfm/reflexes.md#using-cableready-inside-a-reflex-action) to the current user
* speaking of CableReady, the new v4.4 means operation and broadcast **method chaining** as well as customizable should/did morph callbacks
* an optional \(but recommended\) "[tab isolation](../rtfm/reflexes.md#tab-isolation)" mode to restrict Reflexes to the current tab
* major improvements behind the scenes to better handle \(many\) concurrent Reflex actions
* `render` is now automatically delegated to the current page's controller
* StimulusReflex library configuration courtesy of our new [initializer](../hello-world/setup.md#upgrading-package-versions-and-sanity) system
* opt-in Rack middleware support for Page Morphs
* automatic support for mirroring DOM events with [jQuery events](../rtfm/lifecycle.md#jquery-events-1), if jQuery is present
* drop-in [Stimulus 2](https://github.com/stimulusjs/stimulus/releases/tag/v2.0.0) support
* warnings to alert you if your caching is off or your gem+npm versions [don't match](../hello-world/setup.md#upgrading-package-versions-and-sanity)
* JS [bundle size](https://bundlephobia.com/result?p=stimulus_reflex@3.4.0) drops from 43kb to **11.4kb** - _including_ CableReady, morphdom and ActionCable

More than anything, StimulusReflex v3.4 feels fast and incredibly solid. We didn't take any shortcuts when it came to killing bugs and doing things right. We owe that to our users as we use our surplus to build the world we want to live in, together. 🌲

### Upgrading to v3.4.0

* make sure that you update `stimulus_reflex` in **both** your Gemfile and package.json
* it's **very important** to remove any `include CableReady::Broadcaster` statements from your Reflex classes
* OPTIONAL: enable [isolation mode](../rtfm/reflexes.md#tab-isolation) by adding `isolate: true` to the initialize options
* OPTIONAL: generate an initializer with `rails g stimulus_reflex:config`
* OPTIONAL: `bundle remove cable_ready && yarn remove cable_ready`

## v3.3 Morphs

Introduces the concept of **Morphs** to StimulusReflex.

{% embed url="https://www.youtube.com/watch?v=utxCm3uLhIE" caption="" %}

**Page** Morphs provide a full-page [morphdom](https://github.com/patrick-steele-idem/morphdom) refresh with controller processing as an intelligent default.

**Selector** Morphs allow you to intelligently update target elements in your DOM, provided by regenerated partials or [ViewComponents](https://github.com/github/view_component).

**Nothing** Morphs provide a lightning-fast RPC mechanism to launch ActiveJobs, initiate CableReady broadcasts, call APIs and emit signals to external processes.

There's a [handy chart](https://app.lucidchart.com/documents/view/e83d2cac-d2b1-4a05-8a2f-d55ea5e40bc9/0_0) showing how the different Morphs work. Find all of the documentation and examples behind the link below.

{% page-ref page="../rtfm/morph-modes.md" %}

