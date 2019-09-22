import { Controller } from 'stimulus';
import ActionCable from 'actioncable';
import CableReady from 'cable_ready';

// A reference to the Stimulus application registered with: StimulusReflex.initialize
let stimulusApplication;

// Finds an element based on the passed represention the DOM element's attributes.
// This is the same set of attributes forwared to the serer side reflex.
// SEE: stimulute()
// SEE: StimulusReflex::Channel#broadcast_morph
// SEE: StimulusReflex::Channel#broadcast_error
const findElement = attrs => {
  let elements = [];
  if (attrs.id) {
    elements = document.querySelectorAll(`#${attrs.id}`);
  } else {
    let selectors = [];
    for (const key in attrs) {
      if (key.indexOf('.') >= 0) continue;
      if (key === 'value') continue;
      if (key === 'checked') continue;
      if (key === 'selected') continue;
      if (!attrs.hasOwnProperty(key)) continue;
      selectors.push(`[${key}="${attrs[key]}"]`);
    }
    try {
      elements = document.querySelectorAll(selectors.join(''));
    } catch (error) {
      console.log(
        'StimulusReflex encountered an error identifying the Stimulus element. Consider adding an #id to the element.',
        error,
        detail
      );
    }
  }

  const element = elements.length === 1 ? elements[0] : null;
  return element;
};

// Finds the Stimulus controller for the DOM element matching the passed set of DOM element attributes.
// This is the same set of attributes forwared to the serer side reflex.
// SEE: stimulute()
// SEE: StimulusReflex::Channel#broadcast_morph
// SEE: StimulusReflex::Channel#broadcast_error
const findController = attrs => {
  const element = findElement(attrs);
  if (!element) return null;
  if (!element.dataset.controller) return null;
  if (!stimulusApplication) return null;
  return stimulusApplication.getControllerForElementAndIdentifier(element, element.dataset.controller);
};

// Invokes a callback on a StimulusReflex controller.
//
// - reflexStart
// - reflexSuccess
// - reflexError
// - reflexComplete
//
const invokeCallback = (name, controller) => {
  if (controller && typeof controller[name] === 'function') controller[name]();
};

// Subscribes a StimulusReflex controller to an ActionCable channel and room.
//
// controller - the StimulusReflex controller to subscribe
//
const createSubscription = controller => {
  const { channel, room } = controller.StimulusReflex;
  const id = `${channel}${room}`;
  const renderDelay = controller.StimulusReflex.renderDelay || 25;

  const subscription =
    app.StimulusReflex.subscriptions[id] ||
    app.StimulusReflex.consumer.subscriptions.create(
      { channel, room },
      {
        received: data => {
          if (data.cableReady) {
            clearTimeout(controller.StimulusReflex.timeout);
            controller.StimulusReflex.timeout = setTimeout(() => {
              CableReady.perform(data.operations);
            }, renderDelay);
          }
        },
      }
    );

  app.StimulusReflex.subscriptions[id] = subscription;
  controller.StimulusReflex.subscription = subscription;
};

// Extends a regular Stimulus controller with StimulusReflex behavior.
//
// Methods added:
// - stimulate
// - __perform
//
const extendStimulusController = controller => {
  Object.assign(controller, {
    // Invokes a server side reflex method.
    //
    // arguments
    //   first arg: the reflex target (full name of the server side reflex) i.e. 'ReflexClassName#method'
    //   remaining args: any remaining arguments are forwarded to the reflex method
    //
    stimulate() {
      clearTimeout(controller.StimulusReflex.timeout);
      const url = location.href;
      let args = Array.prototype.slice.call(arguments);
      let target = args.shift();
      let attrs = Array.prototype.slice.call(this.element.attributes).reduce((memo, attr) => {
        memo[attr.name] = attr.value;
        return memo;
      }, {});

      attrs.value = this.element.value;
      attrs.checked = !!this.element.checked;
      attrs.selected = !!this.element.selected;
      if (this.element.tagName.match(/select/i)) {
        if (this.element.multiple) {
          const checkedOptions = Array.prototype.slice.call(this.element.querySelectorAll('option:checked'));
          attrs.values = checkedOptions.map(o => o.value);
        } else if (this.element.selectedIndex > -1) {
          attrs.value = this.element.options[this.element.selectedIndex].value;
        }
      }

      const data = { target, args, attrs, url };
      invokeCallback('reflexStart', this);
      controller.StimulusReflex.subscription.send(data);
    },

    // Wraps the call to stimuluate for any data-reflex elements.
    // This is internal and should not be invoked directly.
    __perform(event) {
      event.preventDefault();
      event.stopPropagation();
      this.element.dataset.reflex.split(' ').forEach(reflex => this.stimulate(reflex.split('->')[1]));
    },
  });
};

