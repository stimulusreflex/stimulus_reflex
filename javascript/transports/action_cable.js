import { createConsumer } from '@rails/actioncable'
import { received } from '../reflexes'
import { emitEvent } from '../utils'
import Deprecate from '../deprecate'

let consumer
let params
let subscriptionActive

const initialize = (consumerValue, paramsValue) => {
  consumer = consumerValue
  params = paramsValue
  document.addEventListener('DOMContentLoaded', () => {
    subscriptionActive = false
    connectionStatusClass()
    if (Deprecate.enabled && consumer)
      console.warn(
        "Deprecation warning: the next version of StimulusReflex will obtain a reference to consumer via the Stimulus application object.\nPlease add 'application.consumer = consumer' to your index.js after your Stimulus application has been established, and remove the consumer key from your StimulusReflex initialize() options object."
      )
  })
  document.addEventListener('turbolinks:load', connectionStatusClass)
  document.addEventListener('turbo:load', connectionStatusClass)
}

const createSubscription = controller => {
  consumer = consumer || controller.application.consumer || createConsumer()
  const { channel } = controller.StimulusReflex
  const subscription = { channel, ...params }
  const identifier = JSON.stringify(subscription)

  controller.StimulusReflex.subscription =
    consumer.subscriptions.findAll(identifier)[0] ||
    consumer.subscriptions.create(subscription, {
      received,
      connected,
      rejected,
      disconnected
    })
}

const connected = () => {
  subscriptionActive = true
  connectionStatusClass()
  emitEvent('stimulus-reflex:connected')
  emitEvent('stimulus-reflex:action-cable:connected')
}

const rejected = () => {
  subscriptionActive = false
  connectionStatusClass()
  emitEvent('stimulus-reflex:rejected')
  emitEvent('stimulus-reflex:action-cable:rejected')
  if (Debug.enabled) console.warn('Channel subscription was rejected.')
}

const disconnected = willAttemptReconnect => {
  subscriptionActive = false
  connectionStatusClass()
  emitEvent('stimulus-reflex:disconnected', willAttemptReconnect)
  emitEvent('stimulus-reflex:action-cable:disconnected', willAttemptReconnect)
}

const connectionStatusClass = () => {
  const list = document.body.classList
  if (
    !(
      list.contains('stimulus-reflex-connected') ||
      list.contains('stimulus-reflex-disconnected')
    )
  ) {
    list.add(
      subscriptionActive
        ? 'stimulus-reflex-connected'
        : 'stimulus-reflex-disconnected'
    )
    return
  }
  if (subscriptionActive) {
    list.replace('stimulus-reflex-disconnected', 'stimulus-reflex-connected')
  } else {
    list.replace('stimulus-reflex-connected', 'stimulus-reflex-disconnected')
  }
}

export default {
  consumer,
  params,
  get subscriptionActive () {
    return subscriptionActive
  },
  createSubscription,
  connected,
  rejected,
  disconnected,
  connectionStatusClass,
  initialize
}
