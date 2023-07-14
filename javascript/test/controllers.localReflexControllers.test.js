import { html, fixture, assert, nextFrame, oneEvent } from '@open-wc/testing'

import { application } from './dummy/application'
import ExampleController from './dummy/example_controller'
import RegularController from './dummy/regular_controller'

import App from '../app'
import { localReflexControllers } from '../controllers'
import { initialize } from '../stimulus_reflex'

import {
  unloadAllControllers,
  registeredControllers,
  identifiers
} from './test_helpers'

describe('localReflexControllers', () => {
  beforeEach(() => {
    initialize(application)
  })

  afterEach(() => {
    unloadAllControllers()
  })

  it('returns StimulusReflex-enabled controller', async () => {
    App.app.register('sr', ExampleController)

    assert.deepEqual(registeredControllers(), ['stimulus-reflex', 'sr'])

    const element = await fixture(html`
      <div data-controller="sr"></div>
    `)

    assert.deepEqual(identifiers(localReflexControllers(element)), ['sr'])
  })

  it('doesnt return regular controller', async () => {
    App.app.register('sr', ExampleController)
    App.app.register('regular', RegularController)

    assert.deepEqual(registeredControllers(), [
      'stimulus-reflex',
      'sr',
      'regular'
    ])

    const element = await fixture(html`
      <div data-controller="sr regular"></div>
    `)

    assert.deepEqual(identifiers(localReflexControllers(element)), ['sr'])
  })

  it('returns all StimulusReflex-enabled controllers', async () => {
    App.app.register('sr-one', ExampleController)
    App.app.register('sr-two', ExampleController)
    App.app.register('regular-one', RegularController)
    App.app.register('regular-two', RegularController)

    assert.deepEqual(registeredControllers(), [
      'stimulus-reflex',
      'sr-one',
      'sr-two',
      'regular-one',
      'regular-two'
    ])

    const element = await fixture(html`
      <div data-controller="regular-two sr-two sr-one regular-one"></div>
    `)

    assert.deepEqual(identifiers(localReflexControllers(element)), [
      'sr-two',
      'sr-one'
    ])
  })
})
