let isolationMode = false

export default {
  get disabled () {
    return !isolationMode
  },
  set (value) {
    isolationMode = value
  }
}
