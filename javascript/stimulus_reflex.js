import { Controller } from 'stimulus';
import ActionCable from 'actioncable';
import { camelize } from 'inflected';
import CableReady from 'cable_ready';

// A reference to the Stimulus application registered with: StimulusReflex.initialize
//
let stimulusApplication;

// Extracts attributes from a DOM element.
//
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

// Finds an element based on the passed represention the DOM element's attributes.
//
// NOTE: This is the same set of attributes forwared to the serer side reflex.
// SEE: stimulute()
// SEE: StimulusReflex::Channel#broadcast_morph
// SEE: StimulusReflex::Channel#broadcast_error
//
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

// Invokes a lifecycle method on a controller and its ancestors.
// NOTE: This bubbles up the DOM tree.
//
// - before
// - success
// - error
// - after
//
const invokeLifecycleMethod = (stage, reflex, sourceElement, currentElement) => {
  if (!sourceElement) return;
  if (!currentElement) return;

  const [_, reflexMethodName] = reflex.split('#');
  const controllerNames = currentElement.dataset.controller
    ? currentElement.dataset.controller.split(' ')
    : [];
  const genericCallbackName = ['before', 'after'].includes(stage)
    ? `${stage}Reflex`
    : `reflex${camelize(stage)}`;
  const specificCallbackName = ['before', 'after'].includes(stage)
    ? `${stage}${camelize(reflexMethodName)}`
    : `${camelize(reflexMethodName, false)}${camelize(stage)}`;

  controllerNames.forEach(controllerName => {
    const controller = stimulusApplication.getControllerForElementAndIdentifier(
      currentElement,
      controllerName
    );
    if (controller) {
      if (typeof controller[specificCallbackName] === 'function')
        setTimeout(() => controller[specificCallbackName](sourceElement), 1);
      if (typeof controller[genericCallbackName] === 'function')
        setTimeout(() => controller[genericCallbackName](sourceElement), 1);
    }
  });

  invokeLifecycleMethod(stage, reflex, sourceElement, currentElement.parentElement);
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
// Methods added to the Stimulus controller:
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
      const args = Array.from(arguments);
      const target = args.shift();
      const attrs = extractElementAttributes(this.element);
      const data = { target, args, url, attrs };
      invokeLifecycleMethod('before', target, this.element, this.element);
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

// Sets up declarative reflex behavior.
// Any elements that define data-reflex will automatcially be wired up with the default StimulusReflexController.
//
const setupDeclarativeReflexes = () => {
  document.querySelectorAll('[data-reflex]').forEach(element => {
    const controllerNames = element.dataset.controller ? element.dataset.controller.split(' ') : [];
    const actionNames = element.dataset.action ? element.dataset.action.split(' ') : [];

    if (!controllerNames.includes('stimulus-reflex')) controllerNames.push('stimulus-reflex');
    if (controllerNames.length > 0) element.setAttribute('data-controller', controllerNames.join(' '));

    element.dataset.reflex.split(' ').map(reflex => {
      const actionName = `${reflex.split('->')[0]}->stimulus-reflex#__perform`;
      if (!actionNames.includes(actionName)) actionNames.push(actionName);
    });
    if (actionNames.length > 0) element.setAttribute('data-action', actionNames.join(' '));
  });
};

// Initializes StimulusReflex by registering the default Stimulus controller with the passed Stimulus application.
//
// - application - the Stimulus application
// - controller - [optional] the default StimulusReflexController
//
const initialize = (application, controller = StimulusReflexController) => {
  stimulusApplication = application;
  stimulusApplication.register('stimulus-reflex', controller);
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
  // Trigger success and after lifecycle methods from before-morph to ensure we can find a reference
  // to the source element in case it gets removed from the DOM by morph.
  // This is safe because the server side reflex completed successfully.
  document.addEventListener('cable-ready:before-morph', event => {
    const { target, attrs } = event.detail.stimulusReflex || {};
    const element = findElement(attrs);
    invokeLifecycleMethod('success', target, element, element);
    invokeLifecycleMethod('after', target, element, element);
  });
  document.addEventListener('stimulus-reflex:500', event => {
    const { target, attrs } = event.detail.stimulusReflex || {};
    const element = findElement(attrs);
    invokeLifecycleMethod('error', target, element, element);
    invokeLifecycleMethod('after', target, element, element);
  });
}

export default { initialize, register };
