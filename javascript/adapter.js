import CableReady from 'cable_ready'
import './vendor/message-bus'
import './vendor/message-bus-ajax'

class ConsumerAdapter {
  constructor () {}

  find_subscription (identifier) {
    throw Error('Not implemented')
  }

  create_subscription (channel) {
    throw Error('Not implemented')
  }

  isConnected () {
    throw Error('Not implemented')
  }

  send (identifier, data, options = {}) {
    throw Error('Not implemented')
  }

  connect () {
    throw Error('Not implemented')
  }

  disconnect () {
    throw Error('Not implemented')
  }
}

class MessageBusAdapter extends ConsumerAdapter {
  constructor () {
    super()

    this.subscriptions = {}
  }

  find_subscription (identifier) {
    this.subscriptions[identifier]
  }

  create_subscription (channel) {
    MessageBus.subscribe('/channel', function (data) {
      data = JSON.parse(data)
      if (data.operations.morph && data.operations.morph.length) {
        const urls = Array.from(
          new Set(data.operations.morph.map(m => m.stimulusReflex.url))
        )
        if (urls.length !== 1 || urls[0] !== location.href) return
      }
      CableReady.perform(data.operations)
    })
  }

  isConnected () {
    return MessageBus.status() === 'started'
  }

  send (identifier, data, options = {}) {
    fetch('/stimulus_reflex/receive', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-StimulusReflex-Identifier': identifier
      },
      body: JSON.stringify(data)
    })
  }

  connect () {
    MessageBus.start()
  }

  disconnect () {
    MessageBus.stop()
  }
}

class ActionCableAdapter extends ConsumerAdapter {
  constructor (consumer) {
    super()
    this.consumer = consumer
  }

  find_subscription (identifier) {
    return this.consumer.subscriptions.findAll(identifier)[0]
  }

  create_subscription (channel) {
    this.consumer.subscriptions.create(channel, {
      received: data => {
        if (!data.cableReady) return
        if (data.operations.morph && data.operations.morph.length) {
          const urls = Array.from(
            new Set(data.operations.morph.map(m => m.stimulusReflex.url))
          )
          if (urls.length !== 1 || urls[0] !== location.href) return
        }
        CableReady.perform(data.operations)
      }
    })
  }

  connect () {
    return this.consumer.connection.open()
  }

  disconnect () {
    return this.consumer.connection.close({ allowReconnect: false })
  }

  isConnected () {
    return this.consumer.connection.isOpen()
  }

  send (identifier, data, options = {}) {
    let subscription = this.find_subscription(identifier)
    subscription.send(data)
  }
}

export { MessageBusAdapter, ConsumerAdapter, ActionCableAdapter }
