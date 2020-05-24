import assert from 'assert'
import { JSDOM } from 'jsdom'
import { extractElementDataset } from '../attributes'

describe('extractElementDataset', () => {
  it('returns expected dataset for element without data attributes', () => {
    const dom = new JSDOM('<a id="example">Test</a>')
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset')
    const expected = {}
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected dataset for element', () => {
    const dom = new JSDOM(
      '<a id="example" data-controller="foo" data-reflex="bar" data-info="12345">Test</a>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset')
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345'
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected dataset for element without combining dataset from parent', () => {
    const dom = new JSDOM(
      '<div data-parent-id="should not be included"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345">Test</a></div>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset')
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345'
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected dataset for element but without providing the dataset attribute', () => {
    const dom = new JSDOM(
      '<div data-parent-id="should not be included"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345">Test</a></div>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345'
    }
    assert.deepStrictEqual(extractElementDataset(element), expected)
    assert.deepStrictEqual(extractElementDataset(element, null), expected)
    assert.deepStrictEqual(extractElementDataset(element, undefined), expected)
    assert.deepStrictEqual(extractElementDataset(element, ''), expected)
    assert.deepStrictEqual(extractElementDataset(element, 'blah'), expected)
    assert.deepStrictEqual(extractElementDataset(element, {}), expected)
  })

  it('returns expected dataset for element with data-reflex-dataset without value', () => {
    const dom = new JSDOM(
      '<div data-parent-id="should not be included"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset>Test</a></div>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset')
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345',
      'data-reflex-dataset': ''
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected dataset for element with data-reflex-dataset and other value than "combined"', () => {
    const dom = new JSDOM(
      '<div data-parent-id="should not be included"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset="whut">Test</a></div>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset')
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345',
      'data-reflex-dataset': 'whut'
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected dataset for element with data-reflex-dataset="combined"', () => {
    const dom = new JSDOM(
      '<body data-body-id="body"><div data-grandparent-id="456"><div data-parent-id="123"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset="combined">Test</a></div></div></body>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset')
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345',
      'data-grandparent-id': '456',
      'data-parent-id': '123',
      'data-body-id': 'body',
      'data-reflex-dataset': 'combined'
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected dataset for element with overloaded data attributes', () => {
    const dom = new JSDOM(
      '<div data-info="this is the wrong one"><a data-info="this is the right one" data-reflex-dataset="combined">Test</a></div>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset')
    const expected = {
      'data-info': 'this is the right one',
      'data-reflex-dataset': 'combined'
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected dataset with combined parent attributes only for elements with data-reflex-dataset', () => {
    const dom = new JSDOM(
      '<div data-parent-id="123"><button id="button1" data-reflex-dataset="combined">Something</button><button id="button2">Another thing</button></div>'
    )
    global.document = dom.window.document

    const button1 = dom.window.document.querySelector('#button1')
    const actual_button1 = extractElementDataset(button1, 'data-reflex-dataset')
    const expected_button1 = {
      'data-parent-id': '123',
      'data-reflex-dataset': 'combined'
    }

    const button2 = dom.window.document.querySelector('#button2')
    const actual_button2 = extractElementDataset(button2)
    const expected_button2 = {}

    assert.deepStrictEqual(actual_button1, expected_button1)
    assert.deepStrictEqual(actual_button2, expected_button2)
  })

  it('returns expected dataset for element with different renamed data-reflex-dataset attribute', () => {
    const dom = new JSDOM(
      '<body data-body-id="body"><div data-grandparent-id="456"><div data-parent-id="123"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset-renamed="combined">Test</a></div></div></body>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element, 'data-reflex-dataset-renamed')
    const expected = {
      'data-controller': 'foo',
      'data-reflex': 'bar',
      'data-info': '12345',
      'data-grandparent-id': '456',
      'data-parent-id': '123',
      'data-body-id': 'body',
      'data-reflex-dataset-renamed': 'combined'
    }
    assert.deepStrictEqual(actual, expected)
  })
})
