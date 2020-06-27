import assert from 'assert'
import { extractReflexName } from '../utils'

describe('extractReflexName', () => {
  describe("when it includes 'Reflex'", () => {
    describe('when it includes an event name', () => {
      it('returns a reflex name', () => {
        assert(extractReflexName('click->TestReflex#create') === 'Test')
      })
    })

    describe('when it does not include an event name', () => {
      it('returns a reflex name', () => {
        assert(extractReflexName('TestReflex#create') === 'Test')
      })
    })
  })

  describe("when it does not include 'Reflex'", () => {
    describe('when it includes an event name', () => {
      it('returns a reflex name', () => {
        assert(extractReflexName('click->Test#create') === 'Test')
      })
    })

    describe('when it does not include an event name', () => {
      it('returns a reflex name', () => {
        assert(extractReflexName('Test#create') === 'Test')
      })
    })
  })

  describe("when it can't extract the reflex name", () => {
    it('returns an empty string', () => {
      assert(extractReflexName('nope') === '')
    })
  })
})
