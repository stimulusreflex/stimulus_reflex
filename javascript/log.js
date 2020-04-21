const colors = {
  default: 'inherit',
  gray: '#9E9E9E',
  blue: '#03A9F4',
  green: '#4CAF50',
  red: '#F20404'
}

function styleFor (name) {
  return `color: ${colors[name]}; font-weight: bold`
}

export function logReflex (id, controller, target, element, argument) {
  const title = `%c stimulate %c ${target} %c@ ${new Date()}`
  const grayLight = 'color: gray; font-weight: light;'
  const defaultBold = 'color: inherit; font-weight: bold;'

  console.groupCollapsed(title, grayLight, defaultBold, grayLight)

  console.log('%c id', styleFor('default'), id)
  console.log('%c controller', styleFor('gray'), controller)
  console.log('%c target', styleFor('blue'), target)
  console.log('%c element', styleFor('green'), element)
  console.log('%c argument', styleFor('red'), argument)

  console.groupEnd()
}
