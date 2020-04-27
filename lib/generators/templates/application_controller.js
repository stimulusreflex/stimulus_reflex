import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

/* This is your application's ApplicationController.
 * All StimulusReflex controllers should inherit from this class.
 *
 * Example:
 *
 *   import ApplicationController from './application_controller'
 *
 *   export default class extends ApplicationController { ... }
 *
 * Learn more at: https://docs.stimulusreflex.com
 */
export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  /* Application wide lifecycle methods.
   * Use these methods to handle lifecycle concerns for the entire application.
   * Using the lifecycle is optional, so feel free to delete these stubs if you don't need them.
   *
   * Arguments:
   *
   *   element - the element that triggered the reflex
   *             may be different than the Stimulus controller's this.element
   *
   *   reflex - the name of the reflex e.g. "ExampleReflex#demo"
   *
   *   error - error message from the server
   */

  beforeReflex (element, reflex) {
    // document.body.classList.add('wait')
  }

  reflexSuccess (element, reflex, error) {
    // show success message etc...
  }

  reflexError (element, reflex, error) {
    // show error message etc...
  }

  afterReflex (element, reflex) {
    // document.body.classList.remove('wait')
  }
}
