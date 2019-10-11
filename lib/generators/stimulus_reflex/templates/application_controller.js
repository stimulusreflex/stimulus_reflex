import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  beforeReflex (element, reflex) {
    // do stuff
  }

  afterReflex (element, reflex) {
    // do stuff
  }

  reflexError (element, reflex, error) {
    // do stuff
  }

  reflexSuccess (element, reflex, error) {
    // do stuff
  }
}
