import Schema from './schema'

import { extractElementAttributes, extractElementDataset } from './attributes'
import { uuidv4, getReflexRoots, elementToXPath } from './utils'

import packageInfo from '../package.json'

export default class ReflexData {
  constructor (
    options,
    reflexElement,
    controllerElement,
    reflexController,
    permanentAttributeName,
    target,
    args,
    url,
    tabId
  ) {
    this.options = options
    this.reflexElement = reflexElement
    this.controllerElement = controllerElement
    this.reflexController = reflexController
    this.permanentAttributeName = permanentAttributeName
    this.target = target
    this.args = args
    this.url = url
    this.tabId = tabId
  }

  get attrs () {
    this._attrs =
      this._attrs ||
      this.options['attrs'] ||
      extractElementAttributes(this.reflexElement)

    return this._attrs
  }

  get id () {
    this._id = this._id || this.options['id'] || uuidv4()
    return this._id
  }

  get selectors () {
    this._selectors =
      this._selectors ||
      this.options['selectors'] ||
      getReflexRoots(this.reflexElement)

    return typeof this._selectors === 'string'
      ? [this._selectors]
      : this._selectors
  }

  // TODO: v4 always resolve late
  get resolveLate () {
    return this.options['resolveLate'] || false
  }

  get dataset () {
    this._dataset = this._dataset || extractElementDataset(this.reflexElement)
    return this._dataset
  }

  get innerHTML () {
    return this.includeInnerHtml ? this.reflexElement.innerHTML : ''
  }

  get textContent () {
    return this.includeTextContent ? this.reflexElement.textContent : ''
  }

  // TODO: remove this in v4
  get xpathController () {
    return elementToXPath(this.controllerElement)
  }

  get xpathElement () {
    return elementToXPath(this.reflexElement)
  }
  // END TODO remove

  get formSelector () {
    const attr = this.reflexElement.attributes[Schema.reflexFormSelector]
      ? this.reflexElement.attributes[Schema.reflexFormSelector].value
      : undefined
    return this.options['formSelector'] || attr
  }

  get includeInnerHtml () {
    const attr =
      this.reflexElement.attributes[Schema.reflexIncludeInnerHtml] || false
    return this.options['includeInnerHTML'] || attr
      ? attr.value !== 'false'
      : false
  }

  get includeTextContent () {
    const attr =
      this.reflexElement.attributes[Schema.reflexIncludeTextContent] || false
    return this.options['includeTextContent'] || attr
      ? attr.value !== 'false'
      : false
  }

  get suppressLogging () {
    return (
      this.options['suppressLogging'] ||
      this.reflexElement.attributes[Schema.reflexSuppressLogging] ||
      false
    )
  }

  valueOf () {
    return {
      attrs: this.attrs,
      dataset: this.dataset,
      selectors: this.selectors,
      id: this.id,
      resolveLate: this.resolveLate,
      suppressLogging: this.suppressLogging,
      xpathController: this.xpathController,
      xpathElement: this.xpathElement,
      inner_html: this.innerHTML,
      text_content: this.textContent,
      formSelector: this.formSelector,
      reflexController: this.reflexController,
      permanentAttributeName: this.permanentAttributeName,
      target: this.target,
      args: this.args,
      url: this.url,
      tabId: this.tabId,
      version: packageInfo.version
    }
  }
}
