let deprecationWarnings = true

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
  set deprecate (value) {
    deprecationWarnings = !!value
  }
}
