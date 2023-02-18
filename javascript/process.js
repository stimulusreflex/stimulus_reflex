import CableReady from 'cable_ready'

import App from './app'
import Debug from './debug'
import IsolationMode from './isolation_mode'
import Reflex from './reflex'

import { dispatchLifecycleEvent } from './lifecycle'
import { reflexes } from './reflexes'
import { XPathToElement } from './utils'

export const received = data => {
  if (!data.cableReady) return

  if (data.version.replace('.pre', '-pre') !== CableReady.version) {
    if (Debug.enabled)
      console.error(
        `Reflex failed due to cable_ready gem/NPM package version mismatch. Package versions must match exactly.\nNote that if you are using pre-release builds, gems use the "x.y.z.preN" version format, while NPM packages use "x.y.z-preN".\n\ncable_ready gem: ${data.version}\ncable_ready NPM: ${CableReady.version}`
      )
    return
  }

  let reflexOperations = []

  for (let i = data.operations.length - 1; i >= 0; i--) {
    if (data.operations[i].stimulusReflex) {
      reflexOperations.push(data.operations[i])
      data.operations.splice(i, 1)
    }
  }

  if (
    reflexOperations.some(
      operation => operation.stimulusReflex.url !== location.href
    )
  ) {
    if (Debug.enabled) {
      console.error('Reflex failed due to mismatched URL.')
      return
    }
  }

  let reflexData

  if (reflexOperations.length) {
    reflexData = reflexOperations[0].stimulusReflex
    reflexData.payload = reflexOperations[0].payload
  }

  if (reflexData) {
    const { id, payload } = reflexData
    let reflex

    // TODO: remove this in v4
    if (!reflexes[id] && IsolationMode.disabled) {
      const controllerElement = XPathToElement(reflexData.xpathController)
      const reflexElement = XPathToElement(reflexData.xpathElement)

      controllerElement.reflexController =
        controllerElement.reflexController || {}
      controllerElement.reflexData = controllerElement.reflexData || {}
      controllerElement.reflexError = controllerElement.reflexError || {}

      const controller = App.app.getControllerForElementAndIdentifier(
        controllerElement,
        reflexData.reflexController
      )

      controllerElement.reflexController[id] = controller
      controllerElement.reflexData[id] = reflexData

      reflex = new Reflex(reflexData, controller)
      reflexes[id] = reflex
      reflex.cloned = true
      reflex.element = reflexElement
      controller.lastReflex = reflex

      dispatchLifecycleEvent(reflex, 'before')
      reflex.getPromise
    } else {
      // v4 keep this, make it a const
      reflex = reflexes[id]
    }
    // END TODO: remove

    if (reflex) {
      reflex.payload = payload
      reflex.totalOperations = reflexOperations.length
      reflex.pendingOperations = reflexOperations.length
      reflex.completedOperations = 0
      reflex.piggybackOperations = data.operations
      CableReady.perform(reflexOperations)
    }
  } else {
    if (data.operations.length && reflexes[data.operations[0].reflexId]) {
      CableReady.perform(data.operations)
    }
  }
}
