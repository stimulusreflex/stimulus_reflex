import assert from 'assert'
import { JSDOM } from 'jsdom'
import { extractElementAttributes } from '../attributes'

describe('extractElementAttributes', () => {
  it('returns expected attributes for empty anchor', () => {
    const dom = new JSDOM('<a>Test</a>')
    const element = dom.window.document.querySelector('a')
    const actual = extractElementAttributes(element)
    const expected = {
      value: undefined,
      checked: false,
      selected: false,
      tag_name: 'A'
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for anchor', () => {
    const dom = new JSDOM(
      '<a id="example" data-controller="foo" data-reflex="bar" data-info="12345">Test</a>'
    )
    const element = dom.window.document.querySelector('a')
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'example',
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345',
      value: undefined,
      tag_name: 'A',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for textarea', () => {
    const dom = new JSDOM('<textarea id="example">StimulusReflex</textarea>')
    const element = dom.window.document.querySelector('textarea')
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'example',
      value: 'StimulusReflex',
      tag_name: 'TEXTAREA',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for textbox', () => {
    const dom = new JSDOM(
      '<input type="text" id="example" value="StimulusReflex" />'
    )
    const element = dom.window.document.querySelector('input')
    const actual = extractElementAttributes(element)
    const expected = {
      type: 'text',
      id: 'example',
      value: 'StimulusReflex',
      tag_name: 'INPUT',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for unchecked checkbox', () => {
    const dom = new JSDOM('<input type="checkbox" id="example" />')
    const element = dom.window.document.querySelector('input')
    const actual = extractElementAttributes(element)
    const expected = {
      type: 'checkbox',
      id: 'example',
      value: 'on',
      tag_name: 'INPUT',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for checked checkbox', () => {
    const dom = new JSDOM('<input type="checkbox" id="example" checked />')
    const element = dom.window.document.querySelector('input')
    const actual = extractElementAttributes(element)
    const expected = {
      type: 'checkbox',
      id: 'example',
      value: 'on',
      tag_name: 'INPUT',
      checked: true,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns multiple values for a multiple select', () => {
    const dom = new JSDOM(
      '<select name="my-select" id="my-select" multiple><option value="one" selected>One</option><option value="two" selected>Two</option><option value="three">Three</option></select>'
    )
    const element = dom.window.document.querySelector('select')
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'my-select',
      values: ['one', 'two'],
      // value: "one",
      name: 'my-select',
      tag_name: 'SELECT',
      checked: false,
      selected: false,
      multiple: ''
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns multiple values for a multiple select', () => {
    const dom = new JSDOM(
      '<input type="checkbox" checked>'
    )
    const element = dom.window.document.querySelector('select')
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'my-select',
      values: ['one', 'two'],
      // value: "one",
      name: 'my-select',
      tag_name: 'SELECT',
      checked: false,
      selected: false,
      multiple: ''
    }
    assert.deepStrictEqual(actual, expected)
  })
})
