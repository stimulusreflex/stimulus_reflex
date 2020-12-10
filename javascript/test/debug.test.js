import assert from 'assert'
import refute from './refute'
import Debug from '../debug'
import DebugInOtherFile from '../debug'

describe('Debug', () => {
  beforeEach(() => {
    Debug.set(false)
  })

  it('Debug should be turned off by default', () => {
    assert(Debug.value === false)
  })

  it('Debug can be enabled via set()', () => {
    refute(Debug.value)
    Debug.set(true)
    assert(Debug.value)
  })

  it('Debug can be disabled via set()', () => {
    refute(Debug.value)
    Debug.set(true)
    assert(Debug.value)
    Debug.set(false)
    refute(Debug.value)
  })

  it('Debug can be enabled via debug=', () => {
    refute(Debug.value)
    Debug.debug = true
    assert(Debug.value)
  })

  it('Debug can be disabled via debug=', () => {
    refute(Debug.value)
    Debug.debug = true
    assert(Debug.value)
    Debug.debug = false
    refute(Debug.value)
  })

  it('Debug value can be read by all getters', () => {
    refute(Debug.value)
    refute(Debug.enabled)
    assert(Debug.disabled)

    Debug.set(true)

    assert(Debug.value)
    assert(Debug.enabled)
    refute(Debug.disabled)
  })

  it('Debug value is synced between different instances', () => {
    refute(Debug.value)
    refute(DebugInOtherFile.value)

    Debug.set(true)

    assert(Debug.value)
    assert(DebugInOtherFile.value)

    DebugInOtherFile.set(false)

    refute(Debug.value)
    refute(DebugInOtherFile.value)
  })
})
