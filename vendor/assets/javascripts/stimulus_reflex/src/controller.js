import debounce from 'lodash.debounce';
import App from './cable';

const debouncedSend = debounce(options => App.stimulus.send(options), 250, {});

export const Methods = {
  send() {
    let args = Array.prototype.slice.call(arguments);
    let target = args.shift();
    debouncedSend({
      url: location.href,
      target: target,
      args: args,
    });
  }
}
