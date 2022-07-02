let transport = {}

export default {
  get mode () {
    return transport
  },
  set (newTransport) {
    transport = newTransport
  }
}
