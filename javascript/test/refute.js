import { assert } from 'vitest'

export default value => {
  return assert(!value)
}
