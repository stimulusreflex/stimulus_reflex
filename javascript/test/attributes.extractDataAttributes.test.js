import { html, fixture, assert } from '@open-wc/testing'

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

  it('returns empty object for an element without attributes', async () => {
    const element = await fixture(
      html`
        <div>Test</div>
      `
    )
    const actual = extractDataAttributes(element)
    const expected = {}
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected data attributes for an element', async () => {
    const element = await fixture(html`
      <div
        id="example"
        class="should not appear"
        data-controller="foo"
        data-reflex="bar"
        data-info="12345"
      >
        Test
      </div>
    `)
    const actual = extractDataAttributes(element)
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345'
    }
    assert.deepStrictEqual(actual, expected)
  })
})
