import { dasherize, underscore } from 'inflected'

// Returns the expected matching controller name for the passed reflex.
//
// Example
//
//   matchingControllerName('ExampleReflex#do_stuff') // -> 'example'
//
export const matchingControllerName = reflex => {
  return dasherize(underscore(reflex.split('#')[0].replace(/Reflex$/, '')))
}
