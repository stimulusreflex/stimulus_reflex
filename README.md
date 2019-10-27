<p align="center">
  <a href="https://codefund.io/properties/525/visit-sponsor">
    <img src="https://codefund.io/properties/525/sponsor" />
  </a>
</p>

[![Lines of Code](http://img.shields.io/badge/lines_of_code-516-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://api.codeclimate.com/v1/badges/2b24fdbd1ae37a24bedb/maintainability)](https://codeclimate.com/github/hopsoft/stimulus_reflex/maintainability)
![Prettier-Standard](https://github.com/hopsoft/stimulus_reflex/workflows/Prettier-Standard/badge.svg)
![StandardRB](https://github.com/hopsoft/stimulus_reflex/workflows/StandardRB/badge.svg)
![Tests](https://github.com/hopsoft/stimulus_reflex/workflows/Tests/badge.svg)

![Logo](https://raw.githubusercontent.com/hopsoft/stimulus_reflex/master/assets/stimulus-reflex-logo.svg?sanitize=true)

# StimulusReflex

_reflex_ - an action that is performed as a response to a stimulus

**Build reactive applications with the Rails tooling you already know and love.** StimulusReflex is designed to work perfectly with [server rendered HTML](https://guides.rubyonrails.org/action_view_overview.html), [Russian doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), [Stimulus](https://stimulusjs.org/), [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA), etc... and strives to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/).

_Inspired by [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670)._ 🙌

## Docs

- [Official Documentation](https://docs.stimulusreflex.com)

## Demos

- http://expo.stimulusreflex.com

## Contributing

### Code of Conduct

Everyone interacting with StimulusReflex is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md)

### Coding Standards

This project uses [Standard](https://github.com/testdouble/standard) for Ruby code
and [Prettier-Standard](https://github.com/sheerun/prettier-standard) for JavaScript code to minimize bike shedding related to source formatting.

Please run `./bin/standardize` prior submitting pull requests.

View the [wiki](https://github.com/hopsoft/stimulus_reflex/wiki/Editor-Configuration) to see recommendations for configuring your editor to work best with the project.

### Releasing

1. Bump version number at `lib/stimulus_reflex/version.rb`
1. Run `rake build`
1. Run `rake release`
1. Change directories `cd ./javascript`
1. Run `yarn publish` - NOTE: this will throw a fatal error because the tag already exists but the package will still publish

## License

StimulusReflex is released under the [MIT License](LICENSE.txt).
