import { Controller } from 'stimulus';

export default class extends Controller {
  connect() {
    this.constructor.register(this);
  }

  perform(event) {
    event.preventDefault();
    event.stopPropagation();
    this.element.dataset.reflex.split(' ').forEach(reflex => this.stimulate(reflex.split('->')[1]));
  }
}
