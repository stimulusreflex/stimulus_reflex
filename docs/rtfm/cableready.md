# Integrating CableReady

[CableReady](https://cableready.stimulusreflex.com/) is the primary dependency of StimulusReflex, and it actually pre-dates this library by a year. What is it, and why should you care enough to watch [this video](https://gorails.com/episodes/how-to-use-cable-ready?autoplay=1&ck_subscriber_id=646293602)?

| Library | Responsibility |
| :--- | :--- |
| StimulusReflex | Translates user actions into server-side events that change your data, then regenerating your page based on this new data **into an HTML string**. |
| CableReady | Takes the HTML string from StimulusReflex and sends it to the browser before using [morphdom](https://github.com/patrick-steele-idem/morphdom/) to update only the parts of your DOM that changed. |

⬆️ StimulusReflex is for **sending** commands. 📡  
⬇️ CableReady is for **receiving** updates. 👽

{% hint style="info" %}
A Reflex action is a reaction to a user action that changes server-side state and re-renders the current page \(or a subset of the current page\) for that particular user in the background, provided that they are still on the same page.

A CableReady method is a reaction to some server-side code \(which must be imperatively called\) that makes some change for some set of users in the background.
{% endhint %}

CableReady has 33 operations for changing every aspect of your page, and you can define your own. It can emit events, set cookies, make you breakfast and call your parents \(Twilio fees are not included.\)

{% embed url="https://www.youtube.com/watch?v=dPzv2qsj5L8" caption="" %}

StimulusReflex uses CableReady's `morph` for Page Morphs and some Selector Morphs, `inner_html` for Selector Morphs that don't use `morph` , and `dispatch_event` for Nothing Morphs, as well as aborted/halted Reflexes and sending errors that occur in a Reflex action.

The reason some Selector morphs are sent via `inner_html` is that the content you send to replace your existing DOM elements has to match up. If you replace an element with something completely different, `morph` just won't work. You can read all about this in the [Morphing Sanity Checklist](../appendices/troubleshooting.md#morphing-sanity-checklist).

### Using CableReady inside a Reflex action

It's common for developers to use CableReady inside a Reflex action for all sorts of things, especially initiating client-side events which can be picked up by Stimulus controllers. Another pattern is to use Nothing Morphs that call CableReady operations.

Inside of a Reflex class, `CableReady::Broadcaster` is **already included**, giving you access to the `dom_id` helper and a special version of the `cable_ready` method. If you call `cable_ready` in a Reflex action without specifying a stream or resource - in other words, **no brackets** - CableReady will piggyback on the StimulusReflex ActionCable channel.

This means **you can automatically target the current user**, and if you're _only_ ever targeting the current user, you don't need to set up a channel for CableReady at all.

```ruby
class ExampleReflex < ApplicationReflex
  def foo
    cable_ready.console_log(message: "Cable Ready rocks!").broadcast
    morph :nothing
  end
end
```

This is just like calling `cable_ready[stream_name]`. `stream_name` is the internal variable StimulusReflex uses to hold the stream identifier it uses to send updates to the current user.

The only constaint imposed upon use of the special `cable_ready` method is that **`broadcast` methods must appear at the end of a method chain.** This is because calling `cable_ready.broadcast` without queueing any additional operations already has a function when using CableReady; it tells CableReady to broadcast any enqueued operations on all string-based identifier channels.

You can still use CableReady "normally" inside of a Reflex, if you need to broadcast to more than just the current user. Just call `cable_ready` with a stream identifier in brackets.

{% hint style="danger" %}
Do not include `CableReady::Broadcaster` in your Reflex classes. It's already present in the Reflex scope and including it again will cause errors.
{% endhint %}

### When to use a StimulusReflex `morph` vs. a CableReady operation

Since StimulusReflex uses CableReady's `morph` and `inner_html` operations, you might be wondering when or if to just use CableReady operations directly instead of calling StimulusReflex's `morph`.

The simple answer is that you should use StimulusReflex when you need life-cycle management; callbacks, events and promises. Reflexes have a transactional life-cycle, where each one is assigned a UUID and the client will have the opportunity to respond if something goes wrong.

CableReady operations raise their own events, but StimulusReflex won't know if they are successful or not. Any CableReady operations you broadcast in a Reflex will be executed immediately.

### Order of operations

You can control the order in which CableReady and StimulusReflex operations execute in the client through strategic use \(and non-use\) of `broadcast`.

1. CableReady operations that are `broadcast`ed
2. StimulusReflex `morph` operations
3. CableReady operations that haven't been `broadcast`ed

CableReady operations that have `broadcast` called on them well be immediately delivered to the client, while any CableReady operations queued in a Page or Selector Morph Reflex action that aren't broadcast by the end of the action will be broadcast along with the StimulusReflex-specific `morph` operations. The StimulusReflex operations execute first, followed by any remaining CableReady operations.

{% hint style="warning" %}
If you have CableReady operations that haven't been broadcasted followed by another set of operations that do get broadcasted... the former group of operations will go out with the latter. If you want some operations to be sent with the StimulusReflex operations, make sure that they occur after any calls to `broadcast`.
{% endhint %}

One clever example use of advanced CableReady+StimulusReflex operation ordering is `CableReady#push_state`. There are scenarios where you might want to update your page and then change the URL. If you attempt to change the URL of the page during the Reflex action, the StimulusReflex `morph` updates will be unsuccessful due to the URL changing. StimulusReflex won't execute if the page has changed since the beginning of the Reflex.

By calling `push_state` without actually calling `broadcast`, this ensures that the Reflex page updates can occur before `push_state` changes the URL.

### With great power...

It's important to plan your use of CableReady operations that manipulate the DOM, in terms of timing and eliminating side-effects.

CableReady operations that are broadcasted from a Reflex action will be processed by the client before the Reflex action finishes executing. This means that if you change the DOM in a Page Morph Reflex, it will appear as though your change didn't work when in reality, it was overwritten by the Reflex a few milliseconds later. For this reason, it's rare to see CableReady used in Page Morph Reflex actions. Instead, you should **send the HTML that you want to see**, the first time, so that there's no need to update anything. After all, you can always use client-side callbacks to embellish your UI after a Reflex completes.

The concern is different with a Selector Morph. As discussed above, it's fine to use CableReady operations alongside StimulusReflex `morph` method calls, especially to take advantage of functions not supported directly by StimulusReflex, such as CableReady's `insert_adjacent_html` .

However, you must take responsibility for ensuring that your CableReady operations do not erase, move, or otherwise disturb the DOM above the element which invoked the Reflex action. While StimulusReflex will do everything it can to locate the Stimulus controller attached to the Reflex, if the controller can't be located - or no longer exists - then the life-cycle callbacks will not execute.

This is because StimulusReflex needs to be able to locate the Stimulus controller which initiated the Reflex, and it expects it to be in the same place in your DOM hierarchy that it was when the Reflex started.

{% hint style="info" %}
Keeping your DOM hierarchy consistent through the lifetime of a Reflex is critically important when using StimulusReflex with isolation mode disabled.
{% endhint %}

### radiolabel

If you're making extensive use of StimulusReflex `morph` and CableReady operations, you might consider installing [radiolabel](https://github.com/leastbad/radiolabel). It's a powerful visual aid that allows you to see your CableReady operations happen.

