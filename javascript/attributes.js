import { $$asyncIterator } from 'iterall'

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
  let attrs = Array.prototype.slice
    .call(element.attributes)
    .reduce((memo, attr) => {
      memo[attr.name] = attr.value
      return memo
    }, {})

  attrs.checked = !!element.checked
  attrs.selected = !!element.selected
  attrs.tag_name = element.tagName

  if (hasMultipleOptions(element)) {
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

const hasMultipleOptions = element => {
  const multipleElementCount = document.querySelectorAll(
    `input[type="${element.type}"][name="${element.name}"]`
  ).length

  return (
    (element.tagName.match(/select/i) && element.multiple) ||
    multipleElementCount > 1
  )
}

const collectCheckedOptions = element => {
  const checkedOptions = Array.prototype.slice
    .call(element.querySelectorAll('option:checked'))
    .concat(
      Array.prototype.slice
        .call(
          document.querySelectorAll(
            `input[type="${element.type}"][name="${element.name}"]`
          )
        )
        .filter(elem => elem.checked)
    )

  return checkedOptions.map(o => o.value)
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
  if (attributes.id) {
    elements = document.querySelectorAll(`#${attributes.id}`)
  } else {
    let selectors = []
    for (const key in attributes) {
      if (key.includes('.')) continue
      if (key === 'tagName') continue
      if (key === 'value') continue
      if (key === 'checked') continue
      if (key === 'selected') continue
      if (!Object.prototype.hasOwnProperty.call(attributes, key)) continue
      selectors.push(`[${key}="${attributes[key]}"]`)
    }
    try {
      elements = document.querySelectorAll(selectors.join(''))
    } catch (error) {
      console.error(
        'StimulusReflex encountered an error identifying the Stimulus element. Consider adding an #id to the element.',
        error,
        attributes
      )
    }
  }

  const element = elements.length === 1 ? elements[0] : null
  return element
}

// Indicates if the passed element is considered a text input.
//
export const isTextInput = element => {
  return (
    ['INPUT', 'TEXTAREA', 'SELECT'].includes(element.tagName) &&
    [
      'color',
      'date',
      'datetime',
      'datetime-local',
      'email',
      'month',
      'number',
      'password',
      'range',
      'search',
      'select-one',
      'select-multiple',
      'tel',
      'text',
      'textarea',
      'time',
      'url',
      'week'
    ].includes(element.type)
  )
}
