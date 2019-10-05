import assert from 'assert'
import refute from './refute'
import { attributeValue } from '../attributes'

describe('attributeValue', () => {
  it('returns falsey for no arguments', () => {
    refute(attributeValue())
  })

  it('returns falsey for empty array', () => {
    refute(attributeValue([]))
  })

  it('returns expected attribute value for array with single value', () => {
    assert(attributeValue(['example']) === 'example')
  })

  it('returns expected attribute value for array with multiple values', () => {
    assert(attributeValue(['one', 'two', 'three']) === 'one two three')
  })

  it('returns expected attribute value for array with multiple values that include whitespace', () => {
    assert(attributeValue([' one ', 'two ', 'three ']) === 'one two three')
  })

  it('returns expected attribute value for array with mixed values', () => {
    assert(
      attributeValue(['one', '', 'two', 'three', null]) === 'one two three'
    )
  })
})
