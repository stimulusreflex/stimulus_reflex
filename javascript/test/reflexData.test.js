import { fixture, html, expect, assert } from '@open-wc/testing'

import ReflexData from '../reflex_data'
import Schema, { defaultSchema } from '../schema'

Schema.set(defaultSchema)

describe('ReflexData', () => {
  it('returns an array of selectors', () => {
    assert.deepStrictEqual(new ReflexData({ selectors: '#an-id' }).selectors, [
      '#an-id'
    ])

    assert.deepStrictEqual(
      new ReflexData({ selectors: ['.item', 'li'] }).selectors,
      ['.item', 'li']
    )
  })

  it("attaches the element's innerHTML if includeInnerHTML is true", async () => {
    const element = await fixture(
      html`
        <div>
          <ul>
            <li>First</li>
            <li>Last</li>
          </ul>
        </div>
      `
    )

    assert.equal(
      new ReflexData(
        { includeInnerHTML: true },
        element,
        element
      ).innerHTML.replace(/\s+/g, ''),
      '<ul><li>First</li><li>Last</li></ul>'
    )
  })

  it("attaches the element's innerHTML if includeInnerHTML is declared on the reflexElement", async () => {
    const element = await fixture(
      html`
        <div data-reflex-include-inner-html>
          <ul>
            <li>First</li>
            <li>Last</li>
          </ul>
        </div>
      `
    )

    assert.equal(
      new ReflexData({}, element, element).innerHTML.replace(/\s+/g, ''),
      '<ul><li>First</li><li>Last</li></ul>'
    )
  })

  it("doesn't attach the element's innerHTML if includeInnerHTML is falsey", async () => {
    const element = await fixture(
      html`
        <div>
          <ul>
            <li>First</li>
            <li>Last</li>
          </ul>
        </div>
      `
    )

    assert.equal(new ReflexData({}, element, element).innerHTML, '')
  })

  it("attaches the element's textContent if includeTextContent is true", async () => {
    const element = await fixture(
      html`
        <div>
          <p>Some Text <a>with a link</a></p>
        </div>
      `
    )

    assert.equal(
      new ReflexData({ includeTextContent: true }, element, element).textContent
        .replace(/\s+/g, ' ')
        .trim(),
      'Some Text with a link'
    )
  })

  it("attaches the element's textContent if includeTextContent is declared on the reflex element", async () => {
    const element = await fixture(
      html`
        <div data-reflex-include-text-content>
          <p>Some Text <a>with a link</a></p>
        </div>
      `
    )

    assert.equal(
      new ReflexData({}, element, element).textContent
        .replace(/\s+/g, ' ')
        .trim(),
      'Some Text with a link'
    )
  })

  it("doesn't attach the element's textContent if includeTextContent is falsey", async () => {
    const element = await fixture(
      html`
        <div>
          <p>Some Text <a>with a link</a></p>
        </div>
      `
    )

    assert.equal(new ReflexData({}, element, element).textContent, '')
  })

  it('preserves multiple values from a checkbox list', async () => {
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

    const element = document.querySelector('#my-checkbox-collection-1')

    assert.equal(new ReflexData({}, element, element).attrs.value, 'one,two')
    assert.deepStrictEqual(new ReflexData({}, element, element).attrs.values, [
      'one',
      'two'
    ])
  })
})
