import assert from 'better-assert'
import { attributeValue, matchingControllerName } from '../attributes'

describe('attributeValue', () => {
  it('should return empty string when no arguments passed', () => {
    assert(attributeValue() === null)
  })

  it('should return empty string when empty array passed', () => {
    assert(attributeValue([]) === null)
  })

  it('should return correct value when array with single value passed', () => {
    assert(attributeValue(['example']) === 'example')
  })

  it('should return correct value when array with multiple values passed', () => {
    assert(attributeValue(['one', 'two', 'three']) === 'one two three')
  })

  it('should return correct value when array with mixed values passed', () => {
    assert(
      attributeValue(['one', '', 'two', 'three', null]) === 'one two three'
    )
  })
})

describe('matchingControllerName', () => {
  it('should return correct name for reflex', () => {
    assert(matchingControllerName('ExampleReflex#work') === 'example')
  })

  it('should return correct name abbreviated for event + reflex', () => {
    assert(matchingControllerName('Example#work') === 'example')
  })
})
