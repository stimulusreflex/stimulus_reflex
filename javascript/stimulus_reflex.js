import ActionCable from 'actioncable';
import { Application, Controller } from 'stimulus';
import CableReady from 'cable_ready';

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

// Start declarative stimulus/reflex behavior ................................................................
class StimulusReflexController extends Controller {
  connect() {
    register(this);
  }
  perform(event) {
    event.preventDefault();
    event.stopPropagation();
    this.stimulate(this.element.dataset.reflex);
  }
}

const application = Application.start();
application.register('stimulus-reflex', StimulusReflexController);

const init = () => {
  document.querySelectorAll('[data-stimulus][data-reflex]').forEach(el => {
    if (!el.hasAttribute('data-action'))
      el.setAttribute('data-action', `${el.dataset.stimulus}->stimulus-reflex#perform`);
    if (!el.hasAttribute('data-controller')) el.setAttribute('data-controller', `stimulus-reflex`);
  });
};

window.addEventListener('load', init);
document.addEventListener('turbolinks:load', init);
document.addEventListener('cable-ready:after-morph', init);
// End declarative stimulus/reflex behavior ................................................................

export default { register };