// Sets up declarative reflex behavior.
// Any elements that define data-reflex will automatcially be wired up with the default StimulusReflexController.
//
const setupDeclarativeReflexes = () => {
  document.querySelectorAll('[data-reflex]').forEach(el => {
    if (String(el.dataset.controller).indexOf('stimulus-reflex') >= 0) return;
    const controllers = el.dataset.controller ? el.dataset.controller.split(' ') : [];
    const actions = el.dataset.action ? el.dataset.action.split(' ') : [];
    controllers.push('stimulus-reflex');
    el.setAttribute('data-controller', controllers.join(' '));
    el.dataset.reflex.split(' ').forEach(reflex => {
      actions.push(`${reflex.split('->')[0]}->stimulus-reflex#__perform`);
    });
    el.setAttribute('data-action', actions.join(' '));
  });
};

// Registers a Stimulus controller and extends it with StimulusReflex behavior
// The room can be specified via a data attribute on the Stimulus controller element i.e. data-room="12345"
//
// controller - the Stimulus controller
// options - [optional] configuration
//   * renderDelay - amount of time to delay before mutating the DOM (adds latency but reduces jitter)
//
const register = (controller, options = {}) => {
  const channel = 'StimulusReflex::Channel';
  const room = controller.element.dataset.room || '';
  controller.StimulusReflex = { ...options, channel, room };
  extendStimulusController(controller);
  createSubscription(controller);
};

// Default StimulusReflexController that is implicitly wired up as data-controller for any DOM elements
// that have configured data-reflex. Note that this default can be overridden when initializing the application.
// i.e. StimulusReflex.initialize(myStimulusApplication, MyCustomDefaultController);
//
class StimulusReflexController extends Controller {
  constructor(...args) {
    super(...args);
    register(this);
  }
}

// Initializes StimulusReflex by registering the default Stimulus controller with the passed Stimulus application.
// application - the Stimulus application
// controller - [optional] the default StimulusReflexController
//
const initialize = (application, controller) => {
  stimulusApplication = application;
  stimulusApplication.register('stimulus-reflex', controller || StimulusReflexController);
};

// Wire everything up
//
const app = window.App || {};
app.StimulusReflex = app.StimulusReflex || {};
app.StimulusReflex.consumer = app.StimulusReflex.consumer || ActionCable.createConsumer();
app.StimulusReflex.subscriptions = app.StimulusReflex.subscriptions || {};

if (!document.stimulusReflexInitialized) {
  document.stimulusReflexInitialized = true;
  window.addEventListener('load', setupDeclarativeReflexes);
  document.addEventListener('turbolinks:load', setupDeclarativeReflexes);
  document.addEventListener('cable-ready:after-morph', setupDeclarativeReflexes);
  document.addEventListener('cable-ready:before-morph', event => {
    if (event.detail.stimulusReflex) {
      let controller = findController(event.detail.stimulusReflex.attrs);
      setTimeout(() => {
        invokeCallback('reflexSuccess', controller);
        invokeCallback('reflexComplete', controller);
      }, 1);
    }
  });
  document.addEventListener('stimulus-reflex:500', event => {
    let controller = findController(event.detail.stimulusReflex.attrs);
    invokeCallback('reflexError', controller);
    invokeCallback('reflexComplete', controller);
  });
}

export default { initialize, register };
