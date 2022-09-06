import { assert } from '@open-wc/testing'
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
    assert.equal(attributeValue(['example']), 'example')
  })

  it('returns expected attribute value for array with multiple values', () => {
    assert.equal(attributeValue(['one', 'two', 'three']), 'one two three')
  })

  it('returns expected attribute value for array with multiple values that include whitespace', () => {
    assert.equal(attributeValue([' one ', 'two ', 'three ']), 'one two three')
  })

  it('returns expected attribute value for array with mixed values', () => {
    assert.equal(
      attributeValue(['one', '', 'two', 'three', null]),
      'one two three'
    )
  })

  it('returns expected attribute value for array with mixed and duplicate values', () => {
    assert.equal(
      attributeValue([
        'one',
        '',
        'two',
        'three',
        null,
        'two',
        '',
        'three',
        'one',
        null
      ]),
      'one two three'
    )
  })
})
