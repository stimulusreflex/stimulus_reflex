import ActionCable from 'actioncable';
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
      let attrs = Array.prototype.slice.call(this.element.attributes).reduce((memo = {}, attribute) => {
        memo[attribute.name] = attribute.value;
        return memo;
      });

      if (this.element.hasOwnProperty('value')) attrs.value = this.element.value;
      if (this.element.hasOwnProperty('checked')) attrs.checked = this.element.checked;
      if (this.element.tagName === 'SELECT' && this.element.selectedIndex > -1) {
        if (this.element.multiple) {
          // TODO: handle multiple selected values? set attrs.values as an array?
        } else {
          attrs.value = this.element.options[this.element.selectedIndex].value;
        }
      }

      controller.StimulusReflex.subscription.send({ target, args, attrs, url });
    },
  });
};

export default {
  //
  // Registers a Stimulus controller and extends it with StimulusReflex behavior
  // The room can be specified via a data attribute on the Stimulus controller element i.e. data-room="12345"
  //
  // controller - the Stimulus controller
  // options - optional configuration
  //   * renderDelay - amount of time to delay before mutating the DOM (adds latency but reduces jitter)
  //
  register: (controller, options = {}) => {
    const channel = 'StimulusReflex::Channel';
    const room = controller.element.dataset.room || '';
    controller.StimulusReflex = { ...options, channel, room };
    createSubscription(controller);
    extend(controller);
  },
};
