import { assert } from '@open-wc/testing'
import { camelize } from '../utils'

describe('camelize', () => {
  it('returns camelized simple value', () => {
    assert(camelize('example') === 'Example')
  })

  it('returns camelized simple value without leading uppercase', () => {
    assert(camelize('example', false) === 'example')
  })

  it('returns camelized complex value', () => {
    assert(camelize('complex_example test') === 'ComplexExampleTest')
  })

  it('returns camelized complex value without leading uppercase', () => {
    assert(camelize('complex_example test', false) === 'complexExampleTest')
  })
})
