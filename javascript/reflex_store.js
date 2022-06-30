const states = [
  'created',
  'sent',
  'queued',
  'received',
  'done',
  'error',
  'halted',
  'forbidden'
]
let last

const reflexes = new Proxy(
  {},
  {
    get: function (target, prop) {
      if (states.includes(prop))
        return Object.fromEntries(
          Object.entries(target).filter(([_, reflex]) => reflex.state === prop)
        )
      else if (prop === 'last') return last
      else if (prop === 'all') return target
      return Reflect.get(...arguments)
    },
    set: function (target, prop, value) {
      target[prop] = value
      last = value
      return true
    }
  }
)

export { reflexes }
