---
description: StimulusReflex rocks because it stands on the shoulders of Stimulus
---

# Working with Events

It's become progressively easier to work with events in a consistent way across all web browsers. There are still gotchas and awkward idiosyncrasies that would make Larry David squirm, but compared to the bad old days of IE6 - long a _nevergreen_ browser default on Windows - there's usually a correct answer to most problems.

The team behind StimulusReflex works hard to make sure that the library has everything it needs to present a favorable alternative to using SPAs. We're also opinionated about what StimulusReflex shouldn't take on, and those decisions reflect some of the biggest differences from other solutions such as [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-key-events).

A big part of the reason we can keep the footprint of StimulusReflex so small without sacrificing functionality is that it is tightly integrated with [Stimulus](https://stimulusjs.org), a lightweight library that provides powerful event handling.

We also draw upon proven libraries such as [Lodash](https://lodash.com) and [debounced](https://github.com/hopsoft/debounced) when necessary to craft flexible solutions to common problems.

## Throttle and Debounce

Some actions with some input devices can trigger enough events in a short period of time that unless you handle them properly, you will massively degrade the performance of your application. Common examples include: moving your mouse, holding down a key on your keyboard, scrolling a webpage and resizing your browser window.

For these use cases, we use a technique known as a **throttle**. A throttle accepts a stream of events and after allowing the first one to execute immediately, it will discard further events until a specified delay has passed.

> If you have a delay of 1000ms and send three events in rapid succession, it will fire the first event, wait one second and then fire the third event.

Other times, you might just want to exercise fine control over exactly when some events are allowed to fire. The most common example is the delayed suggested results you see on sites like Google as you type characters into the search box. Your goal is to hold back events until enough time has passed since the last event has been received.

For these use cases, we can use a technique known as a **debounce**. The classic mental model is holding open the elevator door for people to board. The elevator can't leave until a few seconds after you let go of the button.

Debounce is flexible. In addition to specifying a delay, additional options can indicate whether the first \("_leading_"\) event is fired and whether the last \("_trailing_"\) event is fired. Much like an angry, beeping elevator there is also _maxWait_ to provide the amount of time to wait before an interim event is fired, even if new events are still arriving.

{% hint style="info" %}
LiveView's **debounce** implementation accepts **blur** as a delay value, effectively saying "don't do this until the user leaves this input element".

With Stimulus, we can just define a handler for the **blur** event and keep the concepts separate.
{% endhint %}

While you can find many implementations of throttle and debounce on the web, one of the most commonly used implementations can be found in the [Lodash](https://lodash.com/) library. Lodash has dozens of functions that are flexible, well-tested and optimised. They also __return new functions that you can assign to replace your existing functions.

{% hint style="info" %}
Lodash implementation of **debounce** is so flexible that **throttle** is actually implemented using debounce.
{% endhint %}

If you `yarn add lodash` you will be able to import just the functions you need thanks to a process known as **tree shaking**, where Webpack will only grab the minimum code required, keeping your production JS bundle size tiny. [In order for tree shaking to work, you have to use the following import syntax](https://www.azavea.com/blog/2019/03/07/lessons-on-tree-shaking-lodash/):

```javascript
import debounce from 'lodash/debounce'
```

Tree shaking will not work if you attempt to use `{ debounce }` or forget to specify `'lodash/debounce'` - just `from 'lodash'` will include the entire library.

Let's set up a simple example: we will debounce your page scroll events while keeping your server up-to-date on how far down your user is.

{% tabs %}
{% tab title="scroll\_controller.js" %}
```javascript
import ApplicationController from './application_controller.js'
import debounce from 'lodash/debounce'

export default class extends ApplicationController {
  connect () {
    super.connect()
    this.scroll = debounce(this.scroll, 1000)
    window.addEventListener('scroll', this.scroll, { passive: true })
  }

  disconnect () {
    window.removeEventListener('scroll', this.scroll, { passive: true })
  }

  scroll = () => {
    this.stimulate('Event#scroll', window.scrollY)
  }
}
```
{% endtab %}

{% tab title="event\_reflex.rb" %}
```ruby
class EventReflex < ApplicationReflex
  def scroll(value)
    puts value
  end
end
```
{% endtab %}

{% tab title="index.html.erb" %}
```text
<div data-controller="scroll" style="height: 5000px"></div>
```
{% endtab %}
{% endtabs %}

We can use the [Stimulus Global Events](https://stimulusjs.org/reference/actions#global-events) syntax to map window scroll events to the `scroll` function on a Stimulus controller named `event`. When the controller is attached to the `div` at page load, `connect` is fired, StimulusReflex is instantiated and we use the Lodash `debounce` [function](https://lodash.com/docs/4.17.15#debounce) to return a new event handler that will execute when the page is scrolled _but then stops scrolling for at least a second_. We could set a `maxWait` option if we were worried about users who just won't stop scrolling, but that's as weird as it sounds and qualifies as premature optimisation.

When the handler is executed, we call `stimulate` and pass the current scroll offset of the browser window to the server as an integer argument. The server reflex writes the scroll offset to `STDOUT` or your Rails log file.

We will look at more examples below, but for now just remember that `throttle` with default parameters has the example same form and syntax as `debounce`.

## debounced

Another excellent option for debouncing events is the [debounced](https://github.com/hopsoft/debounced) library, which creates debounced versions of standard bubbling DOM events. It's been designed to pair exceptionally well with Stimulus and StimulusReflex:

```markup
<input type="text" data-reflex="debounced:input->Example#work">
```

You can find all of the details on the debounced GitHub page, but it provides a powerful declared syntax which is the perfect fit for declared Reflexes.

## The Four Horsemen aka Key Events

We're going to quickly cover the four primary key-capture events available to the modern JavaScript developer. While they all have their uses, it's quite likely that you're going to stick to one or two of them.

The _key_ thing to remember is that `keydown` and `keyup` indicate which key is **pressed**, while `keypress` indicates which **character was entered**. A lowercase "a" will be reported as 65 by `keydown` and `keyup`, but as 97 by `keypress`. An uppercase "A" is reported as 65 by all events.

`keydown`, `keypress` and `keyup` can be declared on any receiver including `document`. The `input` event can only be captured for an `input`, `select` or `textarea` HTML element. Choose the right event depending on your needs.

### keydown

The lowest-level key capture events are also the only events that can pick up control characters; if you need to know that they are holding down control or even just holding down `w` to move forward, this is your event.

If you press the Escape key, this is the granularity of data you can obtain:

| key | value |
| :--- | :--- |
| altKey | false |
| charCode | 0 |
| code | "Escape" |
| ctrlKey | false |
| key | "Escape" |
| keyCode | 27 |
| location | 0 |
| metaKey | false |
| repeat | false |
| shiftKey | false |
| which | 27 |

While very useful for game development, it doesn't see a lot of use in normal web development because if you access `event.target.value` it gives you the value of the element \(usually a text box\) **before the key was pressed**. Many developers have lost many hairs trying to hunt down bugs on their `keydown` handlers; don't make the same mistake.

It's common to throttle the rate of events fired when the user holds down a key. In the examples below, we'll look at how to throttle on `keydown` by testing the `repeat` attribute to see if one key is being held down.

### keypress

Similar to `keydown`, `keypress` returns the previous value when you access `event.target.value`. However, it only fires for keys that product a character value, so for example the Escape key is off-limits, as are `Alt`, `Shift`, `Ctrl` and `Meta`.

Here's the event data obtained by pressing `w`one time:

| key | value |
| :--- | :--- |
| altKey | false |
| charCode | 119 |
| code | "KeyW" |
| ctrlKey | false |
| key | "w" |
| keyCode | 119 |
| location | 0 |
| metaKey | false |
| repeat | false |
| shiftKey | false |
| which | 119 |

{% hint style="warning" %}
Note that the `keypress` event is technically deprecated even if it's still widely used.
{% endhint %}

### keyup

While `keyup` is the direct counterpart of `keydown` there are some important differences.

Throttling or debouncing is usually _not_ required as the event doesn't fire until the key has been released.

`event.target.value` returns the value of the text box as it currently appears, with any new changes reflected.

`keyup` will _not_ fire if you paste text into an input element. It doesn't care that anything has changed; it's _only_ aware of keys being pressed.

### input

Introduced in 1999, the new member of the key event family wasn't available in IE until version 9. As IE 9 also doesn't support Websockets, it's as safe to use as ActionCable and by extension, StimulusReflex.

A close cousin of `change` and `blur`, `input` events can be used to manage the state of `input`, `textarea` and `select` elements. `input` is fired every time the `value` of the element changes, including when text is pasted. `change` only fires when the `value` is committed, such as by pressing the enter key or selecting a value from a list of options. `blur` fires when focus is lost, _even if nothing changed_.

Like `keypress`, `input` cannot give you access to non-character keycodes such as Escape. It should not require debounce because the event is not fired until after any change has occurred. You can access `event.target.value` and see the current value of the element.

However, the real power of `input` \(and it's sister event `beforeinput`\) is that they give you **boss powers**: the `data` attribute on the event is a string containing the change made, which could be a single character or a pasted novel. Meanwhile, the `inputType` attribute tells you what kind of change was responsible for the event being fired. With this information, you have the ability to create a timeline log of all changes to a document and even replay them in either direction later.

Getting into the details of how `contenteditable` works is far beyond the scope of this document, but you can find more information on what's possible in the [W3C Input Events spec](https://www.w3.org/TR/input-events-1/#interface-InputEvent-Attributes).

You might also consider checking out [Trix](https://trix-editor.org/), the editor library created by the team behind Rails, Stimulus, Turbo Drive and ActionCable.

## keydown throttle example

First, let's tackle a creative use of `throttle`. We're going to allow the user to mash their keyboard without spamming the server with Reflex updates. However, **we only want to throttle if they are holding down a single key**:

{% tabs %}
{% tab title="event\_controller.js" %}
```javascript
import ApplicationController from './application_controller.js'
import throttle from 'lodash/throttle'

export default class extends ApplicationController {
  connect () {
    super.connect()
    this.throttleKeydown = throttle(this.throttleKeydown, 1000)
  }

  keydown (event) {
    event.repeat
      ? this.throttleKeydown(event)
      : this.stimulate('Event#keydown', event.key)
  }

  throttleKeydown (event) {
    this.stimulate('Event#keydown', event.key)
  }
}
```
{% endtab %}

{% tab title="event\_reflex.rb" %}
```ruby
class EventReflex < ApplicationReflex
  def keydown(key)
    puts key
  end
end
```
{% endtab %}

{% tab title="index.html.erb" %}
```text
<div data-controller="event">
  <input type="text" data-action="keydown->event#keydown">
</div>
```
{% endtab %}
{% endtabs %}

## requestAnimationFrame

Just before we wrap up events, there is a third important mechanism modern browsers provide to control time in our applications, and that is requestAnimationFrame.

If you've ever developed games, simulations or visualisations, chances are that you've worked with render loops. For the rest of us, the idea that we can use JavaScript, WebGL and the HTML canvas/SVG elements to create incredible visual results might seem alien. There are many great starter articles including "[Anatomy of a video game](https://developer.mozilla.org/en-US/docs/Games/Anatomy)" on MDN.

requestAnimationFrame is the mechanism used to control screen draw operations. When paired with keydown and mouse/touch events, complete games with GPU-accelerated graphics are possible. New browser APIs such as [HTML5 Bluetooth](https://developers.google.com/web/updates/2015/07/interact-with-ble-devices-on-the-web) mean that you could use your Xbox controllers.

{% hint style="info" %}
It can be intimidating to start out from nothing with requestAnimationFrame, which is why excellent libraries such as [Greensock](https://greensock.com/) are so popular.

While a paid version is available, you can get amazingly far with the free version, specifically if you check out their [Timeline](https://greensock.com/docs/v3/GSAP/Timeline) primative, which offers an impressive selection of callbacks.

We're living in an era when you can use a high accuracy animation timeline to launch Stimulus controller methods in a way that is scrubbable like a video. That's pretty damn cool.
{% endhint %}

What might come as a surprise is that clever use of StimulusReflex is theoretically fast enough to keep your game state running live on the server while your client is updating at 60fps. We leave this as an exercise for the reader, but please tell us if you achieve cold fusion.

