import Deprecate from './deprecate'

let isolationMode = false

export default {
  get disabled () {
    return !isolationMode
  },
  set (value) {
    isolationMode = value
    if (Deprecate.enabled && !isolationMode) {
      document.addEventListener(
        'DOMContentLoaded',
        () =>
          console.warn(
            'Deprecation warning: the next version of StimulusReflex will standardize isolation mode, and the isolate option will be removed.\nPlease update your applications to assume that every tab will be isolated. Use CableReady operations to broadcast updates to other tabs and users.'
          ),
        { once: true }
      )
    }
  }
}
