import { html, fixture, assert, nextFrame } from '@open-wc/testing'
import refute from './refute'

import ExampleController from './dummy/example_controller'
import RegularController from './dummy/regular_controller'

import { initialize } from '../stimulus_reflex'

import App from '../app'
import { application } from './dummy/application'
import { allReflexControllers } from '../controllers'

import {
  unloadAllControllers,
  registeredControllers,
  identifiers
} from './test_helpers'

describe('allReflexControllers', () => {
  beforeEach(() => {
    initialize(application)
  })

  afterEach(() => {
    unloadAllControllers()
  })

  it('returns StimulusReflex-enabled controller from parent', async () => {
    App.app.register('sr', ExampleController)

    assert.deepEqual(registeredControllers(), ['stimulus-reflex', 'sr'])

    const element = await fixture(html`
      <div data-controller="sr">
        <a></a>
      </div>
    `)

    const a = element.querySelector('a')
    assert.deepEqual(identifiers(allReflexControllers(a)), ['sr'])
  })

  it('doesnt return regular controller from parent', async () => {
    App.app.register('regular', RegularController)

    assert.deepEqual(registeredControllers(), ['stimulus-reflex', 'regular'])

    const element = await fixture(html`
      <div data-controller="regular">
        <a></a>
      </div>
    `)

    const a = element.querySelector('a')
    assert.isEmpty(identifiers(allReflexControllers(a)))
  })

  it('should return all reflex controllers from parents', async () => {
    App.app.register('sr-one', ExampleController)
    App.app.register('sr-two', ExampleController)
    App.app.register('regular-one', RegularController)
    App.app.register('regular-two', RegularController)

    const element = await fixture(html`
      <div data-controller="sr-one">
        <div data-controller="sr-two">
          <div data-controller="regular-one">
            <div data-controller="regular-two">
              <a></a>
            </div>
          </div>
        </div>
      </div>
    `)

    const a = element.querySelector('a')

    const controllers = allReflexControllers(a)

    assert.deepEqual(identifiers(controllers), ['sr-two', 'sr-one'])
  })

  it('should return controllers with same name', async () => {
    App.app.register('sr', ExampleController)

    const outer = await fixture(html`
      <div data-controller="sr" id="outer">
        <div data-controller="sr" id="inner">
          <a></a>
        </div>
      </div>
    `)

    const a = outer.querySelector('a')
    const inner = outer.querySelector('#inner')
    const controllers = allReflexControllers(a)

    assert.deepEqual(identifiers(controllers), ['sr', 'sr'])

    assert.deepEqual(controllers[0].element, inner)
    assert.deepEqual(controllers[1].element, outer)
  })
})
