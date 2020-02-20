[![Lines of Code](http://img.shields.io/badge/lines_of_code-608-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://api.codeclimate.com/v1/badges/2b24fdbd1ae37a24bedb/maintainability)](https://codeclimate.com/github/hopsoft/stimulus_reflex/maintainability)
![Prettier-Standard](https://github.com/hopsoft/stimulus_reflex/workflows/Prettier-Standard/badge.svg)
![StandardRB](https://github.com/hopsoft/stimulus_reflex/workflows/StandardRB/badge.svg)
![Tests](https://github.com/hopsoft/stimulus_reflex/workflows/Tests/badge.svg)

# StimulusReflex

**You just discovered an exciting new way to build modern, reactive, real-time apps with Ruby on Rails.**

StimulusReflex eliminates the complexity imposed by full-stack frontend frameworks.
And, it's fast.

It works with seamlessly with the Rails tooling you already know and love.

- [Server rendered HTML over the wire](https://guides.rubyonrails.org/action_view_overview.html)
- [ERB, or your favorite templating engine](https://www.ruby-toolbox.com/categories/template_engines)
- [Russian doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching)
- [Stimulus](https://stimulusjs.org/)
- [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA)
- etc...

**The goal is to help small teams do big things with familiar tools.**

>  This project strives to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/).

_Originally inspired by [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670)._ 🙌

## Docs

- [Official Documentation](https://docs.stimulusreflex.com)

## Demos

- http://expo.stimulusreflex.com

## Community

- [Discourse](https://stimulus-reflex.discourse.group) - long form async communication
- [Discord](https://discord.gg/XveN625) - chat root

## Contributing

### Code of Conduct

Everyone interacting with the StimulusReflex project’s codebases, issue trackers, chat rooms and forum is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

### Coding Standards

This project uses [Standard](https://github.com/testdouble/standard) for Ruby code
and [Prettier-Standard](https://github.com/sheerun/prettier-standard) for JavaScript code to minimize bike shedding related to source formatting.

Please run `./bin/standardize` prior to submitting pull requests.

View the [wiki](https://github.com/hopsoft/stimulus_reflex/wiki/Editor-Configuration) to see recommendations for configuring your editor to work best with the project.

### Releasing

1. Bump version number at `lib/stimulus_reflex/version.rb`
1. Run `rake build`
1. Run `rake release`
1. Change directories `cd ./javascript`
1. Run `yarn publish` - NOTE: this will throw a fatal error because the tag already exists but the package will still publish

## License

StimulusReflex is released under the [MIT License](LICENSE.txt).
