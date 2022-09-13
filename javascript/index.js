export * from './stimulus_reflex'

import * as StimulusReflex from './stimulus_reflex'

import Debug from './debug'
import Deprecate from './deprecate'

import packageInfo from '../package.json'

const global = {
  version: packageInfo.version,
  ...StimulusReflex,
  get debug () {
    return Debug.value
  },
  set debug (value) {
    Debug.set(!!value)
  },
  get deprecate () {
    return Deprecate.value
  },
  set deprecate (value) {
    Deprecate.set(!!value)
  }
}

window.StimulusReflex = global

export default global
