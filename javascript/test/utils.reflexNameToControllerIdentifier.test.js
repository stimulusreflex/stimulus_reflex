import { assert } from '@open-wc/testing'

import { reflexNameToControllerIdentifier } from '../utils'

describe('reflexNameToControllerIdentifier', () => {
  describe('empty string', () => {
    it('returns empty string', () => {
      assert.equal(reflexNameToControllerIdentifier(''), '')
    })
  })

  describe('regular reflex name', () => {
    it('returns controller identifier', () => {
      assert.equal(reflexNameToControllerIdentifier('Test'), 'test')
      assert.equal(reflexNameToControllerIdentifier('TestReflex'), 'test')
    })
  })

  describe('camelcased reflex name', () => {
    it('returns controller identifier', () => {
      assert.equal(
        reflexNameToControllerIdentifier('SomethingElse'),
        'something-else'
      )
      assert.equal(
        reflexNameToControllerIdentifier('SomethingElseReflex'),
        'something-else'
      )
    })
  })

  describe('namespaced reflex name', () => {
    it('returns controller identifier', () => {
      assert.equal(
        reflexNameToControllerIdentifier('MyModule::Test'),
        'my-module--test'
      )
      assert.equal(
        reflexNameToControllerIdentifier('MyModule::TestReflex'),
        'my-module--test'
      )
    })
  })
})
