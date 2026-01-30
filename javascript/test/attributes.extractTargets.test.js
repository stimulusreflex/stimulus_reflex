import { html, fixture, assert } from '@open-wc/testing'

import { extractTargets } from '../attributes'
import Schema, { defaultSchema } from '../schema'

Schema.set(defaultSchema)

describe('extractTargets', () => {
  it('should extract no targets by default', async () => {
    const dom = await fixture(
      html`<div data-reflex-target="post">Post</div>`
    )
    const targets = extractTargets(undefined, null)
    assert.deepStrictEqual(targets, {})
  })

  it('should extract multiple targets from page', async () => {
    const dom = await fixture(
      html`
          <div data-reflex-target="post">Post</div>
          <div data-reflex-target="comment" class="comment-1">Comment 1</div>
          <div data-reflex-target="comment" class="comment-2">Comment 2</div>
      `
    )
    const targets = extractTargets("page", null)

    assert.equal(targets["post"][0]["name"], "post")
    assert.equal(targets["post"][0]["selector"], "/html/body/div[1]/div[1]")
    assert.equal(targets["post"][0]["attrs"]["data-reflex-target"], "post")

    assert.equal(targets["comment"][0]["name"], "comment")
    assert.equal(targets["comment"][0]["selector"], "/html/body/div[1]/div[2]")
    assert.equal(targets["comment"][0]["attrs"]["data-reflex-target"], "comment")
    assert.equal(targets["comment"][0]["attrs"]["class"], "comment-1")

    assert.equal(targets["comment"][1]["name"], "comment")
    assert.equal(targets["comment"][1]["selector"], "/html/body/div[1]/div[3]")
    assert.equal(targets["comment"][1]["attrs"]["data-reflex-target"], "comment")
    assert.equal(targets["comment"][1]["attrs"]["class"], "comment-2")
  })

  it('should limit targets to parent controller if specified', async () => {
    const controller = await fixture( // Note: fixture() returns the first element in the DOM
      html`
          <div data-controller="test">
              <div data-reflex-target="included">In</div>
          </div>
          <div data-reflex-target="not_included">Out</div>
      `
    )

    const targets = extractTargets("controller", controller)

    assert.equal(targets["included"][0]["name"], "included")
    assert.equal(targets["included"][0]["selector"], "/html/body/div[1]/div[1]/div[1]")
    assert.equal(targets["not_included"], undefined)
  })
})
