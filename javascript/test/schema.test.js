import { fixture, html, expect, assert } from '@open-wc/testing'

import ReflexData from '../reflex_data'
import Schema, { defaultSchema } from '../schema'

const schemaOne = {
  reflexAttribute: 'data-reflex-one',
  reflexPermanentAttribute: 'data-reflex-permanent-one',
  reflexRootAttribute: 'data-reflex-root-one',
  reflexSuppressLoggingAttribute: 'data-reflex-suppress-logging-one',
  reflexDatasetAttribute: 'data-reflex-dataset-one',
  reflexDatasetAllAttribute: 'data-reflex-dataset-all-one',
  reflexSerializeFormAttribute: 'data-reflex-serialize-form-one',
  reflexFormSelectorAttribute: 'data-reflex-form-selector-one',
  reflexIncludeInnerHtmlAttribute: 'data-reflex-include-inner-html-one',
  reflexIncludeTextContentAttribute: 'data-reflex-include-text-content-one'
}

const schemaTwo = {
  reflexAttribute: 'data-reflex-two',
  reflexPermanentAttribute: 'data-reflex-permanent-two',
  reflexRootAttribute: 'data-reflex-root-two',
  reflexSuppressLoggingAttribute: 'data-reflex-suppress-logging-two',
  reflexDatasetAttribute: 'data-reflex-dataset-two',
  reflexDatasetAllAttribute: 'data-reflex-dataset-all-two',
  reflexSerializeFormAttribute: 'data-reflex-serialize-form-two',
  reflexFormSelectorAttribute: 'data-reflex-form-selector-two',
  reflexIncludeInnerHtmlAttribute: 'data-reflex-include-inner-html-two',
  reflexIncludeTextContentAttribute: 'data-reflex-include-text-content-two'
}

describe('Schema', () => {
  beforeEach(() => {
    Schema.set(defaultSchema)
  })

  it('should read from default schema', () => {
    assert.equal(Schema.reflex, 'data-reflex')
    assert.equal(Schema.reflexPermanent, 'data-reflex-permanent')
    assert.equal(Schema.reflexRoot, 'data-reflex-root')
    assert.equal(Schema.reflexSuppressLogging, 'data-reflex-suppress-logging')
    assert.equal(Schema.reflexDataset, 'data-reflex-dataset')
    assert.equal(Schema.reflexDatasetAll, 'data-reflex-dataset-all')
    assert.equal(Schema.reflexSerializeForm, 'data-reflex-serialize-form')
    assert.equal(Schema.reflexFormSelector, 'data-reflex-form-selector')
    assert.equal(
      Schema.reflexIncludeInnerHtml,
      'data-reflex-include-inner-html'
    )
    assert.equal(
      Schema.reflexIncludeTextContent,
      'data-reflex-include-text-content'
    )
  })

  it('should override schema', () => {
    Schema.set({ schema: schemaOne })

    assert.equal(Schema.reflex, 'data-reflex-one')
    assert.equal(Schema.reflexPermanent, 'data-reflex-permanent-one')
    assert.equal(Schema.reflexRoot, 'data-reflex-root-one')
    assert.equal(
      Schema.reflexSuppressLogging,
      'data-reflex-suppress-logging-one'
    )
    assert.equal(Schema.reflexDataset, 'data-reflex-dataset-one')
    assert.equal(Schema.reflexDatasetAll, 'data-reflex-dataset-all-one')
    assert.equal(Schema.reflexSerializeForm, 'data-reflex-serialize-form-one')
    assert.equal(Schema.reflexFormSelector, 'data-reflex-form-selector-one')
    assert.equal(
      Schema.reflexIncludeInnerHtml,
      'data-reflex-include-inner-html-one'
    )
    assert.equal(
      Schema.reflexIncludeTextContent,
      'data-reflex-include-text-content-one'
    )
  })

  it('should override schema multipe times', () => {
    Schema.set({ schema: schemaTwo })

    assert.equal(Schema.reflex, 'data-reflex-two')
    assert.equal(Schema.reflexPermanent, 'data-reflex-permanent-two')
    assert.equal(Schema.reflexRoot, 'data-reflex-root-two')
    assert.equal(
      Schema.reflexSuppressLogging,
      'data-reflex-suppress-logging-two'
    )
    assert.equal(Schema.reflexDataset, 'data-reflex-dataset-two')
    assert.equal(Schema.reflexDatasetAll, 'data-reflex-dataset-all-two')
    assert.equal(Schema.reflexSerializeForm, 'data-reflex-serialize-form-two')
    assert.equal(Schema.reflexFormSelector, 'data-reflex-form-selector-two')
    assert.equal(
      Schema.reflexIncludeInnerHtml,
      'data-reflex-include-inner-html-two'
    )
    assert.equal(
      Schema.reflexIncludeTextContent,
      'data-reflex-include-text-content-two'
    )
  })
})
