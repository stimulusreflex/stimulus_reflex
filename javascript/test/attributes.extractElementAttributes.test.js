import assert from 'assert'
import { JSDOM } from 'jsdom'
import { extractElementAttributes } from '../attributes'

describe('extractElementAttributes', () => {
  it('returns expected attributes for empty anchor', () => {
    const dom = new JSDOM('<a>Test</a>')
    global.document = dom.window.document
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
    global.document = dom.window.document
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
    global.document = dom.window.document
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
    global.document = dom.window.document
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
    global.document = dom.window.document
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
    global.document = dom.window.document
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

  it('returns multiple values for a select', () => {
    const dom = new JSDOM(
      '<select name="my-select" id="my-select"><option value="one">One</option><option value="two" selected>Two</option><option value="three">Three</option></select>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('select')
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'my-select',
      value: 'two',
      values: ['two'],
      name: 'my-select',
      tag_name: 'SELECT',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns multiple values for a multiple select', () => {
    const dom = new JSDOM(
      '<select name="my-select" id="my-select" multiple><option value="one" selected>One</option><option value="two" selected>Two</option><option value="three">Three</option></select>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('select')
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'my-select',
      value: 'one,two',
      values: ['one', 'two'],
      name: 'my-select',
      tag_name: 'SELECT',
      checked: false,
      selected: false,
      multiple: ''
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns multiple values for a checkbox list', () => {
    const dom = new JSDOM(
      '<input type="checkbox" name="my-checkbox-collection" id="my-checkbox-collection-1" value="one" checked><input type="checkbox" name="my-checkbox-collection" id="my-checkbox-collection-2" value="two" checked><input type="checkbox" name="my-checkbox-collection" id="my-checkbox-collection-3 value="three">'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector(
      '#my-checkbox-collection-1'
    )
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'my-checkbox-collection-1',
      value: 'one,two',
      values: ['one', 'two'],
      type: 'checkbox',
      name: 'my-checkbox-collection',
      tag_name: 'INPUT',
      checked: true,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for element with data-reflex-inherit', () => {
    const dom = new JSDOM(
      '<body data-body-id="body"><div data-grandparent-id="456"><div data-parent-id="123"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-inherit>Test</a></div></div></body>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementAttributes(element)
    const expected = {
      id: 'example',
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345',
      'data-grandparent-id': '456',
      'data-parent-id': '123',
      'data-body-id': 'body',
      'data-reflex-inherit': '',
      value: undefined,
      tag_name: 'A',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for element with overloaded data attributes with data-reflex-inherit', () => {
    const dom = new JSDOM(
      '<div data-info="this_is_the_wrong_data-info"><a data-info="this_is_the_right_data-info" data-reflex-inherit>Test</a></div>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementAttributes(element)
    const expected = {
      'data-info': 'this_is_the_right_data-info',
      'data-reflex-inherit': '',
      value: undefined,
      tag_name: 'A',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes with parent attributes only for elements with data-reflex-inherit', () => {
    const dom = new JSDOM(
      '<div data-parent-id="123"><button id="button1" data-reflex-inherit>Something</button><button id="button2">Another thing</button></div>'
    )
    global.document = dom.window.document

    const button1 = dom.window.document.querySelector('#button1')
    const actual_button1 = extractElementAttributes(button1)
    const expected_button1 = {
      id: 'button1',
      'data-parent-id': '123',
      'data-reflex-inherit': '',
      value: '',
      tag_name: 'BUTTON',
      checked: false,
      selected: false
    }

    const button2 = dom.window.document.querySelector('#button2')
    const actual_button2 = extractElementAttributes(button2)
    const expected_button2 = {
      id: 'button2',
      value: '',
      tag_name: 'BUTTON',
      checked: false,
      selected: false
    }

    assert.deepStrictEqual(actual_button1, expected_button1)
    assert.deepStrictEqual(actual_button2, expected_button2)
  })
})
