import { html, fixture, assert } from '@open-wc/testing'

import ExampleController from './dummy/example_controller'

import { application } from './dummy/application'
import { initialize } from '../stimulus_reflex'

import App from '../app'
import { scanForReflexesOnElement } from '../scanner'

function registeredControllers () {
  return Array.from(App.app.router.modulesByIdentifier.keys())
}

describe('scanForReflexesOnElement', () => {
  beforeEach(() => {
    initialize(application)
  })

  afterEach(() => {
    App.app.unload(registeredControllers())
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
    App.app.register('example', ExampleController)

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
    App.app.register('example1', ExampleController)
    App.app.register('example2', ExampleController)

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

  it('should not add an additional data-controller attribute to the reflex element if any parent element already holds a controller instance', async () => {
    App.app.register('example', ExampleController)

    const controllerElement = await fixture(html`
      <div data-controller="example">
        <a data-reflex="click->Example#click">Click</a>
      </div>
    `)

    const button = controllerElement.children[0]

    scanForReflexesOnElement(button)

    assert.equal(controllerElement.dataset.controller, 'example')

    assert.equal(button.dataset.reflex, 'click->Example#click')
    assert.equal(button.dataset.action, 'click->example#__perform')
    assert.equal(button.dataset.controller, null)
  })

  it('should add an additional data-controller attribute to the reflex element if any parent element holds a data-controller attribute but controller doesnt exist', async () => {
    const controllerElement = await fixture(html`
      <div data-controller="example">
        <a data-reflex="click->Example#click">Click</a>
      </div>
    `)

    const button = controllerElement.children[0]

    scanForReflexesOnElement(button)

    // this element holds a data-controller="example" attribute but the `example` controller is not registered
    assert.equal(controllerElement.dataset.controller, 'example')
    assert.deepEqual(registeredControllers(), ['stimulus-reflex'])

    assert.equal(button.dataset.reflex, 'click->Example#click')
    assert.equal(button.dataset.action, 'click->stimulus-reflex#__perform')
    assert.equal(button.dataset.controller, 'stimulus-reflex')
  })

  it('should use data-controller from reflex element when parent element also holds a controller instance', async () => {
    App.app.register('example1', ExampleController)
    App.app.register('example2', ExampleController)

    const controllerElement = await fixture(html`
      <div data-controller="example1">
        <a data-reflex="click->Example#click" data-controller="example2"
          >Click</a
        >
      </div>
    `)

    const button = controllerElement.children[0]

    scanForReflexesOnElement(button)

    assert.equal(controllerElement.dataset.controller, 'example1')

    assert.equal(button.dataset.reflex, 'click->Example#click')
    assert.equal(button.dataset.action, 'click->example2#__perform')
    assert.equal(button.dataset.controller, 'example2')
  })

  it('should not add data-controller to reflex element if parent holds', async () => {
    App.app.register('example', ExampleController)

    const controllerElement = await fixture(html`
      <div data-controller="example">
        <a data-reflex="click->SomethingDifferent#click">Click</a>
      </div>
    `)

    const button = controllerElement.children[0]

    scanForReflexesOnElement(button)

    assert.equal(controllerElement.dataset.controller, 'example')

    assert.equal(button.dataset.reflex, 'click->SomethingDifferent#click')
    assert.equal(button.dataset.action, 'click->example#__perform')
    assert.equal(button.dataset.controller, undefined)
  })

  it('should use correct data-controller if element holds multiple controllers', async () => {
    App.app.register('example', ExampleController)
    App.app.register('something-different', ExampleController)

    const button = await fixture(html`
      <a
        data-reflex="click->SomethingDifferent#click"
        data-controller="example something-different"
        >Click</a
      >
    `)

    scanForReflexesOnElement(button)

    assert.equal(button.dataset.reflex, 'click->SomethingDifferent#click')
    assert.equal(button.dataset.action, 'click->something-different#__perform')
    assert.equal(button.dataset.controller, 'example something-different')
  })

  it('should add stimulus-reflex data-controller if element holds controller but none matches', async () => {
    App.app.register('example', ExampleController)

    const button = await fixture(html`
      <a
        data-reflex="click->Example#click"
        data-controller="something-different"
        >Click</a
      >
    `)

    scanForReflexesOnElement(button)

    assert.equal(button.dataset.reflex, 'click->Example#click')
    assert.equal(button.dataset.action, 'click->stimulus-reflex#__perform')
    assert.equal(
      button.dataset.controller,
      'something-different stimulus-reflex'
    )
  })

  it('should use correct data-controller from parent if parent holds multiple controllers', async () => {
    App.app.register('example', ExampleController)
    App.app.register('something-different', ExampleController)

    const controllerElement = await fixture(html`
      <div data-controller="example something-different">
        <a data-reflex="click->SomethingDifferent#click">Click</a>
      </div>
    `)

    const button = controllerElement.children[0]

    scanForReflexesOnElement(button)

    assert.equal(
      controllerElement.dataset.controller,
      'example something-different'
    )

    assert.equal(button.dataset.reflex, 'click->SomethingDifferent#click')
    assert.equal(button.dataset.action, 'click->something-different#__perform')
    assert.equal(button.dataset.controller, undefined)
  })
})
