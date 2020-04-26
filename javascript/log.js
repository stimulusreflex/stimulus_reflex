const logs = {}

const colors = {
  gray: '#9E9E9E',
  blue: '#03A9F4',
  darkblue: '#0040f5',
  green: '#4CAF50',
  red: '#F20404',
  purple: '#97288a',
  magenta: '#eb59f7',
  orange: '#f19737',
  random: () => {
    return '#' + Math.floor(Math.random() * 200 * 200 * 200).toString(16)
  }
}

function style (color = 'inherit', weight = 'normal', background = 'none') {
  return `color: ${color}; font-weight: ${weight}; background: ${background}`
}

function request (id, target, controller, element, argument) {
  const color = colors.random()
  const triggerdAt = new Date()

  const title = `%cstimulate ==> %c${target} %c- %c${id}`
  const styles = [
    style('gray'),
    style('inherit', 'bold'),
    style('gray'),
    style(color)
  ]

  console.groupCollapsed(title, ...styles)
  console.log('%c id', style('inherit', 'bold'), id)
  console.log('%c date', style(colors.gray, 'bold'), triggerdAt)
  console.log('%c target', style(colors.blue, 'bold'), target)
  console.log('%c controller', style(colors.purple, 'bold'), controller)
  console.log('%c element', style(colors.green, 'bold'), element)
  console.log('%c argument', style(colors.magenta, 'bold'), argument)
  console.groupEnd()

  logs[id] = { color, triggerdAt, count: 1 }
}

function response (response) {
  const { reflexId, target, url, last } = response.event.detail.stimulusReflex || {}
  const { html, selector } = response.event.detail || {}
  const { color, triggerdAt, count } = logs[reflexId] || {}
  const receivedAt = new Date()
  const responseCount = (!last || count > 1) ? `[${count}]` : ''

  const title = `%cstimulate <== %c${target} %c- %c${reflexId} %c(${receivedAt - triggerdAt}ms) ${responseCount}`
  const styles = [
    style('gray'),
    style('inherit', 'bold'),
    style('gray'),
    style(color),
    style('gray')
  ]

  console.groupCollapsed(title, ...styles)
  console.log('%c id', style(colors.default, 'bold'), reflexId)
  console.log('%c date', style(colors.gray, 'bold'), receivedAt)
  console.log('%c target', style(colors.blue, 'bold'), target)
  console.log('%c selector', style(colors.purple, 'bold'), selector)
  console.log('%c html', style(colors.green, 'bold'), html)
  console.log('%c url', style(colors.magenta, 'bold'), url)
  console.log('%c event', style(colors.orange, 'bold'), event)
  console.groupEnd()

  if (last) {
    delete logs[reflexId]
  } else {
    logs[reflexId].count += 1
  }
}

function error (response) {
  const { reflexId, target, selectors, error, url } = response.event.detail.stimulusReflex || {}
  const { color, triggerdAt } = logs[reflexId] || {}
  const receivedAt = new Date()

  const title = `%cstimulate <== %c${target} %c- %c${reflexId} %c(${receivedAt - triggerdAt}ms) [error]`
  const styles = [
    style('gray', 'normal', '#fceceb'),
    style('inherit', 'bold', '#fceceb'),
    style('gray', 'normal', '#fceceb'),
    style(color, 'normal', '#fceceb'),
    style('gray', 'normal', '#fceceb')
  ]

  console.groupCollapsed(title, ...styles)
  console.error('%c id', style('black', 'bold'), reflexId)
  console.error('%c date', style(colors.gray, 'bold'), receivedAt)
  console.error('%c error', style('inherit', 'bold'), error)
  console.error('%c target', style(colors.blue, 'bold'), target)
  console.error('%c selectors', style(colors.purple, 'bold'), selectors)
  console.error('%c url', style(colors.magenta, 'bold'), url)
  console.error('%c event', style(colors.orange, 'bold'), event)
  console.groupEnd()

  delete logs[reflexId]
}

export default {
  request,
  response,
  error
}
