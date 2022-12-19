import { Controller } from '@hotwired/stimulus'
import StimulusReflex from 'stimulus_reflex'

// This is the Stimulus ApplicationController.
// All StimulusReflex controllers should inherit from this class.
//
// Example:
//
//   import ApplicationController from './application_controller'
//
//   export default class extends ApplicationController { ... }
//
// Learn more at: https://docs.stimulusreflex.com
//

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  // Application-wide lifecycle methods
  //
  // Use these methods to handle lifecycle callbacks for all controllers.
  // Using lifecycle methods is optional, so feel free to delete these if you don't need them.
  //
  // Arguments:
  //
  //   element - the element that triggered the reflex
  //             may be different than the Stimulus controller's this.element
  //
  //   reflex - the name of the reflex e.g. "Example#demo"
  //
  //   error/noop - the error message (for reflexError), otherwise null
  //
  //   id - a UUID4 or developer-provided unique identifier for each Reflex
  //

  beforeReflex (element, reflex, noop, id) {
    // document.body.classList.add('wait')
  }

  reflexQueued (element, reflex, noop, id) {
    // Reflex will be delivered to server upon reconnection
  }

  reflexDelivered (element, reflex, noop, id) {
    // Reflex has been delivered to the server
  }

  reflexSuccess (element, reflex, noop, id) {
    // show success message
  }

  reflexError (element, reflex, error, id) {
    // show error message
  }

  reflexForbidden (element, reflex, noop, id) {
    // Reflex action did not have permission to run
    // window.location = '/'
  }

  reflexHalted (element, reflex, noop, id) {
    // handle aborted Reflex action
  }

  afterReflex (element, reflex, noop, id) {
    // document.body.classList.remove('wait')
  }

  finalizeReflex (element, reflex, noop, id) {
    // all operations have completed, animation etc is now safe
  }
}
