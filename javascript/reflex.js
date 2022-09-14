import Debug from './debug'
import Deprecate from './deprecate'

export default class Reflex {
  constructor (data, controller) {
    this.data = data.valueOf()
    this.controller = controller
    this.element = data.reflexElement
    this.id = data.id
    this.error = null
    this.payload = null
    this.stage = 'created'
    this.lifecycle = ['created']
    this.warned = false
    this.target = data.target
    this.action = data.target.split('#')[1]
    this.selector = null
    this.morph = null
    this.operation = null
    this.timestamp = new Date()
    this.cloned = false // TODO: v4 remove
  }

  get getPromise () {
    const promise = new Promise((resolve, reject) => {
      this.promise = {
        resolve,
        reject,
        data: this.data
      }
    })
    promise.id = this.id
    // TODO: v4 remove
    Object.defineProperty(promise, 'reflexId', {
      get () {
        if (Deprecate.enabled)
          console.warn(
            'reflexId is deprecated and will be removed from v4. Use id instead.'
          )
        return this.id
      }
    })
    // END TODO: v4 remove
    promise.reflex = this
    if (Debug.enabled) promise.catch(() => {})
    return promise
  }
}
