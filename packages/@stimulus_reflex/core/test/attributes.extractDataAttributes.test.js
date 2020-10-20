import assert from 'assert'
import { JSDOM } from 'jsdom'
import { extractDataAttributes } from '../attributes'

describe('extractDataAttributes', () => {
  it('returns empty object for null', () => {
    const actual = extractDataAttributes(null)
    const expected = {}
    assert.deepStrictEqual(actual, expected)
  })

  it('returns empty object for undefined', () => {
    const actual = extractDataAttributes(undefined)
    const expected = {}
    assert.deepStrictEqual(actual, expected)
  })

  it('returns empty object for empty object', () => {
    const actual = extractDataAttributes({})
    const expected = {}
    assert.deepStrictEqual(actual, expected)
  })

  it('returns empty object for an element without attributes', () => {
    const dom = new JSDOM('<div>Test</div>')
    global.document = dom.window.document
    const element = dom.window.document.querySelector('div')
    const actual = extractDataAttributes(element)
    const expected = {}
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected data attributes for an element', () => {
    const dom = new JSDOM(
      '<div id="example" class="should not appear" data-controller="foo" data-reflex="bar" data-info="12345">Test</div>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('div')
    const actual = extractDataAttributes(element)
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345'
    }
    assert.deepStrictEqual(actual, expected)
  })
})
