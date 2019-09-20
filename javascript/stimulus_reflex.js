import ActionCable from 'actioncable';
import CableReady from 'cable_ready';
import StimulusReflexController from './stimulus_reflex_controller';
import { dispatch } from './helpers';

let stimulusApplication;
const app = window.App || {};
app.StimulusReflex = app.StimulusReflex || {};
app.StimulusReflex.consumer = app.StimulusReflex.consumer || ActionCable.createConsumer();
app.StimulusReflex.subscriptions = app.StimulusReflex.subscriptions || {};

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

const extend = controller => {
  Object.assign(controller, {
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

      controller.StimulusReflex.subscription.send({ target, args, attrs, url });
    },
  });
};

// Sets up implicit declarative reflex behavior
const setup = () => {
  document.querySelectorAll('[data-reflex]').forEach(el => {
    if (String(el.dataset.controller).indexOf('stimulus-reflex') >= 0) return;
    const controllers = el.dataset.controller ? el.dataset.controller.split(' ') : [];
    const actions = el.dataset.action ? el.dataset.action.split(' ') : [];
    controllers.push('stimulus-reflex');
    el.setAttribute('data-controller', controllers.join(' '));
    el.dataset.reflex.split(' ').forEach(reflex => {
      actions.push(`${reflex.split('->')[0]}->stimulus-reflex#perform`);
    });
    el.setAttribute('data-action', actions.join(' '));
  });
};

// Initializes StimulusReflex by registering the default Stimulus controller
// with the passed Stimulus application
const initialize = (application, controller) => {
  stimulusApplication = application;
  stimulusApplication.register('stimulus-reflex', controller || StimulusReflexController);
};

// Registers a Stimulus controller and extends it with StimulusReflex behavior
// The room can be specified via a data attribute on the Stimulus controller element i.e. data-room="12345"
//
// controller - the Stimulus controller
// options - optional configuration
//   * renderDelay - amount of time to delay before mutating the DOM (adds latency but reduces jitter)
//
const register = (controller, options = {}) => {
  const channel = 'StimulusReflex::Channel';
  const room = controller.element.dataset.room || '';
  controller.StimulusReflex = { ...options, channel, room };
  createSubscription(controller);
  extend(controller);
};

StimulusReflexController.register = register;

if (!document.stimulusReflexInitialized) {
  document.stimulusReflexInitialized = true;
  window.addEventListener('load', setup);
  document.addEventListener('turbolinks:load', setup);
  document.addEventListener('cable-ready:after-morph', event => {
    setup();
    if (event.detail.stimulusReflex)
      dispatch('stimulus-reflex:success', event.detail.stimulusReflex, stimulusApplication);
  });
  document.addEventListener('stimulus-reflex:500', event => {
    dispatch('stimulus-reflex:error', event.detail.stimulusReflex, stimulusApplication);
  });

  // document.addEventListener('stimulus-reflex:success', event => {
  //   const controller = event.stimulusController;
  //   debugger;
  // });

  // document.addEventListener('stimulus-reflex:error', event => {
  //   const controller = event.stimulusController;
  //   debugger;
  // });
}

export default { initialize, register };
