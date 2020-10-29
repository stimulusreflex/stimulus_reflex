# `@stimulus_reflex/polyfills`

The `@stimulus_reflex/polyfills` package provides support for StimulusReflex and CableReady in older browsers like Internet Explorer 11.

This package contains a few polyfills and bundles polyfills from other packages. See below for details:

### `@stimulus_reflex/polyfills`

* Custom
  * [`NodeList.forEach()`](https://developer.mozilla.org/en-US/docs/Web/API/NodeList/forEach#Polyfill)
  * [`CustomEvent`](https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#Polyfill)

* [core-js](https://www.npmjs.com/package/core-js)
  * `Array.forEach()`
  * `Array.includes()`
  * `String.startsWith()`
  * `String.includes()`

### `@stimulus/polyfills`

* [core-js](https://www.npmjs.com/package/core-js)
  * `Array.find()`
  * `Array.findIndex()`
  * `Array.from()`
  * `Map`
  * `Object.assign()`
  * `Promise`
  * `Set`
* [element-closest](https://www.npmjs.com/package/element-closest)
  * `Element.closest()`
* [mutation-observer-inner-html-shim](https://www.npmjs.com/package/mutation-observer-inner-html-shim)
  * `MutationObserver` support for Internet Explorer 11
* [eventlistener-polyfill](https://github.com/github/eventlistener-polyfill)
  * once & passive support for Internet Explorer 11 & Edge


### `@webcomponents/template`
* [`<template>`](https://www.npmjs.com/package/@webcomponents/template)

### `formdata-polyfill`
* [`FormData`](https://www.npmjs.com/package/formdata-polyfill)
