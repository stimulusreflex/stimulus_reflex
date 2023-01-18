import { html, fixture, assert } from '@open-wc/testing'

import ExampleController from './dummy/example_controller'

import { application } from './dummy/application'
import { initialize } from '../stimulus_reflex'

import Stimulus from '../app'
import { scanForReflexesOnElement } from '../scanner'

describe('scanForReflexesOnElement', () => {
  beforeEach(() => {
    initialize(application)
  })

  afterEach(() => {
    const registeredControllers = Array.from(
      Stimulus.app.router.modulesByIdentifier.keys()
    )

    Stimulus.app.unload(registeredControllers)
  })

  it('should add the right action and controller attribute', async () => {
    const element = await fixture(html`
      <a data-reflex="click->Example#handle">Handle</a>
    `)

    scanForReflexesOnElement(element)

    assert.equal(element.dataset.reflex, 'click->Example#handle')
    assert.equal(element.dataset.action, 'click->stimulus-reflex#__perform')
    assert.equal(element.dataset.controller, 'stimulus-reflex')
  })

  it('should add the right action and controller attribute with an existing controller attribute', async () => {
    Stimulus.app.register('example', ExampleController)

    const element = await fixture(html`
      <a data-controller="example" data-reflex="click->Example#handle"
        >Handle</a
      >
    `)

    scanForReflexesOnElement(element)

    assert.equal(element.dataset.reflex, 'click->Example#handle')
    assert.equal(element.dataset.action, 'click->example#__perform')
    assert.equal(element.dataset.controller, 'example')
  })

  it('should add the right action and controller attribute with multiple reflex descriptors', async () => {
    const element = await fixture(html`
      <a data-reflex="click->Example#click hover->Example#hover">Handle</a>
    `)

    scanForReflexesOnElement(element)

    assert.equal(
      element.dataset.reflex,
      'click->Example#click hover->Example#hover'
    )
    assert.equal(
      element.dataset.action,
      'click->stimulus-reflex#__perform hover->stimulus-reflex#__perform'
    )
    assert.equal(element.dataset.controller, 'stimulus-reflex')
  })

  it('should add the right action and controller attribute with multiple reflex descriptors using different reflexes and multiple custom controllers', async () => {
    Stimulus.app.register('example1', ExampleController)
    Stimulus.app.register('example2', ExampleController)

    const element = await fixture(html`
      <a
        data-controller="example1 example2"
        data-reflex="click->Example1#click click->Example2#click"
        >Click</a
      >
    `)

    scanForReflexesOnElement(element)

    assert.equal(
      element.dataset.reflex,
      'click->Example1#click click->Example2#click'
    )
    assert.equal(
      element.dataset.action,
      'click->example1#__perform click->example2#__perform'
    )
    assert.equal(element.dataset.controller, 'example1 example2')
  })

  it('should add the right action and controller attribute with multiple reflex descriptors using different reflexes and no custom controller', async () => {
    const element = await fixture(html`
      <a data-reflex="click->Example1#click click->Example2#click">Click</a>
    `)

    scanForReflexesOnElement(element)

    assert.equal(
      element.dataset.reflex,
      'click->Example1#click click->Example2#click'
    )
    assert.equal(element.dataset.action, 'click->stimulus-reflex#__perform')
    assert.equal(element.dataset.controller, 'stimulus-reflex')
  })
})
