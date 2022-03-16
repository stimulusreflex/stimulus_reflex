import { html, fixture, assert } from '@open-wc/testing'

import { extractElementAttributes } from '../attributes'

describe('extractElementAttributes', () => {
  it('returns expected attributes for empty anchor', async () => {
    const element = await fixture(
      html`
        <a>Test</a>
      `
    )
    const actual = extractElementAttributes(element)
    const expected = {
      value: undefined,
      checked: false,
      selected: false,
      tag_name: 'A'
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for anchor', async () => {
    const element = await fixture(html`
      <a id="example" data-controller="foo" data-reflex="bar" data-info="12345"
        >Test</a
      >
    `)
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

  it('returns expected attributes for textarea', async () => {
    const element = await fixture(
      html`
        <textarea id="example">StimulusReflex</textarea>
      `
    )
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

  it('returns expected attributes for textbox', async () => {
    const element = await fixture(html`
      <input type="text" id="example" value="StimulusReflex" />
    `)
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

  it('returns expected attributes for textbox when multiple inputs with same name', async () => {
    const dom = await fixture(html`
      <div>
        <input
          name="repeated"
          type="text"
          id="another"
          value="StimulusReflex"
        />
        <input
          name="repeated"
          type="text"
          id="example"
          value="StimulusReflex"
        />
      </div>
    `)
    const element = dom.querySelector('input#example')
    const actual = extractElementAttributes(element)
    const expected = {
      type: 'text',
      id: 'example',
      name: 'repeated',
      value: 'StimulusReflex',
      tag_name: 'INPUT',
      checked: false,
      selected: false
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('returns expected attributes for unchecked checkbox', async () => {
    const element = await fixture(
      html`
        <input type="checkbox" id="example" />
      `
    )
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

  it('returns expected attributes for checked checkbox', async () => {
    const element = await fixture(
      html`
        <input type="checkbox" id="example" checked />
      `
    )
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

  it('returns multiple values for a select', async () => {
    const element = await fixture(html`
      <select name="my-select" id="my-select">
        <option value="one">One</option>
        <option value="two" selected>Two</option>
        <option value="three">Three</option>
      </select>
    `)
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

  it('returns multiple values for a multiple select', async () => {
    const element = await fixture(html`
      <select name="my-select" id="my-select" multiple>
        <option value="one" selected>One</option>
        <option value="two" selected>Two</option>
        <option value="three">Three</option>
      </select>
    `)
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

  it('returns multiple values for a checkbox list', async () => {
    const dom = await fixture(html`
      <div>
        <input
          type="checkbox"
          name="my-checkbox-collection"
          id="my-checkbox-collection-3"
          value="three"
        />
        <input
          type="checkbox"
          name="my-checkbox-collection"
          id="my-checkbox-collection-1"
          value="one"
          checked
        />
        <input
          type="checkbox"
          name="my-checkbox-collection"
          id="my-checkbox-collection-2"
          value="two"
          checked
        />
      </div>
    `)

    const element = dom.querySelector('input#my-checkbox-collection-1')
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
})
