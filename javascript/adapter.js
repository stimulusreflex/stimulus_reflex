import CableReady from 'cable_ready'

class AbstractConsumerAdapter {
  constructor (consumer) {
    this.consumer = consumer
    if (new.target === AbstractConsumerAdapter) {
      throw new TypeError('Cannot construct an abstract instance directly')
    }
    const methods = [
      // takes an argument identifier
      'find_subscription',
      // takes an argument channel
      'create_subscription',
      'isConnected',
      // takes arguments identifier, data, options
      'send',
      'connect',
      'disconnect'
    ]
    for (const method of methods) {
      if (typeof this[method] === undefined) {
        throw new TypeError(`Must override the method ${method}`)
      }
    }
  }
}

const getAbstractClass = () => {
  return AbstractConsumerAdapter
}

class ActionCableAdapter extends AbstractConsumerAdapter {
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

export { ActionCableAdapter, getAbstractClass }
