import { dasherize, underscore } from 'inflected'

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

// Returns the expected matching controller name for the passed reflex.
//
//   matchingControllerName('ExampleReflex#do_stuff') // 'example'
//
export const matchingControllerName = reflex => {
  return dasherize(underscore(reflex.split('#')[0].replace(/Reflex$/, '')))
}
