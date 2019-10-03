import assert from 'better-assert'
import * as attrs from '../attributes'

describe('attributeValue', () => {
  it('returns empty string for no arguments', () => {
    assert(attrs.attributeValue() === null)
  })

  it('returns empty string for empty array', () => {
    assert(attrs.attributeValue([]) === null)
  })

  it('returns correct value for array with single value', () => {
    assert(attrs.attributeValue(['example']) === 'example')
  })

  it('returns correct value for array with multiple values', () => {
    assert(attrs.attributeValue(['one', 'two', 'three']) === 'one two three')
  })

  it('returns correct value for array with multiple values that include whitespace', () => {
    assert(
      attrs.attributeValue([' one ', 'two ', 'three ']) === 'one two three'
    )
  })

  it('returns correct value for array with mixed values', () => {
    assert(
      attrs.attributeValue(['one', '', 'two', 'three', null]) ===
        'one two three'
    )
  })
})

describe('attributeValues', () => {
  it('returns empty array for no arguments', () => {
    assert(attrs.attributeValues().length === 0)
  })

  it('returns correct array for single value', () => {
    const list = attrs.attributeValues('one')
    assert(list.length === 1)
    assert(list[0] === 'one')
  })

  it('returns correct array for multiple values', () => {
    const list = attrs.attributeValues('one two three')
    assert(list.length === 3)
    assert(list[0] === 'one')
    assert(list[1] === 'two')
    assert(list[2] === 'three')
  })

  it('returns correct array for multiple values with whitespace padding', () => {
    const list = attrs.attributeValues(' one two   three ')
    assert(list.length === 3)
    assert(list[0] === 'one')
    assert(list[1] === 'two')
    assert(list[2] === 'three')
  })
})

describe('matchingControllerName', () => {
  it('returns correct name for reflex', () => {
    assert(attrs.matchingControllerName('ExampleReflex#work') === 'example')
  })

  it('returns correct name abbreviated for event + reflex', () => {
    assert(attrs.matchingControllerName('Example#work') === 'example')
  })
})
