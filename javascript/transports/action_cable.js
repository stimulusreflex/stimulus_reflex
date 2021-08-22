import { createConsumer } from '@rails/actioncable'
import { received } from '../reflexes'
import { emitEvent } from '../utils'

let consumer
let params
let subscriptionActive

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
  emitEvent('stimulus-reflex:connected') // DEPRECATED and will be removed in the future
  emitEvent('stimulus-reflex:action-cable:connected')
}

const rejected = () => {
  subscriptionActive = false
  emitEvent('stimulus-reflex:rejected') // DEPRECATED and will be removed in the future
  emitEvent('stimulus-reflex:action-cable:rejected')
  if (Debug.enabled) console.warn('Channel subscription was rejected.')
}

const disconnected = willAttemptReconnect => {
  subscriptionActive = false
  emitEvent('stimulus-reflex:disconnected', willAttemptReconnect) // DEPRECATED and will be removed in the future
  emitEvent('stimulus-reflex:action-cable:disconnected', willAttemptReconnect)
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
  set (consumerValue, paramsValue) {
    consumer = consumerValue
    params = paramsValue
  }
}
