import debounce from 'lodash.debounce';

window.App = window.App || {};
App.cable = App.cable || ActionCable.createConsumer();
App.stimulusReflex = App.stimulusReflex || App.cable.subscriptions.create("StimulusReflex::Channel", {
  received: data => {
    if (data.cableReady) debouncedPerform(data.operations);
  }
});

const debouncedSend = debounce(options => App.stimulusReflex.send(options), 250, {});

const debouncedPerform = debounce(operations => {
  CableReady.perform(operations);
  document.dispatchEvent(new Event('turbolinks:load'));
}, 200, {});

const methods = {
  send() {
    let args = Array.prototype.slice.call(arguments);
    let target = args.shift();
    debouncedSend({
      url: location.href,
      target: target,
      args: args,
    });
  }
};

export const register = controller => {
  Object.assign(controller, methods);
  return controller;
};
