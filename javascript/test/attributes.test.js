import assert from 'better-assert'
import { matchingControllerName } from '../attributes'

describe('matchingControllerName', () => {
  it('should return correct name for reflex', () => {
    assert(matchingControllerName('ExampleReflex#work') === 'example')
  })

  it('should return correct name abbreviated for event + reflex', () => {
    assert(matchingControllerName('Example#work') === 'example')
  })
})
