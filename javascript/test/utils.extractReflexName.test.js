import { assert } from '@open-wc/testing'

import { extractReflexName } from '../utils'

describe('extractReflexName', () => {
  describe("when it includes 'Reflex'", () => {
    describe('when it includes an event name', () => {
      it('returns a reflex name', () => {
        assert.equal(extractReflexName('click->TestReflex#create'), 'Test')
      })
    })

    describe('when it does not include an event name', () => {
      it('returns a reflex name', () => {
        assert.equal(extractReflexName('TestReflex#create'), 'Test')
      })
    })
  })

  describe("when it does not include 'Reflex'", () => {
    describe('when it includes an event name', () => {
      it('returns a reflex name', () => {
        assert.equal(extractReflexName('click->Test#create'), 'Test')
      })
    })

    describe('when it does not include an event name', () => {
      it('returns a reflex name', () => {
        assert.equal(extractReflexName('Test#create'), 'Test')
      })
    })
  })

  describe("when it can't extract the reflex name", () => {
    it('returns an empty string', () => {
      assert.equal(extractReflexName('nope'), '')
    })
  })

  describe('when the reflex class is camelcased', () => {
    it('returns namespaced reflex name', () => {
      assert.equal(
        extractReflexName('click->SomethingElseReflex#create'),
        'SomethingElse'
      )
    })

    it('returns namespaced reflex name', () => {
      assert.equal(
        extractReflexName('click->SomethingElse#create'),
        'SomethingElse'
      )
    })
  })

  describe('when the reflex class is namespaced', () => {
    it('returns namespaced reflex name', () => {
      assert.equal(
        extractReflexName('click->MyModule::TestReflex#create'),
        'MyModule::Test'
      )
    })
  })
})
