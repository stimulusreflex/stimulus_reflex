import { Controller } from 'stimulus';
import ActionCable from 'actioncable';
import { camelize } from 'inflected';
import CableReady from 'cable_ready';

// A reference to the Stimulus application registered with: StimulusReflex.initialize
let stimulusApplication;

// Finds an element based on the passed represention the DOM element's attributes.
// This is the same set of attributes forwared to the serer side reflex.
// SEE: stimulute()
// SEE: StimulusReflex::Channel#broadcast_morph
// SEE: StimulusReflex::Channel#broadcast_error
const findElement = attributes => {
  attributes = attributes || {};
  let elements = [];
  if (attributes.id) {
    elements = document.querySelectorAll(`#${attributes.id}`);
  } else {
    let selectors = [];
    for (const key in attributes) {
      if (key.includes('.')) continue;
      if (key === 'value') continue;
      if (key === 'checked') continue;
      if (key === 'selected') continue;
      if (!attributes.hasOwnProperty(key)) continue;
      selectors.push(`[${key}="${attributes[key]}"]`);
    }
    try {
      elements = document.querySelectorAll(selectors.join(''));
    } catch (error) {
      console.log(
        'StimulusReflex encountered an error identifying the Stimulus element. Consider adding an #id to the element.',
        error,
        attributes
      );
    }
  }

  const element = elements.length === 1 ? elements[0] : null;
  return element;
};

// Extracts attributes from a DOM element
const extractElementAttributes = element => {
  let attrs = Array.prototype.slice.call(element.attributes).reduce((memo, attr) => {
    memo[attr.name] = attr.value;
    return memo;
  }, {});

  attrs.value = element.value;
  attrs.checked = !!element.checked;
  attrs.selected = !!element.selected;
  if (element.tagName.match(/select/i)) {
    if (element.multiple) {
      const checkedOptions = Array.prototype.slice.call(element.querySelectorAll('option:checked'));
      attrs.values = checkedOptions.map(o => o.value);
    } else if (element.selectedIndex > -1) {
      attrs.value = element.options[element.selectedIndex].value;
    }
  }
  return attrs;
};

// Finds the Stimulus controller for the DOM element matching the passed set of DOM element attributes.
// This is the same set of attributes forwared to the serer side reflex.
// SEE: stimulute()
// SEE: StimulusReflex::Channel#broadcast_morph
// SEE: StimulusReflex::Channel#broadcast_error
const findController = (name, element) => {
  if (!element) return null;
  if (!stimulusApplication) return null;
  return stimulusApplication.getControllerForElementAndIdentifier(element, name);
};

// Finds the closest StimulusReflex controller name in the DOM tree
const findStimulusReflexControllerName = element => {
  const controllerNames = element.dataset.controller ? element.dataset.controller.split(' ') : [];
  return controllerNames.reduce((memo, name) => {
    const controller = findController(name, element);
    return memo || (controller && typeof controller.stimulate === 'function') ? name : null;
  }, null);
};

// Invokes a method on a StimulusReflex controller.
const invokeCallback = (name, controller) => {
  if (controller && typeof controller[name] === 'function') controller[name]();
};

const invokeLifecycleCallback = (stage, element) => {
  if (!element) return;
  const stimulusReflexController = findController(findStimulusReflexControllerName(element), element);
  const actions = element.dataset.action ? element.dataset.action.split(' ') : [];
  const [_reflexClassName, reflexMethodName] = (element.dataset.reflex || '').split('#');
  const genericCallbackName = ['before', 'after'].includes(stage)
    ? `${stage}Reflex`
    : `reflex${camelize(stage)}`;
  let reflexCallbackName;
  if (reflexMethodName) {
    reflexCallbackName = ['before', 'after'].includes(stage)
      ? `${stage}${camelize(reflexMethodName)}`
      : `${camelize(reflexMethodName, false)}${camelize(stage)}`;
  }

  setTimeout(() => {
    if (reflexCallbackName) {
      actions.forEach(action => {
        const [_eventName, handler] = action.split('->');
        const [controllerName, _methodName] = handler.split('#');
        const controller = findController(controllerName, element);
        invokeCallback(reflexCallbackName, controller);
      });
    }
    invokeCallback(genericCallbackName, stimulusReflexController);
  }, 1);
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
      const args = Array.prototype.slice.call(arguments);
      const target = args.shift();
      const attrs = extractElementAttributes(this.element);
      const data = { target, args, attrs, url };
      invokeLifecycleCallback('before', this.element);
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
  document.querySelectorAll('[data-reflex]').forEach(element => {
    const controllerNames = element.dataset.controller ? element.dataset.controller.split(' ') : [];
    const controllerName = findStimulusReflexControllerName(element);
    const actionNames = element.dataset.action ? element.dataset.action.split(' ') : [];
    element.dataset.reflex.split(' ').map(reflex => {
      const actionName = `${reflex.split('->')[0]}->stimulus-reflex#__perform`;
      if (!actionNames.includes(actionName)) actionNames.push(actionName);
    });
    if (!controllerName) controllerNames.push('stimulus-reflex');
    element.setAttribute('data-controller', controllerNames.join(' '));
    element.setAttribute('data-action', actionNames.join(' '));
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
    const { attrs } = event.detail.stimulusReflex || {};
    const element = findElement(attrs);
    invokeLifecycleCallback('success', element);
    invokeLifecycleCallback('after', element);
  });
  document.addEventListener('stimulus-reflex:500', event => {
    const { attrs } = event.detail.stimulusReflex || {};
    const element = findElement(attrs);
    invokeLifecycleCallback('error', element);
    invokeLifecycleCallback('after', element);
  });
}

export default { initialize, register };
