import { assert } from '@open-wc/testing'
import refute from './refute'

import { findControllerByReflexName } from '../controllers'

describe('findControllerByReflexName', () => {
  it('returns undefined if empty controllers array is passed', () => {
    assert.isUndefined(
      findControllerByReflexName('click->TestReflex#create', [])
    )
    assert.isUndefined(findControllerByReflexName('click->Test#create', []))
  })

  it('returns no controller if no matching controller is found', () => {
    const controller = { identifier: 'test' }
    const controllers = [
      { identifier: 'first' },
      controller,
      { identifier: 'last' }
    ]

    assert.isUndefined(
      findControllerByReflexName('click->NoReflex#create', controllers)
    )
    assert.isUndefined(
      findControllerByReflexName('click->No#create', controllers)
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

    assert.equal(
      findControllerByReflexName('click->Test#create', controllers),
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

    assert.equal(
      findControllerByReflexName(
        'click->Some::Deep::Module::Test#create',
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

    assert.equal(
      findControllerByReflexName('click->SomeThing#create', controllers),
      controller
    )
  })
})
