import Debug from './debug'
import Deprecate from './deprecate'
import Schema from './schema'

import { Utils } from 'cable_ready'

const { debounce, dispatch, xpathToElement, xpathToElementArray } = Utils

// uuid4 function taken from stackoverflow
// https://stackoverflow.com/a/2117523/554903

const uuidv4 = () => {
  const crypto = window.crypto || window.msCrypto
  return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c =>
    (
      c ^
      (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))
    ).toString(16)
  )
}

const serializeForm = (form, options = {}) => {
  if (!form) return ''

  const w = options.w || window
  const { element } = options
  const formData = new w.FormData(form)
  const data = Array.from(formData, e => e.map(encodeURIComponent).join('='))
  const submitButton = form.querySelector('input[type=submit]')
  if (
    element &&
    element.name &&
    element.nodeName === 'INPUT' &&
    element.type === 'submit'
  ) {
    data.push(
      `${encodeURIComponent(element.name)}=${encodeURIComponent(element.value)}`
    )
  } else if (submitButton && submitButton.name) {
    data.push(
      `${encodeURIComponent(submitButton.name)}=${encodeURIComponent(
        submitButton.value
      )}`
    )
  }
  return Array.from(data).join('&')
}

const camelize = (value, uppercaseFirstLetter = true) => {
  if (typeof value !== 'string') return ''
  value = value
    .replace(/[\s_](.)/g, $1 => $1.toUpperCase())
    .replace(/[\s_]/g, '')
    .replace(/^(.)/, $1 => $1.toLowerCase())

  if (uppercaseFirstLetter)
    value = value.substr(0, 1).toUpperCase() + value.substr(1)

  return value
}

// TODO: remove this in v4 (potentially!)
const XPathToElement = xpathToElement
const XPathToArray = xpathToElementArray
const emitEvent = (name, detail = {}) => dispatch(document, name, detail)

const extractReflexName = reflexString => {
  const match = reflexString.match(/(?:.*->)?(.*?)(?:Reflex)?#/)

  return match ? match[1] : ''
}

// construct a valid xPath for an element in the DOM
const elementToXPath = element => {
  if (element.id !== '') return "//*[@id='" + element.id + "']"
  if (element === document.body) return '/html/body'
  if (element.nodeName === 'HTML') return '/html'

  let ix = 0
  const siblings =
    element && element.parentNode ? element.parentNode.childNodes : []

  for (var i = 0; i < siblings.length; i++) {
    const sibling = siblings[i]
    if (sibling === element) {
      const computedPath = elementToXPath(element.parentNode)
      const tagName = element.tagName.toLowerCase()
      const ixInc = ix + 1
      return `${computedPath}/${tagName}[${ixInc}]`
    }

    if (sibling.nodeType === 1 && sibling.tagName === element.tagName) {
      ix++
    }
  }
}

const elementInvalid = element => {
  return (
    element.type === 'number' && element.validity && element.validity.badInput
  )
}

const getReflexElement = (args, element) => {
  return args[0] && args[0].nodeType === Node.ELEMENT_NODE
    ? args.shift()
    : element
}

const getReflexOptions = args => {
  const options = {}
  // TODO: remove reflexId in v4
  if (
    args[0] &&
    typeof args[0] === 'object' &&
    Object.keys(args[0]).filter(key =>
      [
        'id',
        'attrs',
        'selectors',
        'reflexId',
        'resolveLate',
        'serializeForm',
        'suppressLogging',
        'includeInnerHTML',
        'includeTextContent'
      ].includes(key)
    ).length
  ) {
    const opts = args.shift()
    // TODO: in v4, all promises resolve during finalize stage
    // if they specify resolveLate, console.warn to say that the option will be ignored
    // deprecation warning in 3.5 is not required as it's still required until v4
    Object.keys(opts).forEach(o => {
      // TODO: no need to check for reflexId in v4
      if (o === 'reflexId') {
        if (Deprecate.enabled)
          console.warn('reflexId option will be removed in v4. Use id instead.')
        options['id'] = opts['reflexId']
      } else options[o] = opts[o]
    })
  }
  return options
}

// compute the DOM element(s) which will be the morph root
// use the data-reflex-root attribute on the reflex or the controller
// optional value is a CSS selector(s); comma-separated list
// order of preference is data-reflex, data-controller, document body (default)
const getReflexRoots = element => {
  let list = []
  while (list.length === 0 && element) {
    let reflexRoot = element.getAttribute(Schema.reflexRoot)
    if (reflexRoot) {
      if (reflexRoot.length === 0 && element.id) reflexRoot = `#${element.id}`
      const selectors = reflexRoot.split(',').filter(s => s.trim().length)
      if (Debug.enabled && selectors.length === 0) {
        console.error(
          `No value found for ${Schema.reflexRoot}. Add an #id to the element or provide a value for ${Schema.reflexRoot}.`,
          element
        )
      }
      list = list.concat(selectors.filter(s => document.querySelector(s)))
    }
    element = element.parentElement
      ? element.parentElement.closest(`[${Schema.reflexRoot}]`)
      : null
  }
  return list
}

const reflexNameToControllerIdentifier = (reflexName) => {
  return reflexName
    .replace(/([a-z0–9])([A-Z])/g, '$1-$2')
    .replace(/(::)/g, '--')
    .replace(/-reflex$/gi, '')
    .toLowerCase()
}

export {
  camelize,
  debounce,
  dispatch,
  elementInvalid,
  elementToXPath,
  emitEvent,
  extractReflexName,
  getReflexElement,
  getReflexOptions,
  getReflexRoots,
  reflexNameToControllerIdentifier,
  serializeForm,
  uuidv4,
  XPathToArray,
  XPathToElement,
}
