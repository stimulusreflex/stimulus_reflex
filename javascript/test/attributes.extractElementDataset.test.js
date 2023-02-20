import { html, fixture, assert } from '@open-wc/testing'

import { extractElementDataset } from '../attributes'
import Schema, { defaultSchema } from '../schema'

Schema.set({
  schema: {
    ...defaultSchema,
    controllerAttribute: 'data-controller',
    actionAttribute: 'data-action',
    targetAttribute: 'data-target'
  }
})

describe('extractElementDataset', () => {
  it('should return dataset for element without data attributes', async () => {
    const element = await fixture(
      html`
        <a id="example">Test</a>
      `
    )
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {},
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element', async () => {
    const element = await fixture(html`
      <a id="example" data-controller="foo" data-reflex="bar" data-info="12345"
        >Test</a
      >
    `)
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element without combining dataset from parent', async () => {
    const parent = await fixture(html`
      <div data-parent-id="should not be included">
        <a
          id="example"
          data-controller="foo"
          data-reflex="bar"
          data-info="12345"
          >Test</a
        >
      </div>
    `)

    const element = parent.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element but without providing the dataset attribute', async () => {
    const parent = await fixture(html`
      <div data-parent-id="should not be included">
        <a
          id="example"
          data-controller="foo"
          data-reflex="bar"
          data-info="12345"
          >Test</a
        >
      </div>
    `)

    const element = parent.querySelector('a')
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(extractElementDataset(element), expected)
  })

  it('should return dataset for element with data-reflex-dataset without value', async () => {
    const parent = await fixture(html`
      <div data-parent-id="should not be included">
        <a
          id="example"
          data-controller="foo"
          data-reflex="bar"
          data-info="12345"
          data-reflex-dataset
          >Test</a
        >
      </div>
    `)

    const element = parent.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345',
        'data-reflex-dataset': ''
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element with data-reflex-dataset and other value than "ancestors"', async () => {
    const parent = await fixture(html`
      <div data-parent-id="should not be included">
        <a
          id="example"
          data-controller="foo"
          data-reflex="bar"
          data-info="12345"
          data-reflex-dataset="whut"
          >Test</a
        >
      </div>
    `)

    const element = parent.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345',
        'data-reflex-dataset': 'whut'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element with data-reflex-dataset="ancestors"', async () => {
    const body = await fixture(html`
      <div data-body-id="body">
        <div data-grandparent-id="456">
          <div data-parent-id="123">
            <a
              id="example"
              data-controller="foo"
              data-reflex="bar"
              data-info="12345"
              data-reflex-dataset="ancestors"
              >Test</a
            >
          </div>
        </div>
      </div>
    `)

    const element = body.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345',
        'data-grandparent-id': '456',
        'data-parent-id': '123',
        'data-body-id': 'body',
        'data-reflex-dataset': 'ancestors'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element with overloaded data attributes', async () => {
    const parent = await fixture(html`
      <div data-info="this is the outer one">
        <a data-info="this is the inner one" data-reflex-dataset="ancestors"
          >Test</a
        >
      </div>
    `)

    const element = parent.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-info': 'this is the inner one',
        'data-reflex-dataset': 'ancestors'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return with ancestors parent attributes only for elements with data-reflex-dataset', async () => {
    const parent = await fixture(html`
      <div data-parent-id="123">
        <button id="button1" data-reflex-dataset="ancestors">Something</button>
        <button id="button2">Another thing</button>
      </div>
    `)

    const button1 = parent.querySelector('#button1')
    const actualButton1 = extractElementDataset(button1)
    const expectedButton1 = {
      dataset: {
        'data-parent-id': '123',
        'data-reflex-dataset': 'ancestors'
      },
      datasetAll: {}
    }

    const button2 = parent.querySelector('#button2')
    const actualButton2 = extractElementDataset(button2)
    const expectedButton2 = {
      dataset: {},
      datasetAll: {}
    }

    assert.deepStrictEqual(actualButton1, expectedButton1)
    assert.deepStrictEqual(actualButton2, expectedButton2)
  })

  // no way to test this because Schema object doesn't support dynamically renaming attribute keys
  // it('should return dataset for element with different renamed data-reflex-dataset attribute', async () => {
  //   const dom = new JSDOM(
  //     `<body data-body-id="body">
  //       <div data-grandparent-id="456">
  //         <div data-parent-id="123">
  //           <a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset-renamed="ancestors">Test</a>
  //         </div>
  //       </div>
  //     </body>
  //     `
  //   )
  //   global.document = dom.window.document
  //   // App.app.schema.reflexDatasetAttribute = 'data-reflex-dataset-renamed'
  //   const element = dom.window.document.querySelector('a')
  //   const actual = extractElementDataset(element)
  //   const expected = {
  //     dataset: {
  //       'data-controller': 'foo',
  //       'data-reflex': 'bar',
  //       'data-info': '12345',
  //       'data-grandparent-id': '456',
  //       'data-parent-id': '123',
  //       'data-body-id': 'body',
  //       'data-reflex-dataset-renamed': 'ancestors'
  //     },
  //     datasetAll: {}
  //   }
  //   assert.deepStrictEqual(actual, expected)
  // })

  it('should return dataset for id', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-reflex-dataset="#timmy"
        ></div>
        <div id="timmy" data-age="12"></div>
      </div>
    `)
    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-age': '12',
        'data-reflex-dataset': '#timmy'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for tag name', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-reflex-dataset="span"
        ></div>
        <span data-span-one="1"></span>
        <span data-span-two="2"></span>
        <div data-div="other"></div>
        <div data-div="other"></div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-span-one': '1',
        'data-span-two': '2',
        'data-reflex-dataset': 'span'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for tag name with class', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-reflex-dataset="span.post"
        ></div>
        <span class="post" data-span-one="1"></span>
        <span class="post" data-span-two="2"></span>
        <span data-span="other"></span>
        <span data-span="other"></span>
        <div data-div="other"></div>
        <div data-div="other"></div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-span-one': '1',
        'data-span-two': '2',
        'data-reflex-dataset': 'span.post'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple elements with the same ids', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-reflex-dataset="#timmy"
        ></div>
        <div id="timmy" data-one="1"></div>
        <div id="timmy" data-two="2"></div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-one': '1',
        'data-two': '2',
        'data-reflex-dataset': '#timmy'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple different ids', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-reflex-dataset="#post1 #post2 #post3 #post4"
        ></div>
        <div id="post1" data-one-id="1"></div>
        <div id="post2" data-two-id="2"></div>
        <div id="post3" data-three-id="3"></div>
        <div id="post4" data-four-id="4"></div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-one-id': '1',
        'data-two-id': '2',
        'data-three-id': '3',
        'data-four-id': '4',
        'data-reflex-dataset': '#post1 #post2 #post3 #post4'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for class', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-id="1"
          data-reflex-dataset=".sarah"
        ></div>
        <div class="sarah" data-job="clerk"></div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-job': 'clerk',
        'data-reflex-dataset': '.sarah'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple elements with the same class', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-id="1"
          data-reflex-dataset=".post"
        ></div>
        <div class="post" data-one-id="1"></div>
        <div class="post" data-two-id="2"></div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-one-id': '1',
        'data-two-id': '2',
        'data-reflex-dataset': '.post'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple different classes', async () => {
    const parent = await fixture(html`
      <div>
        <div
          id="element"
          data-controller="foo"
          data-id="1"
          data-reflex-dataset=".post1 .post2 .post3 .post4"
        ></div>
        <div class="post1" data-one-id="1"></div>
        <div class="post2" data-two-id="2"></div>
        <div class="post3" data-three-id="3"></div>
        <div class="post4" data-four-id="4"></div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-one-id': '1',
        'data-two-id': '2',
        'data-three-id': '3',
        'data-four-id': '4',
        'data-reflex-dataset': '.post1 .post2 .post3 .post4'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for first occurence and stack data values if they overlap', async () => {
    const element = await fixture(html`
      <div
        id="element"
        data-controller="posts"
        data-id="1"
        data-reflex-dataset=".post"
        data-reflex-dataset-all=".post"
      >
        <div class="post" data-post-id="1"></div>
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-id="4"></div>
      </div>
    `)

    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-id': '1',
        'data-post-id': '1',
        'data-reflex-dataset': '.post',
        'data-reflex-dataset-all': '.post'
      },
      datasetAll: {
        'data-controller': ['posts'],
        'data-id': ['1'],
        'data-post-id': ['1', '2', '3', '4'],
        'data-reflex-dataset': ['.post'],
        'data-reflex-dataset-all': ['.post']
      }
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for data-reflex-dataset-all', async () => {
    const element = await fixture(html`
      <div
        id="element"
        data-controller="posts"
        data-post-id="1"
        data-reflex-dataset-all=".post"
      >
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-id="4"></div>
      </div>
    `)

    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-post-id': '1',
        'data-reflex-dataset-all': '.post'
      },
      datasetAll: {
        'data-controller': ['posts'],
        'data-post-id': ['1', '2', '3', '4'],
        'data-reflex-dataset-all': ['.post']
      }
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset if the plural of overlapped value is also used with data-reflex-dataset-all', async () => {
    const element = await fixture(html`
      <div
        id="element"
        data-controller="posts"
        data-post-ids="1"
        data-reflex-dataset=".post"
        data-reflex-dataset-all=".post"
      >
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-id="4"></div>
      </div>
    `)

    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-post-id': '2',
        'data-post-ids': '1',
        'data-reflex-dataset': '.post',
        'data-reflex-dataset-all': '.post'
      },
      datasetAll: {
        'data-controller': ['posts'],
        'data-post-id': ['2', '3', '4'],
        'data-post-ids': ['1'],
        'data-reflex-dataset': ['.post'],
        'data-reflex-dataset-all': ['.post']
      }
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset if both singular and plural key exists but no data-reflex-dataset-all is passed', async () => {
    const element = await fixture(html`
      <div
        id="element"
        data-controller="posts"
        data-post-id="1"
        data-reflex-dataset=".post"
      >
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-ids="4"></div>
      </div>
    `)

    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-post-id': '1',
        'data-post-ids': '4',
        'data-reflex-dataset': '.post'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for parent', async () => {
    const parent = await fixture(html`
      <div data-dont-include="me">
        <div data-controller="foo" data-parent-id="1">
          <div data-dont-include="me"></div>
          <div id="element" data-child-id="2" data-reflex-dataset="parent">
            <div data-dont-include="me"></div>
          </div>
        </div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-parent-id': '1',
        'data-child-id': '2',
        'data-reflex-dataset': 'parent'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for ancestors', async () => {
    const parent = await fixture(html`
      <div>
        <div data-dont-include="me"></div>
        <div data-controller="foo" data-grandparent-id="1">
          <div data-dont-include="me"></div>
          <div data-parent-id="2">
            <div data-dont-include="me"></div>
            <div id="element" data-child-id="3" data-reflex-dataset="ancestors">
              <div data-dont-include="me"></div>
            </div>
          </div>
        </div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-grandparent-id': '1',
        'data-parent-id': '2',
        'data-child-id': '3',
        'data-reflex-dataset': 'ancestors'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for descendants', async () => {
    const parent = await fixture(html`
      <div>
        <div data-dont-include="me"></div>
        <div
          data-controller="foo"
          id="element"
          data-id="1"
          data-reflex-dataset="descendants"
        >
          <div data-child-id="2">
            <div data-grandchild-id="3"></div>
          </div>
        </div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-child-id': '2',
        'data-grandchild-id': '3',
        'data-reflex-dataset': 'descendants'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for children', async () => {
    const parent = await fixture(html`
      <div data-dont-include="me">
        <div data-dont-include="me"></div>
        <div
          id="element"
          data-controller="foo"
          data-id="1"
          data-reflex-dataset="children"
        >
          <div data-child-one-id="1">
            <div data-dont-include="me"></div>
          </div>
          <div data-child-two-id="2">
            <div data-dont-include="me"></div>
          </div>
        </div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-child-one-id': '1',
        'data-child-two-id': '2',
        'data-reflex-dataset': 'children'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for siblings', async () => {
    const parent = await fixture(html`
      <div data-dont-include="me">
        <div
          id="element"
          data-controller="foo"
          data-id="1"
          data-reflex-dataset="siblings"
        >
          <div data-dont-include="me"></div>
        </div>
        <div data-sibling-one-id="1">
          <div data-dont-include="me"></div>
        </div>
        <div data-sibling-two-id="2">
          <div data-dont-include="me"></div>
        </div>
      </div>
    `)

    const element = parent.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-sibling-one-id': '1',
        'data-sibling-two-id': '2',
        'data-reflex-dataset': 'siblings'
      },
      datasetAll: {}
    }
    assert.deepStrictEqual(actual, expected)
  })
})
