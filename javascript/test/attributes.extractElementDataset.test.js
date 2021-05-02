import assert from 'assert'
import { JSDOM } from 'jsdom'
import { extractElementDataset } from '../attributes'
import reflexes from '../reflexes'
import { defaultSchema } from '../schema'

describe('extractElementDataset', () => {
  beforeEach(() => {
    reflexes.app = {}
    reflexes.app.schema = defaultSchema
    reflexes.app.schema.reflexDatasetAttribute = 'data-reflex-dataset'
  })

  it('should return dataset for element without data attributes', () => {
    const dom = new JSDOM('<a id="example">Test</a>')
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {},
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element', () => {
    const dom = new JSDOM(
      '<a id="example" data-controller="foo" data-reflex="bar" data-info="12345">Test</a>'
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element without combining dataset from parent', () => {
    const dom = new JSDOM(
      `
      <div data-parent-id="should not be included">
        <a id="example" data-controller="foo" data-reflex="bar" data-info="12345">Test</a>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element but without providing the dataset attribute', () => {
    const dom = new JSDOM(
      `
      <div data-parent-id="should not be included">
        <a id="example" data-controller="foo" data-reflex="bar" data-info="12345">Test</a>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(extractElementDataset(element), expected)

    reflexes.app.schema.reflexDatasetAttribute = null
    assert.deepStrictEqual(extractElementDataset(element), expected)

    reflexes.app.schema.reflexDatasetAttribute = undefined
    assert.deepStrictEqual(extractElementDataset(element), expected)

    reflexes.app.schema.reflexDatasetAttribute = ''
    assert.deepStrictEqual(extractElementDataset(element), expected)

    reflexes.app.schema.reflexDatasetAttribute = 'blah'
    assert.deepStrictEqual(extractElementDataset(element), expected)

    reflexes.app.schema.reflexDatasetAttribute = {}
    assert.deepStrictEqual(extractElementDataset(element), expected)
  })

  it('should return dataset for element with data-reflex-dataset without value', () => {
    const dom = new JSDOM(
      `
      <div data-parent-id="should not be included">
        <a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset>Test</a>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345',
        'data-reflex-dataset': ''
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element with data-reflex-dataset and other value than "combined"', () => {
    const dom = new JSDOM(
      `
      <div data-parent-id="should not be included">
        <a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset="whut">Test</a>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345',
        'data-reflex-dataset': 'whut'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element with data-reflex-dataset="combined"', () => {
    const dom = new JSDOM(
      `
      <body data-body-id="body">
        <div data-grandparent-id="456">
          <div data-parent-id="123"><a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset="combined">Test</a></div>
        </div>
      </body>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345',
        'data-grandparent-id': '456',
        'data-parent-id': '123',
        'data-body-id': 'body',
        'data-reflex-dataset': 'combined'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for element with overloaded data attributes', () => {
    const dom = new JSDOM(
      `
      <div data-info="this is the outer one">
        <a data-info="this is the inner one" data-reflex-dataset="combined">Test</a>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-info': 'this is the inner one',
        'data-reflex-dataset': 'combined'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return with combined parent attributes only for elements with data-reflex-dataset', () => {
    const dom = new JSDOM(
      `
      <div data-parent-id="123">
        <button id="button1" data-reflex-dataset="combined">Something</button>
        <button id="button2">Another thing</button>
      </div>
      `
    )
    global.document = dom.window.document

    const button1 = dom.window.document.querySelector('#button1')
    const actual_button1 = extractElementDataset(button1)
    const expected_button1 = {
      dataset: {
        'data-parent-id': '123',
        'data-reflex-dataset': 'combined'
      },
      datasetArray: {}
    }

    const button2 = dom.window.document.querySelector('#button2')
    const actual_button2 = extractElementDataset(button2)
    const expected_button2 = {
      dataset: {},
      datasetArray: {}
    }

    assert.deepStrictEqual(actual_button1, expected_button1)
    assert.deepStrictEqual(actual_button2, expected_button2)
  })

  it('should return dataset for element with different renamed data-reflex-dataset attribute', () => {
    const dom = new JSDOM(
      `<body data-body-id="body">
        <div data-grandparent-id="456">
          <div data-parent-id="123">
            <a id="example" data-controller="foo" data-reflex="bar" data-info="12345" data-reflex-dataset-renamed="combined">Test</a>
          </div>
        </div>
      </body>
      `
    )
    global.document = dom.window.document
    reflexes.app.schema.reflexDatasetAttribute = 'data-reflex-dataset-renamed'
    const element = dom.window.document.querySelector('a')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-reflex': 'bar',
        'data-info': '12345',
        'data-grandparent-id': '456',
        'data-parent-id': '123',
        'data-body-id': 'body',
        'data-reflex-dataset-renamed': 'combined'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for id', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-reflex-dataset="#timmy"></div>
      <div id="timmy" data-age="12"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-age': '12',
        'data-reflex-dataset': '#timmy'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for tag name', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-reflex-dataset="span"></div>
      <span data-span-one="1"></span>
      <span data-span-two="2"></span>
      <div data-div="other"></div>
      <div data-div="other"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-span-one': '1',
        'data-span-two': '2',
        'data-reflex-dataset': 'span'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for tag name with class', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-reflex-dataset="span.post"></div>
      <span class="post" data-span-one="1"></span>
      <span class="post" data-span-two="2"></span>
      <span data-span="other"></span>
      <span data-span="other"></span>
      <div data-div="other"></div>
      <div data-div="other"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-span-one': '1',
        'data-span-two': '2',
        'data-reflex-dataset': 'span.post'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple elements with the same ids', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-reflex-dataset="#timmy"></div>
      <div id="timmy" data-one="1"></div>
      <div id="timmy" data-two="2"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-one': '1',
        'data-two': '2',
        'data-reflex-dataset': '#timmy'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple different ids', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-reflex-dataset="#post1 #post2 #post3 #post4"></div>
      <div id="post1" data-one-id="1"></div>
      <div id="post2" data-two-id="2"></div>
      <div id="post3" data-three-id="3"></div>
      <div id="post4" data-four-id="4"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
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
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for class', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-id="1" data-reflex-dataset=".sarah"></div>
      <div class="sarah" data-job="clerk"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-job': 'clerk',
        'data-reflex-dataset': '.sarah'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple elements with the same class', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-id="1" data-reflex-dataset=".post"></div>
      <div class="post" data-one-id="1"></div>
      <div class="post" data-two-id="2"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-one-id': '1',
        'data-two-id': '2',
        'data-reflex-dataset': '.post'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for multiple different classes', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="foo" data-id="1" data-reflex-dataset=".post1 .post2 .post3 .post4"></div>
      <div class="post1" data-one-id="1"></div>
      <div class="post2" data-two-id="2"></div>
      <div class="post3" data-three-id="3"></div>
      <div class="post4" data-four-id="4"></div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
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
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for first occurence and stack data values if they overlap', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="posts" data-id="1" data-reflex-dataset=".post" data-reflex-dataset-array=".post">
        <div class="post" data-post-id="1"></div>
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-id="4"></div>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-id': '1',
        'data-post-id': '1',
        'data-reflex-dataset': '.post',
        'data-reflex-dataset-array': '.post'
      },
      datasetArray: {
        'data-controller': ['posts'],
        'data-id': ['1'],
        'data-post-id': ['1', '2', '3', '4'],
        'data-reflex-dataset': ['.post'],
        'data-reflex-dataset-array': ['.post']
      }
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for data-reflex-dataset-array', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="posts" data-post-id="1" data-reflex-dataset-array=".post">
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-id="4"></div>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-post-id': '1',
        'data-reflex-dataset-array': '.post'
      },
      datasetArray: {
        'data-controller': ['posts'],
        'data-post-id': ['1', '2', '3', '4'],
        'data-reflex-dataset-array': ['.post']
      }
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset if the plural of overlapped value is also used with data-reflex-dataset-array', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="posts" data-post-ids="1" data-reflex-dataset=".post" data-reflex-dataset-array=".post">
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-id="4"></div>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-post-id': '2',
        'data-post-ids': '1',
        'data-reflex-dataset': '.post',
        'data-reflex-dataset-array': '.post'
      },
      datasetArray: {
        'data-controller': ['posts'],
        'data-post-id': ['2', '3', '4'],
        'data-post-ids': ['1'],
        'data-reflex-dataset': ['.post'],
        'data-reflex-dataset-array': ['.post']
      }
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset if both singular and plural key exists but no data-reflex-dataset-array is passed', () => {
    const dom = new JSDOM(
      `
      <div id="element" data-controller="posts" data-post-id="1" data-reflex-dataset=".post">
        <div class="post" data-post-id="2"></div>
        <div class="post" data-post-id="3"></div>
        <div class="post" data-post-ids="4"></div>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'posts',
        'data-post-id': '1',
        'data-post-ids': '4',
        'data-reflex-dataset': '.post'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for parent', () => {
    const dom = new JSDOM(
      `
      <div data-dont-include="me">
        <div data-controller="foo" data-parent-id="1">
          <div data-dont-include="me"></div>
          <div id="element" data-child-id="2" data-reflex-dataset="parent">
            <div data-dont-include="me"></div>
          </div>
        </div>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-parent-id': '1',
        'data-child-id': '2',
        'data-reflex-dataset': 'parent'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for ancestors', () => {
    const dom = new JSDOM(
      `
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
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-grandparent-id': '1',
        'data-parent-id': '2',
        'data-child-id': '3',
        'data-reflex-dataset': 'ancestors'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for children', () => {
    const dom = new JSDOM(
      `
      <div data-dont-include="me">
        <div data-dont-include="me"></div>
        <div id="element" data-controller="foo" data-id="1" data-reflex-dataset="children">
          <div data-child-one-id="1">
            <div data-dont-include="me"></div>
          </div>
          <div data-child-two-id="2">
            <div data-dont-include="me"></div>
          </div>
        </div>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-child-one-id': '1',
        'data-child-two-id': '2',
        'data-reflex-dataset': 'children'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })

  it('should return dataset for siblings', () => {
    const dom = new JSDOM(
      `
      <div data-dont-include="me">
        <div id="element" data-controller="foo" data-id="1" data-reflex-dataset="siblings">
          <div data-dont-include="me"></div>
        </div>
        <div data-sibling-one-id="1">
          <div data-dont-include="me"></div>
        </div>
        <div data-sibling-two-id="2">
          <div data-dont-include="me"></div>
        </div>
      </div>
      `
    )
    global.document = dom.window.document
    const element = dom.window.document.querySelector('#element')
    const actual = extractElementDataset(element)
    const expected = {
      dataset: {
        'data-controller': 'foo',
        'data-id': '1',
        'data-sibling-one-id': '1',
        'data-sibling-two-id': '2',
        'data-reflex-dataset': 'siblings'
      },
      datasetArray: {}
    }
    assert.deepStrictEqual(actual, expected)
  })
})
