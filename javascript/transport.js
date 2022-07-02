let transport = {}

export default {
  get plugin () {
    return transport
  },
  set (newTransport) {
    transport = newTransport
  }
}
