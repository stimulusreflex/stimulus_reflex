import CableReady from 'cable_ready'

class ConsumerAdapter {
  constructor (consumer) {
    this.consumer = consumer
  }

  find_subscriptions (identifier) {
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

class ActionCableAdapter extends ConsumerAdapter {
  constructor (consumer) {
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

export { ActionCableAdapter, ConsumerAdapter }
