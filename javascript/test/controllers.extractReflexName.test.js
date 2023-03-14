import { assert } from '@open-wc/testing'
import refute from './refute'

import { findControllerByReflexName } from '../controllers'

describe('findControllerByReflexName', () => {
  it('returns undefined if empty controllers array is passed', () => {
    assert.equal(
      findControllerByReflexName('click->TestReflex#create', []),
      undefined
    )
  })

  it('returns first controller if no matching controller is found', () => {
    const controller = { identifier: 'test' }
    const controllers = [
      { identifier: 'first' },
      controller,
      { identifier: 'last' }
    ]

    assert.equal(
      findControllerByReflexName('click->NoReflex#create', controllers),
      controllers[0]
    )
  })

  it('returns matching controller', () => {
    const controller = { identifier: 'test' }
    const controllers = [
      { identifier: 'first' },
      controller,
      { identifier: 'last' }
    ]

    assert.equal(
      findControllerByReflexName('click->TestReflex#create', controllers),
      controller
    )
  })

  it('returns matching namespaced controller', () => {
    const controller = { identifier: 'some--deep--module--test' }
    const controllers = [
      { identifier: 'first' },
      controller,
      { identifier: 'last' }
    ]

    assert.equal(
      findControllerByReflexName(
        'click->Some::Deep::Module::TestReflex#create',
        controllers
      ),
      controller
    )
  })

  it('returns dasherized controller', () => {
    const controller = { identifier: 'some-thing' }
    const controllers = [
      { identifier: 'first' },
      controller,
      { identifier: 'last' }
    ]

    assert.equal(
      findControllerByReflexName('click->SomeThingReflex#create', controllers),
      controller
    )
  })
})
