import Debug from './debug'

export default class Reflex {
  constructor (data, controller) {
    this.data = data.valueOf()
    // TODO do we even need controller in v4?
    this.controller = controller
    this.reflexId = data.reflexId
    this.finalStage = 'finalize'
    this.error = null
    this.state = 'created'
  }

  get getPromise () {
    const promise = new Promise((resolve, reject) => {
      this.promise = {
        resolve,
        reject,
        data: this.data
      }
    })
    promise.reflexId = this.reflexId
    if (Debug.enabled) promise.catch(() => {})
    return promise
  }
}
