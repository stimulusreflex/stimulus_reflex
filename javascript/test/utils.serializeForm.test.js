import assert from 'assert'
import { JSDOM } from 'jsdom'
import { serializeForm } from '../utils'

describe('formSerialize', () => {
  context('basic', () => {
    it('should output an empty string if no form is present', () => {
      const dom = new JSDOM('<div></div>')
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = ''
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize empty form', () => {
      const dom = new JSDOM('<form></form>')
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = ''
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize basic form with single input', () => {
      const dom = new JSDOM(
        '<form><input type="text" name="foo" value="bar"/></form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=bar'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize inputs with no values', () => {
      const dom = new JSDOM('<form><input type="text" name="foo"/></form>')
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo='
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text input with spaces in name', () => {
      const dom = new JSDOM(
        '<form><input type="text" name="name 1" value="StimulusReflex"></form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'name 1=StimulusReflex'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize from with multiple inputs', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="text" name="foo" value="bar 1"/>' +
          '<input type="text" name="foo.bar" value="bar 2"/>' +
          '<input type="text" name="baz.foo" value="bar 3"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=bar 1&foo.bar=bar 2&baz.foo=bar 3'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text input and textarea', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="text" name="name" value="StimulusReflex">' +
          '<textarea name="description">An exciting new way to build modern, reactive, real-time apps with Ruby on Rails.</textarea>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected =
        'name=StimulusReflex&description=An exciting new way to build modern, reactive, real-time apps with Ruby on Rails.'
      assert.deepStrictEqual(actual, expected)
    })

    it('should ignore disabled inputs', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="text" name="foo" value="bar 1"/>' +
          '<input type="text" name="foo.bar" value="bar 2" disabled/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=bar 1'
      assert.deepStrictEqual(actual, expected)
    })
  })

  context('<input type="checkbox">', () => {
    it('should serialize checkboxes', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="checkbox" name="foo" checked/>' +
          '<input type="checkbox" name="bar"/>' +
          '<input type="checkbox" name="baz" checked/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=on&baz=on'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize checkbox array', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="checkbox" name="foo[]" value="bar" checked/>' +
          '<input type="checkbox" name="foo[]" value="baz" checked/>' +
          '<input type="checkbox" name="foo[]" value="baz"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo[]=bar&foo[]=baz'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize checkbox array with one input', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="checkbox" name="foo[]" value="bar" checked/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo[]=bar'
      assert.deepStrictEqual(actual, expected)
    })
  })

  context('<input type="radio">', () => {
    it('should serialize radio button with no checked input', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="radio" name="foo" value="bar1"/>' +
          '<input type="radio" name="foo" value="bar2"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = ''
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize radio button', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="radio" name="foo" value="bar1" checked="checked"/>' +
          '<input type="radio" name="foo" value="bar2"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=bar1'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize radio button with empty input', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="radio" name="foo" value="" checked="checked"/>' +
          '<input type="radio" name="foo" value="bar2"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo='
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize radio and checkbox with the same key', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="radio" name="foo" value="bar1" checked="checked"/>' +
          '<input type="radio" name="foo" value="bar2"/>' +
          '<input type="checkbox" name="foo" value="bar3" checked="checked"/>' +
          '<input type="checkbox" name="foo" value="bar4"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=bar1&foo=bar3'
      assert.deepStrictEqual(actual, expected)
    })
  })

  context('<input> - buttons', () => {
    it('should not serialize buttons', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="submit" name="submit" value="submit"/>' +
          '<input type="reset" name="reset" value="reset"/>' +
          '<input type="button" name="button" value="button"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const element = dom.window.document.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { w: dom.window })
      const expected = ''
      assert.deepStrictEqual(actual, expected)
    })
  })

  context('<input> - brackets notation', () => {
    it('should serialize text inputs with brackets notation', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="text" name="name[]" value="StimulusReflex">' +
          '<input type="text" name="name[]" value="CableReady">' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'name[]=StimulusReflex&name[]=CableReady'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text inputs with nested brackets notation', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="email" name="account[name]" value="Foo Dude">' +
          '<input type="text" name="account[email]" value="foobar@example.org">' +
          '<input type="text" name="account[address][city]" value="Qux">' +
          '<input type="text" name="account[address][state]" value="CA">' +
          '<input type="text" name="account[address][empty]" value="">' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected =
        'account[name]=Foo Dude&account[email]=foobar@example.org&account[address][city]=Qux&account[address][state]=CA&account[address][empty]='
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text inputs with brackets notation and nested numbered index', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input id="person_address_23_city" name="person[address][23][city]" type="text" value="Paris"/>' +
          '<input id="person_address_45_city" name="person[address][45][city]" type="text" value="London" /> ' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected =
        'person[address][23][city]=Paris&person[address][45][city]=London'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text inputs with brackets notation and nested non-numbered index', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input id="person_address_23_city" name="person[address][23_id][city]" type="text" value="Paris"/>' +
          '<input id="person_address_45_city" name="person[address][45_id][city]" type="text" value="London" />' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected =
        'person[address][23_id][city]=Paris&person[address][45_id][city]=London'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text inputs with non-indexed bracket notation', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input name="people[][name]" value="fred" />' +
          '<input name="people[][name]" value="bob" />' +
          '<input name="people[][name]" value="bubba" />' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected =
        'people[][name]=fred&people[][name]=bob&people[][name]=bubba'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text inputs with non-indexed nested bracket notation', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input name="user[tags][]" value="cow" />' +
          '<input name="user[tags][]" value="milk" />' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'user[tags][]=cow&user[tags][]=milk'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize text inputs with indexed bracket notation', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input name="people[2][name]" value="bubba" />' +
          '<input name="people[2][age]" value="15" />' +
          '<input name="people[0][name]" value="fred" />' +
          '<input name="people[0][age]" value="12" />' +
          '<input name="people[1][name]" value="bob" />' +
          '<input name="people[1][age]" value="14" />' +
          '<input name="people[][name]" value="frank">' +
          '<input name="people[3][age]" value="2">' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected =
        'people[2][name]=bubba&people[2][age]=15&people[0][name]=fred&people[0][age]=12&people[1][name]=bob&people[1][age]=14&people[][name]=frank&people[3][age]=2'
      assert.deepStrictEqual(actual, expected)
    })
  })

  context('<select>', () => {
    it('should serialize select', () => {
      const dom = new JSDOM(
        '<form>' +
          '<select name="foo">' +
          '<option value="bar">bar</option>' +
          '<option value="baz" selected>baz</option>' +
          '</select>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=baz'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize select with empty option', () => {
      const dom = new JSDOM(
        '<form>' +
          '<select name="foo">' +
          '<option value="">empty</option>' +
          '<option value="bar">bar</option>' +
          '<option value="baz">baz</option>' +
          '</select>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo='
      assert.deepStrictEqual(actual, expected)
    })
  })

  context('<select multiple>', () => {
    it('should serialize select multiple', () => {
      const dom = new JSDOM(
        '<form>' +
          '<select name="foo" multiple>' +
          '<option value="bar" selected>bar</option>' +
          '<option value="baz">baz</option>' +
          '<option value="cat" selected>cat</option>' +
          '</select>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=bar&foo=cat'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize select multiple with empty option', () => {
      const dom = new JSDOM(
        '<form>' +
          '<select name="foo" multiple>' +
          '<option value="" selected>empty</option>' +
          '<option value="bar" selected>bar</option>' +
          '<option value="baz">baz</option>' +
          '<option value="cat">cat</option>' +
          '</select>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo=&foo=bar'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize select multiple with bracket notation', () => {
      const dom = new JSDOM(
        '<form>' +
          '<select name="foo[]" multiple>' +
          '<option value="bar" selected>Bar</option>' +
          '<option value="baz">Baz</option>' +
          '<option value="qux" selected>Qux</option>' +
          '</select>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo[]=bar&foo[]=qux'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize select multiple with bracket notation and empty option', () => {
      const dom = new JSDOM(
        '<form>' +
          '<select name="foo[bar]" multiple>' +
          '<option selected>Default value</option>' +
          '<option value="" selected>Empty value</option>' +
          '<option value="baz" selected>Baz</option>' +
          '<option value="qux">Qux</option>' +
          '<option value="norf" selected>Norf</option>' +
          '</select>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected =
        'foo[bar]=Default value&foo[bar]=&foo[bar]=baz&foo[bar]=norf'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize select multiple with nested bracket notation', () => {
      const dom = new JSDOM(
        '<form>' +
          '<select name="foo[bar]" multiple>' +
          '<option value="baz" selected>Baz</option>' +
          '<option value="qux">Qux</option>' +
          '<option value="norf" selected>Norf</option>' +
          '</select>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const actual = serializeForm(form, { w: dom.window })
      const expected = 'foo[bar]=baz&foo[bar]=norf'
      assert.deepStrictEqual(actual, expected)
    })
  })

  context('attach input name if input triggered action', () => {
    it('should serialize button if button triggered action', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="submit" name="commit" value="Create Post"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const element = dom.window.document.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { w: dom.window, element })
      const expected = 'commit=Create Post'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize inputs and button which triggered the action', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="text" name="title" value="Post"/>' +
          '<input type="submit" name="commit" value="Create Post"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const element = dom.window.document.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { w: dom.window, element })
      const expected = 'title=Post&commit=Create Post'
      assert.deepStrictEqual(actual, expected)
    })

    it('should serialize empty button if button triggered action', () => {
      const dom = new JSDOM(
        '<form>' + '<input type="submit" name="commit" value=""/>' + '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const element = dom.window.document.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { w: dom.window, element })
      const expected = 'commit='
      assert.deepStrictEqual(actual, expected)
    })

    it('should not serialize if input has no name', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="submit" name="" value="Create Post"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const element = dom.window.document.querySelector('input')
      const actual = serializeForm(form, { w: dom.window, element })
      const expected = ''
      assert.deepStrictEqual(actual, expected)
    })

    it('should not serialize if element is no input', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input type="submit" name="commit" value="Create Post"/>' +
          '<div class="foo">bar</div>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const element = dom.window.document.querySelector('div')
      const actual = serializeForm(form, { w: dom.window, element })
      const expected = ''
      assert.deepStrictEqual(actual, expected)
    })

    it('should not serialize input twice if input also triggered the action', () => {
      const dom = new JSDOM(
        '<form>' +
          '<input data-action="change->post#create" type="text" name="commit" value="Create Post"/>' +
          '</form>'
      )
      const form = dom.window.document.querySelector('form')
      const element = dom.window.document.querySelector('input')
      const actual = serializeForm(form, { w: dom.window, element })
      const expected = 'commit=Create Post'
      assert.deepStrictEqual(actual, expected)
    })
  })
})
