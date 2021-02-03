let deprecationWarnings = false

export default {
  get enabled () {
    return deprecationWarnings
  },
  get disabled () {
    return !deprecationWarnings
  },
  get value () {
    return deprecationWarnings
  },
  set (value) {
    deprecationWarnings = !!value
  },
  set debug (value) {
    deprecationWarnings = !!value
  }
}
