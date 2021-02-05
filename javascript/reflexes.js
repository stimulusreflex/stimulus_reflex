import stimulus from './stimulus'
import CableReady from 'cable_ready'
import Debug from './debug'
import { dispatchLifecycleEvent } from './lifecycle'
import { XPathToElement } from './utils'

const reflexes = {}

export default reflexes

export const performOperations = data => {
  if (!data.cableReady) return

  let reflexOperations = {}

  for (let name in data.operations) {
    if (data.operations.hasOwnProperty(name)) {
      for (let i = data.operations[name].length - 1; i >= 0; i--) {
        if (
          data.operations[name][i].stimulusReflex ||
          (data.operations[name][i].detail &&
            data.operations[name][i].detail.stimulusReflex)
        ) {
          reflexOperations[name] = reflexOperations[name] || []
          reflexOperations[name].push(data.operations[name][i])
          data.operations[name].splice(i, 1)
        }
      }
      if (!data.operations[name].length)
        Reflect.deleteProperty(data.operations, name)
    }
  }

  let totalOperations = 0
  let reflexData

  const dispatchEvent = reflexOperations['dispatchEvent']
  const morph = reflexOperations['morph']
  const innerHtml = reflexOperations['innerHtml']

  ;[dispatchEvent, morph, innerHtml].forEach(operation => {
    if (operation && operation.length) {
      const urls = Array.from(
        new Set(
          operation.map(m =>
            m.detail ? m.detail.stimulusReflex.url : m.stimulusReflex.url
          )
        )
      )

      if (urls.length !== 1 || urls[0] !== location.href) return
      totalOperations += operation.length

      if (!reflexData) {
        reflexData = operation[0].detail
          ? operation[0].detail.stimulusReflex
          : operation[0].stimulusReflex
      }
    }
  })

  if (reflexData) {
    const { reflexId } = reflexData

    if (!reflexes[reflexId] && isolationMode.disabled) {
      const controllerElement = XPathToElement(reflexData.xpathController)
      const reflexElement = XPathToElement(reflexData.xpathElement)
      controllerElement.reflexController =
        controllerElement.reflexController || {}
      controllerElement.reflexData = controllerElement.reflexData || {}
      controllerElement.reflexError = controllerElement.reflexError || {}

      controllerElement.reflexController[
        reflexId
      ] = stimulus.app.getControllerForElementAndIdentifier(
        controllerElement,
        reflexData.reflexController
      )

      controllerElement.reflexData[reflexId] = reflexData
      dispatchLifecycleEvent(
        'before',
        reflexElement,
        controllerElement,
        reflexId
      )
      registerReflex(reflexData)
    }

    if (reflexes[reflexId]) {
      reflexes[reflexId].totalOperations = totalOperations
      reflexes[reflexId].pendingOperations = totalOperations
      reflexes[reflexId].completedOperations = 0
      CableReady.perform(reflexOperations)
    }
  }

  // run piggy back operations after stimulus reflex behavior
  CableReady.perform(data.operations)
}

export const registerReflex = data => {
  const { reflexId } = data
  reflexes[reflexId] = { finalStage: 'finalize' }

  const promise = new Promise((resolve, reject) => {
    reflexes[reflexId].promise = {
      resolve,
      reject,
      data
    }
  })

  promise.reflexId = reflexId

  if (Debug.enabled) promise.catch(() => {})

  return promise
}
