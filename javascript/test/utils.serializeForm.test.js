import assert from 'assert'
import { JSDOM } from 'jsdom'
import { serializeForm } from '../utils'

describe('formSerialize', () => {
  it('should serialize text input and textarea', () => {
    const dom = new JSDOM(
      '<form id="form"><input type="text" name="name" value="StimulusReflex"><textarea name="description">An exciting new way to build modern, reactive, real-time apps with Ruby on Rails.</textarea></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected =
      'name=StimulusReflex&description=An exciting new way to build modern, reactive, real-time apps with Ruby on Rails.'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize text input with spaces in name', () => {
    const dom = new JSDOM(
      '<form id="form"><input type="text" name="name 1" value="StimulusReflex"></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected = 'name 1=StimulusReflex'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize text input array', () => {
    const dom = new JSDOM(
      '<form id="form"><input type="text" name="name[]" value="StimulusReflex"><input type="text" name="name[]" value="CableReady"></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected = 'name[]=StimulusReflex&name[]=CableReady'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize nested text input', () => {
    const dom = new JSDOM(
      '<form id="form"><input id="person_name" name="person[name]" type="text" value="Bob"/></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected = 'person[name]=Bob'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize checkboxes', () => {
    const dom = new JSDOM(
      '<form id="form"><input type="checkbox" name="foo" checked/><input type="checkbox" name="bar"/><input type="checkbox" name="baz" checked/></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected = 'foo=on&baz=on'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize checkbox array', () => {
    const dom = new JSDOM(
      '<form id="form"><input type="checkbox" name="foo[]" value="bar" checked/><input type="checkbox" name="foo[]" value="baz" checked/><input type="checkbox" name="foo[]" value="baz"/></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected = 'foo[]=bar&foo[]=baz'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize disabled inputs', () => {
    const dom = new JSDOM(
      '<form id="form"><input type="text" name="foo" value="bar 1"/><input type="text" name="foo.bar" value="bar 2" disabled/></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected = 'foo=bar 1'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize disabled and empty inputs', () => {
    const dom = new JSDOM(
      '<form id="form"><input type="text" name="foo" value=""/><input type="text" name="foo.bar" value="" disabled/></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected = 'foo='
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize text input array with number index', () => {
    const dom = new JSDOM(
      '<form id="form"><input id="person_address_23_city" name="person[address][23][city]" type="text" value="Paris"/><input id="person_address_45_city" name="person[address][45][city]" type="text" value="London" /></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected =
      'person[address][23][city]=Paris&person[address][45][city]=London'
    assert.deepStrictEqual(actual, expected)
  })

  it('should serialize text input array with non-number index', () => {
    const dom = new JSDOM(
      '<form id="form"><input id="person_address_23_city" name="person[address][23_id][city]" type="text" value="Paris"/><input id="person_address_45_city" name="person[address][45_id][city]" type="text" value="London" /></form>'
    )
    const form = dom.window.document.querySelector('#form')
    const actual = serializeForm(form, dom.window)
    const expected =
      'person[address][23_id][city]=Paris&person[address][45_id][city]=London'
    assert.deepStrictEqual(actual, expected)
  })
})
