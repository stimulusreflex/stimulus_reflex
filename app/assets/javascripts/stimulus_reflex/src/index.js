let cableReadyTimeout;
let defaultRenderDelay = 100;

const connect = () => {
  if (document.querySelector('body[data-cable]')) {
    window.App || (window.App = {});
    App.cable || (App.cable = ActionCable.createConsumer());
    App.stimulusReflex ||
      (App.stimulusReflex = App.cable.subscriptions.create(
        'StimulusReflex::Channel',
        {
          received: data => {
            if (data.cableReady) {
              clearTimeout(cableReadyTimeout);
              cableReadyTimeout = setTimeout(() => {
                CableReady.perform(data.operations);
              }, StimulusReflex.renderDelay || defaultRenderDelay);
            }
          },
        }
      ));
  }
};

document.addEventListener('DOMContentLoaded', connect);
const methods = {
  stimulate() {
    if (!App.stimulusReflex)
      throw "ActionCable connection not established! Don't forget to opt-in with: body[data-cable]";
    clearTimeout(cableReadyTimeout);
    let args = Array.prototype.slice.call(arguments);
    let target = args.shift();
    App.stimulusReflex.send({
      url: location.href,
      target: target,
      args: args,
    });
  },
};

export const register = controller => {
  Object.assign(controller, methods);
  return controller;
};
