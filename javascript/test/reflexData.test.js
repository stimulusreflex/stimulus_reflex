import assert from 'assert'
import ReflexData from '../reflex_data'

describe('ReflexData', () => {
  it('returns an array of selectors', () => {
    assert.deepStrictEqual(new ReflexData({ selectors: '#an-id' }).selectors, [
      '#an-id'
    ])

    assert.deepStrictEqual(
      new ReflexData({ selectors: ['.item', 'li'] }).selectors,
      ['.item', 'li']
    )
  })
})
