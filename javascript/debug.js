let debugging = false

export default {
  get enabled () {
    return debugging
  },
  get disabled () {
    return !debugging
  },
  get value () {
    return debugging
  },
  set (value) {
    debugging = !!value
  },
  set debug (value) {
    debugging = !!value
  }
}
