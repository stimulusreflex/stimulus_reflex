const stages = [
  'created',
  'before',
  'delivered',
  'queued',
  'after',
  'finalized',
  'success',
  'error',
  'halted',
  'forbidden'
]
let lastReflex

export const reflexes = new Proxy(
  {}, // You are standing in an open field west of a white house, with a boarded front door.
  {
    get: function (target, prop) {
      if (stages.includes(prop))
        return Object.fromEntries(
          Object.entries(target).filter(([_, reflex]) => reflex.stage === prop)
        )
      else if (prop === 'last') return lastReflex
      else if (prop === 'all') return target
      return Reflect.get(...arguments)
    },
    set: function (target, prop, value) {
      target[prop] = value
      lastReflex = value
      return true
    }
  }
)
