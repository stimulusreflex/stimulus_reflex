import { html, fixture, assert } from '@open-wc/testing'

import { serializeForm } from '../utils'

describe('formSerialize', async () => {
  context('basic', async () => {
    it('should output an empty string if no form is present (null)', async () => {
      const actual = serializeForm(null)
      const expected = ''
      assert.equal(actual, expected)
    })

    it('should output an empty string if no form is present (undefined)', async () => {
      const actual = serializeForm(undefined)
      const expected = ''
      assert.equal(actual, expected)
    })

    it('should serialize empty form', async () => {
      const form = await fixture(
        html`
          <form></form>
        `
      )
      const actual = serializeForm(form)
      const expected = ''
      assert.equal(actual, expected)
    })

    it('should serialize basic form with single input', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="foo" value="bar" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=bar'
      assert.equal(actual, expected)
    })

    it('should serialize inputs with no values', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="foo" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo='
      assert.equal(actual, expected)
    })

    it('should serialize from with multiple inputs', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="foo" value="bar 1" />
          <input type="text" name="foo.bar" value="bar 2" />
          <input type="text" name="baz.foo" value="bar 3" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=bar%201&foo.bar=bar%202&baz.foo=bar%203'
      assert.equal(actual, expected)
    })

    it('should serialize text input and textarea', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="name" value="StimulusReflex" />
          <textarea name="description">
An exciting new way to build modern, reactive, real-time apps with Ruby on Rails.</textarea
          >
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'name=StimulusReflex&description=An%20exciting%20new%20way%20to%20build%20modern%2C%20reactive%2C%20real-time%20apps%20with%20Ruby%20on%20Rails.'
      assert.equal(actual, expected)
    })

    it('should ignore disabled inputs', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="foo" value="bar 1" />
          <input type="text" name="foo.bar" value="bar 2" disabled />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=bar%201'
      assert.equal(actual, expected)
    })
  })

  context('<input type="checkbox">', async () => {
    it('should serialize checkboxes', async () => {
      const form = await fixture(html`
        <form>
          <input type="checkbox" name="foo" checked />
          <input type="checkbox" name="bar" />
          <input type="checkbox" name="baz" checked />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=on&baz=on'
      assert.equal(actual, expected)
    })

    it('should serialize checkbox array', async () => {
      const form = await fixture(html`
        <form>
          <input type="checkbox" name="foo[]" value="bar" checked />
          <input type="checkbox" name="foo[]" value="baz" checked />
          <input type="checkbox" name="foo[]" value="baz" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo%5B%5D=bar&foo%5B%5D=baz'
      assert.equal(actual, expected)
    })

    it('should serialize checkbox array with one input', async () => {
      const form = await fixture(html`
        <form>
          <input type="checkbox" name="foo[]" value="bar" checked />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo%5B%5D=bar'
      assert.equal(actual, expected)
    })
  })

  context('<input type="radio">', async () => {
    it('should serialize radio button with no checked input', async () => {
      const form = await fixture(html`
        <form>
          <input type="radio" name="foo" value="bar1" />
          <input type="radio" name="foo" value="bar2" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = ''
      assert.equal(actual, expected)
    })

    it('should serialize radio button', async () => {
      const form = await fixture(html`
        <form>
          <input type="radio" name="foo" value="bar1" checked="checked" />
          <input type="radio" name="foo" value="bar2" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=bar1'
      assert.equal(actual, expected)
    })

    it('should serialize radio button with empty input', async () => {
      const form = await fixture(html`
        <form>
          <input type="radio" name="foo" value="" checked="checked" />
          <input type="radio" name="foo" value="bar2" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo='
      assert.equal(actual, expected)
    })

    it('should serialize radio and checkbox with the same key', async () => {
      const form = await fixture(html`
        <form>
          <input type="radio" name="foo" value="bar1" checked="checked" />
          <input type="radio" name="foo" value="bar2" />
          <input type="checkbox" name="foo" value="bar3" checked="checked" />
          <input type="checkbox" name="foo" value="bar4" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=bar1&foo=bar3'
      assert.equal(actual, expected)
    })
  })

  context('<input> - buttons', async () => {
    it('should not serialize buttons', async () => {
      const form = await fixture(html`
        <form>
          <input type="submit" name="submit" value="submit"/>
          <input type="reset" name="reset" value="reset"/>
          <input type="button" name="button" value="button"/>
          <button type="submit name="submitButton" value="submit">Submit</button>
          <button type="reset name="resetButton" value="reset">Reset</button>
          <button type="button name="buttonButton" value="button">Button</button>
        </form>
      `)
      const element = form.querySelector('input[type="submit"]')
      const actual = serializeForm(form)
      const expected = 'submit=submit'
      assert.equal(actual, expected)
    })
  })

  context('<input> - brackets notation', async () => {
    it('should serialize text inputs with brackets notation', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="name[]" value="StimulusReflex" />
          <input type="text" name="name[]" value="CableReady" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%5B%5D=StimulusReflex&name%5B%5D=CableReady'
      assert.equal(actual, expected)
    })

    it('should serialize text inputs with nested brackets notation', async () => {
      const form = await fixture(html`
        <form>
          <input type="email" name="account[name]" value="Foo Dude" />
          <input type="text" name="account[email]" value="foobar@example.org" />
          <input type="text" name="account[address][city]" value="Qux" />
          <input type="text" name="account[address][state]" value="CA" />
          <input type="text" name="account[address][empty]" value="" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'account%5Bname%5D=Foo%20Dude&account%5Bemail%5D=foobar%40example.org&account%5Baddress%5D%5Bcity%5D=Qux&account%5Baddress%5D%5Bstate%5D=CA&account%5Baddress%5D%5Bempty%5D='
      assert.equal(actual, expected)
    })

    it('should serialize text inputs with brackets notation and nested numbered index', async () => {
      const form = await fixture(html`
        <form>
          <input
            id="person_address_23_city"
            name="person[address][23][city]"
            type="text"
            value="Paris"
          />
          <input
            id="person_address_45_city"
            name="person[address][45][city]"
            type="text"
            value="London"
          />
          ' +
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'person%5Baddress%5D%5B23%5D%5Bcity%5D=Paris&person%5Baddress%5D%5B45%5D%5Bcity%5D=London'
      assert.equal(actual, expected)
    })

    it('should serialize text inputs with brackets notation and nested non-numbered index', async () => {
      const form = await fixture(html`
        <form>
          <input
            id="person_address_23_city"
            name="person[address][23_id][city]"
            type="text"
            value="Paris"
          />
          <input
            id="person_address_45_city"
            name="person[address][45_id][city]"
            type="text"
            value="London"
          />
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'person%5Baddress%5D%5B23_id%5D%5Bcity%5D=Paris&person%5Baddress%5D%5B45_id%5D%5Bcity%5D=London'
      assert.equal(actual, expected)
    })

    it('should serialize text inputs with non-indexed bracket notation', async () => {
      const form = await fixture(html`
        <form>
          <input name="people[][name]" value="fred" />
          <input name="people[][name]" value="bob" />
          <input name="people[][name]" value="bubba" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'people%5B%5D%5Bname%5D=fred&people%5B%5D%5Bname%5D=bob&people%5B%5D%5Bname%5D=bubba'
      assert.equal(actual, expected)
    })

    it('should serialize text inputs with non-indexed nested bracket notation', async () => {
      const form = await fixture(html`
        <form>
          <input name="user[tags][]" value="cow" />
          <input name="user[tags][]" value="milk" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'user%5Btags%5D%5B%5D=cow&user%5Btags%5D%5B%5D=milk'
      assert.equal(actual, expected)
    })

    it('should serialize text inputs with indexed bracket notation', async () => {
      const form = await fixture(html`
        <form>
          <input name="people[2][name]" value="bubba" />
          <input name="people[2][age]" value="15" />
          <input name="people[0][name]" value="fred" />
          <input name="people[0][age]" value="12" />
          <input name="people[1][name]" value="bob" />
          <input name="people[1][age]" value="14" />
          <input name="people[][name]" value="frank" />
          <input name="people[3][age]" value="2" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'people%5B2%5D%5Bname%5D=bubba&people%5B2%5D%5Bage%5D=15&people%5B0%5D%5Bname%5D=fred&people%5B0%5D%5Bage%5D=12&people%5B1%5D%5Bname%5D=bob&people%5B1%5D%5Bage%5D=14&people%5B%5D%5Bname%5D=frank&people%5B3%5D%5Bage%5D=2'
      assert.equal(actual, expected)
    })

    it('should serialize forms with multiple, non-unique array elements', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="post[test][]" value="a" />
          <input type="text" name="post[test][]" value="a" />
          <input type="text" name="post[test][]" value="b" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'post%5Btest%5D%5B%5D=a&post%5Btest%5D%5B%5D=a&post%5Btest%5D%5B%5D=b'
      assert.equal(actual, expected)
    })
  })

  context('<select>', async () => {
    it('should serialize select', async () => {
      const form = await fixture(html`
        <form>
          <select name="foo">
            <option value="bar">bar</option>
            <option value="baz" selected>baz</option>
          </select>
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=baz'
      assert.equal(actual, expected)
    })

    it('should serialize select with empty option', async () => {
      const form = await fixture(html`
        <form>
          <select name="foo">
            <option value="">empty</option>
            <option value="bar">bar</option>
            <option value="baz">baz</option>
          </select>
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo='
      assert.equal(actual, expected)
    })
  })

  context('<select multiple>', async () => {
    it('should serialize select multiple', async () => {
      const form = await fixture(html`
        <form>
          <select name="foo" multiple>
            <option value="bar" selected>bar</option>
            <option value="baz">baz</option>
            <option value="cat" selected>cat</option>
          </select>
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=bar&foo=cat'
      assert.equal(actual, expected)
    })

    it('should serialize select multiple with empty option', async () => {
      const form = await fixture(html`
        <form>
          <select name="foo" multiple>
            <option value="" selected>empty</option>
            <option value="bar" selected>bar</option>
            <option value="baz">baz</option>
            <option value="cat">cat</option>
          </select>
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo=&foo=bar'
      assert.equal(actual, expected)
    })

    it('should serialize select multiple with bracket notation', async () => {
      const form = await fixture(html`
        <form>
          <select name="foo[]" multiple>
            <option value="bar" selected>Bar</option>
            <option value="baz">Baz</option>
            <option value="qux" selected>Qux</option>
          </select>
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo%5B%5D=bar&foo%5B%5D=qux'
      assert.equal(actual, expected)
    })

    it('should serialize select multiple with bracket notation and empty option', async () => {
      const form = await fixture(html`
        <form>
          <select name="foo[bar]" multiple>
            <option selected>Default value</option>
            <option value="" selected>Empty value</option>
            <option value="baz" selected>Baz</option>
            <option value="qux">Qux</option>
            <option value="norf" selected>Norf</option>
          </select>
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'foo%5Bbar%5D=Default%20value&foo%5Bbar%5D=&foo%5Bbar%5D=baz&foo%5Bbar%5D=norf'
      assert.equal(actual, expected)
    })

    it('should serialize select multiple with nested bracket notation', async () => {
      const form = await fixture(html`
        <form>
          <select name="foo[bar]" multiple>
            <option value="baz" selected>Baz</option>
            <option value="qux">Qux</option>
            <option value="norf" selected>Norf</option>
          </select>
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'foo%5Bbar%5D=baz&foo%5Bbar%5D=norf'
      assert.equal(actual, expected)
    })
  })

  context('attach input name if input triggered action', async () => {
    it('should serialize button if button triggered action', async () => {
      const form = await fixture(html`
        <form>
          <input type="submit" name="commit" value="Create Post" />
        </form>
      `)
      const element = form.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { element })
      const expected = 'commit=Create%20Post'
      assert.equal(actual, expected)
    })

    it('should serialize inputs and input button which triggered the action', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="title" value="Post" />
          <input type="submit" name="commit" value="Create Post" />
        </form>
      `)
      const element = form.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { element })
      const expected = 'title=Post&commit=Create%20Post'
      assert.equal(actual, expected)
    })

    it('should also serialize submit button if other element triggered action', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="name" value="Hello World" />
          <input type="submit" name="commit" value="Create Post" />
        </form>
      `)
      const element = form.querySelector('input[type="text"]')
      const actual = serializeForm(form, { element })
      const expected = 'name=Hello%20World&commit=Create%20Post'
      assert.equal(actual, expected)
    })

    it('should serialize first submit button if no submit button triggered the action', async () => {
      const form = await fixture(html`
        <form>
          <input type="submit" name="commit" value="One" />
          <input type="submit" name="commit" value="Two" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'commit=One'
      assert.equal(actual, expected)
    })

    it('should serialize submit button which triggered the action even if there is more than one submit button', async () => {
      const form = await fixture(html`
        <form>
          <input type="submit" name="commit" value="One" />
          <input type="submit" name="commit" value="Two" />
        </form>
      `)
      const element = form.querySelector('input[value="Two"]')
      const actual = serializeForm(form, { element })
      const expected = 'commit=Two'
      assert.equal(actual, expected)
    })

    it('should serialize empty button if button triggered action', async () => {
      const form = await fixture(html`
        <form>
          <input type="submit" name="commit" value="" />
        </form>
      `)
      const element = form.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { element })
      const expected = 'commit='
      assert.equal(actual, expected)
    })

    it('should not serialize input even if the input element triggered the action', async () => {
      const form = await fixture(html`
        <form>
          <input type="checkbox" name="public" value="1" />
        </form>
      `)
      const element = form.querySelector('input[type="checkbox"]')
      const actual = serializeForm(form, { element })
      const expected = ''
      assert.equal(actual, expected)
    })

    it('should not serialize if input has no name', async () => {
      const form = await fixture(html`
        <form>
          <input type="submit" name="" value="Create Post" />
        </form>
      `)
      const element = form.querySelector('input')
      const actual = serializeForm(form, { element })
      const expected = ''
      assert.equal(actual, expected)
    })

    it('should not serialize if element is no input', async () => {
      const form = await fixture(html`
        <form>
          ' + '
          <div name="foo" value="bar">bar</div>
          ' + '
        </form>
      `)
      const element = form.querySelector('div')
      const actual = serializeForm(form, { element })
      const expected = ''
      assert.equal(actual, expected)
    })

    it('should not serialize input twice if input also triggered the action', async () => {
      const form = await fixture(html`
        <form>
          <input
            data-action="change->post#create"
            type="text"
            name="commit"
            value="Create Post"
          />
        </form>
      `)
      const element = form.querySelector('input')
      const actual = serializeForm(form, { element })
      const expected = 'commit=Create%20Post'
      assert.equal(actual, expected)
    })
  })

  context('url encodings', async () => {
    it('should encode space', async () => {
      const form = await fixture(html`
        <form><input type="text" name="na me" value="Stimulus Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'na%20me=Stimulus%20Reflex'
      assert.equal(actual, expected)
    })

    it('should encode ampersand', async () => {
      const form = await fixture(html`
        <form><input type="text" name="na&me" value="Stimulus&Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'na%26me=Stimulus%26Reflex'
      assert.equal(actual, expected)
    })

    it('should encode equals', async () => {
      const form = await fixture(html`
        <form><input type="text" name="name=" value="Stimulus=Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%3D=Stimulus%3DReflex'
      assert.equal(actual, expected)
    })

    it('should encode colon', async () => {
      const form = await fixture(html`
        <form><input type="text" name="na:me" value="Stimulus:Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'na%3Ame=Stimulus%3AReflex'
      assert.equal(actual, expected)
    })

    it('should encode semi-colon', async () => {
      const form = await fixture(html`
        <form><input type="text" name="name;" value="StimulusReflex;" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%3B=StimulusReflex%3B'
      assert.equal(actual, expected)
    })

    it('should encode slash', async () => {
      const form = await fixture(html`
        <form><input type="text" name="na/me" value="Stimulus/Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'na%2Fme=Stimulus%2FReflex'
      assert.equal(actual, expected)
    })

    it('should encode plus', async () => {
      const form = await fixture(html`
        <form><input type="text" name="name+" value="Stimulus+Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%2B=Stimulus%2BReflex'
      assert.equal(actual, expected)
    })

    it('should encode dollar sign', async () => {
      const form = await fixture(html`
        <form><input type="text" name="name$" value="Stimulus$Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%24=Stimulus%24Reflex'
      assert.equal(actual, expected)
    })

    it('should encode at symbol', async () => {
      const form = await fixture(html`
        <form><input type="text" name="name@" value="Stimulus@Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%40=Stimulus%40Reflex'
      assert.equal(actual, expected)
    })

    it('should encode question mark', async () => {
      const form = await fixture(html`
        <form><input type="text" name="name?" value="StimulusReflex?" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%3F=StimulusReflex%3F'
      assert.equal(actual, expected)
    })

    it('should encode percent', async () => {
      const form = await fixture(html`
        <form><input type="text" name="name%" value="Stimulus%Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%25=Stimulus%25Reflex'
      assert.equal(actual, expected)
    })

    it('should encode brackets', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="name[]" value="StimulusReflex[]" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'name%5B%5D=StimulusReflex%5B%5D'
      assert.equal(actual, expected)
    })

    it('should encode curly braces', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="na{}me" value="Stimulus{}Reflex" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'na%7B%7Dme=Stimulus%7B%7DReflex'
      assert.equal(actual, expected)
    })

    it('should encode pound character', async () => {
      const form = await fixture(html`
        <form><input type="text" name="na#me" value="Stimulus#Reflex" /></form>
      `)
      const actual = serializeForm(form)
      const expected = 'na%23me=Stimulus%23Reflex'
      assert.equal(actual, expected)
    })

    it('should encode multiple inputs with ampersand and equals', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="one" value="Hello & World" />
          <input type="text" name="two" value="foo = bar" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'one=Hello%20%26%20World&two=foo%20%3D%20bar'
      assert.equal(actual, expected)
    })

    it('should encode submit button name', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="name" value="Hello&World" />
          <input type="submit" name="commit&" value="Create=Post" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected = 'name=Hello%26World&commit%26=Create%3DPost'
      assert.equal(actual, expected)
    })

    it('should encode submit button name as triggered element', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="name" value="Hello&World" />
          <input type="submit" name="commit&" value="Create=Post" />
        </form>
      `)
      const element = form.querySelector('input[type="submit"]')
      const actual = serializeForm(form, { element })
      const expected = 'name=Hello%26World&commit%26=Create%3DPost'
      assert.equal(actual, expected)
    })

    it('should encode all characterss', async () => {
      const form = await fixture(html`
        <form>
          <input type="text" name="name" value=" $&+,/:;=?@<>#%{}|^[]\`\\" />
        </form>
      `)
      const actual = serializeForm(form)
      const expected =
        'name=%20%24%26%2B%2C%2F%3A%3B%3D%3F%40%3C%3E%23%25%7B%7D%7C%5E%5B%5D%60%5C'
      assert.equal(actual, expected)
    })
  })
})
