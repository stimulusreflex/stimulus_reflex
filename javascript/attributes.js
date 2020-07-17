import { defaultSchema } from './schema'

const multipleInstances = element =>
  document.querySelectorAll(
    `input[type="${element.type}"][name="${element.name}"]`
  ).length > 1

const collectCheckedOptions = element => {
  return Array.from(element.querySelectorAll('option:checked'))
    .concat(
      Array.from(
        document.querySelectorAll(
          `input[type="${element.type}"][name="${element.name}"]`
        )
      ).filter(elem => elem.checked)
    )
    .map(o => o.value)
}

// Returns a string value for the passed array.
//
//   attributeValue(['', 'one', null, 'two', 'three ']) // 'one two three'
//
export const attributeValue = (values = []) => {
  const value = values
    .filter(v => v && String(v).length)
    .map(v => v.trim())
    .join(' ')
    .trim()
  return value.length ? value : null
}

// Returns an array for the passed string value by splitting on whitespace.
//
//   attributeValues('one two three ') // ['one', 'two', 'three']
//
export const attributeValues = value => {
  if (!value) return []
  if (!value.length) return []
  return value.split(' ').filter(v => v.trim().length)
}

// Extracts attributes from a DOM element.
//
export const extractElementAttributes = element => {
  let attrs = Array.from(element.attributes).reduce((memo, attr) => {
    memo[attr.name] = attr.value
    return memo
  }, {})

  attrs.checked = !!element.checked
  attrs.selected = !!element.selected
  attrs.tag_name = element.tagName

  if (element.tagName.match(/select/i) || multipleInstances(element)) {
    const collectedOptions = collectCheckedOptions(element)
    attrs.values = collectedOptions
    attrs.value = collectedOptions.join(',')
  } else {
    attrs.value = element.value
    if (element.tagName.match(/select/i)) {
      if (element.selectedIndex > -1) {
        attrs.value = element.options[element.selectedIndex].value
      }
    }
  }
  return attrs
}

// Extracts the dataset of an element and combines it with the data attributes from all parents if requested.
//
export const extractElementDataset = (element, datasetAttribute = null) => {
  let attrs = extractDataAttributes(element) || {}
  const dataset = datasetAttribute && element.attributes[datasetAttribute]

  if (dataset && dataset.value === 'combined') {
    let parent = element.parentElement

    while (parent) {
      attrs = { ...extractDataAttributes(parent), ...attrs }
      parent = parent.parentElement
    }
  }

  return attrs
}

// Extracts all data attributes from a DOM element.
//
export const extractDataAttributes = element => {
  let attrs = {}

  if (element && element.attributes) {
    Array.from(element.attributes).forEach(attr => {
      if (attr.name.startsWith('data-')) {
        attrs[attr.name] = attr.value
      }
    })
  }

  return attrs
}

// Finds an element based on the passed represention of the DOM element's attributes.
//
// NOTE: This is the same set of attributes extrated via extractElementAttributes and forwarded to the server side reflex.
// SEE: stimulate()
// SEE: StimulusReflex::Channel#broadcast_morph
// SEE: StimulusReflex::Channel#broadcast_error
//
export const findElement = attributes => {
  attributes = attributes || {}
  let elements = []
  let selectors = []
  if (attributes.id) {
    elements = document.querySelectorAll(`#${attributes.id}`)
  } else {
    for (const key in attributes) {
      if (key.includes('.')) continue
      if (key === 'tagName') continue
      if (key === 'value') continue
      if (key === 'values') continue
      if (key === 'checked') continue
      if (key === 'selected') continue
      if (key === 'data-controller' && attributes[key] === 'stimulus-reflex')
        continue
      if (key === 'data-action' && attributes[key].includes('#__perform'))
        continue
      if (!Object.prototype.hasOwnProperty.call(attributes, key)) continue
      selectors.push(`[${key}="${attributes[key]}"]`)
    }
    try {
      elements = document.querySelectorAll(selectors.join(''))
    } catch (error) {
      console.error(
        'StimulusReflex encountered an error identifying the Stimulus element. Consider adding an #id to the element.',
        error,
        { 'CSS selector': selectors.join(''), attributes }
      )
    }
  }

  if (elements.length === 0)
    console.warn(
      'StimulusReflex was unable to find an element that matches the signature of the element which triggered this Reflex. Lifecycle callbacks and events cannot be raised unless your elements have distinguishing characteristics. Consider adding an #id or a randomized data-key to the element.',
      { 'CSS selector': selectors.join(''), attributes }
    )

  if (elements.length > 1)
    console.warn(
      'StimulusReflex found multiple identical elements that match the signature of the element which triggered this Reflex. Lifecycle callbacks and events cannot be raised unless your elements have distinguishing characteristics. Consider adding an #id or a randomized data-key to the element.',
      { 'CSS selector': selectors.join(''), attributes }
    )

  return elements.length === 1 ? elements[0] : null
}
