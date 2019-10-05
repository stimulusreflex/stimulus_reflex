import assert from 'assert'
import { matchingControllerName } from '../controllers'

describe('matchingControllerName', () => {
  it('returns expected controller name for reflex', () => {
    assert(matchingControllerName('ExampleReflex#work') === 'example')
  })

  it('returns expected controller name abbreviated for event + reflex', () => {
    assert(matchingControllerName('Example#work') === 'example')
  })
})
