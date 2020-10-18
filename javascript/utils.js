// uuid4 function taken from stackoverflow
// https://stackoverflow.com/a/2117523/554903

export const uuidv4 = () => {
  const crypto = window.crypto || window.msCrypto
  return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c =>
    (
      c ^
      (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))
    ).toString(16)
  )
}

export const serializeForm = (form, options = { w: window }) => {
  const { element, w } = options;

  const formData = new w.FormData(form)
  const data = Array.from(formData, e => e.join('='));

  if (element && element.name) {
    data.push(`${element.name}=${element.value}`)
  }

  return Array.from(new Set(data)).join('&');
}

export const camelize = (value, uppercaseFirstLetter = true) => {
  if (typeof value !== 'string') return ''
  value = value
    .replace(/[\s_](.)/g, $1 => $1.toUpperCase())
    .replace(/[\s_]/g, '')
    .replace(/^(.)/, $1 => $1.toLowerCase())

  if (uppercaseFirstLetter)
    value = value.substr(0, 1).toUpperCase() + value.substr(1)

  return value
}

export const debounce = (callback, delay = 250) => {
  let timeoutId
  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => {
      timeoutId = null
      callback(...args)
    }, delay)
  }
}

export const extractReflexName = reflexString => {
  const match = reflexString.match(/(?:.*->)?(.*?)(?:Reflex)?#/)

  return match ? match[1] : ''
}

export const emitEvent = (event, detail) => {
  document.dispatchEvent(
    new CustomEvent(event, {
      bubbles: true,
      cancelable: false,
      detail
    })
  )
}
