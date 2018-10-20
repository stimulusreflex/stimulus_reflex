import debounce from 'lodash.debounce';
import App from './cable';

const debouncedPerform = debounce(operations => {
  CableReady.perform(operations);
  document.dispatchEvent(new Event('turbolinks:load'));
}, 200, {});

if (window.useStimulusChannel) {
  App.stimulus = App.stimulus || App.cable.subscriptions.create("StimulusReflex::Channel", {
    connected: function() {
      console.log("stimulus channel is connected");
    },

    disconnected: function() {
      console.log("stimulus channel disconnected");
    },

    received: function(data) {
      console.log("data recieved", data);
      if (data.cableReady) debouncedPerform(data.operations);
    }
  });
}
