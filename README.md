<p align="center">
  <img src="https://github.com/stimulusreflex/stimulus_reflex/blob/main/assets/stimulus-reflex-logo-with-copy.png?raw=1" width="360" />
  <h1 align="center">Welcome to StimulusReflex 👋</h1>
  <p align="center">
    <img src="https://img.shields.io/gem/v/stimulus_reflex.svg?color=red" />
    <img src="https://img.shields.io/npm/v/stimulus_reflex.svg?color=blue" />
    <a href="https://www.npmjs.com/package/stimulus_reflex">
      <img alt="downloads" src="https://img.shields.io/npm/dm/stimulus_reflex.svg?color=blue" target="_blank" />
    </a>
    <a href="https://github.com/stimulusreflex/stimulus_reflex/blob/main/LICENSE.txt">
      <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-brightgreen.svg" target="_blank" />
    </a>
    <a href="https://docs.stimulusreflex.com/" target="_blank">
      <img alt="Documentation" src="https://img.shields.io/badge/documentation-yes-brightgreen.svg" />
    </a>
    <br />
    <a href="#badge">
      <img alt="semantic-release" src="https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg">
    </a>
    <a href="https://github.com/testdouble/standard" target="_blank">
      <img alt="Ruby Code Style" src="https://img.shields.io/badge/Ruby_Code_Style-standard-brightgreen.svg" />
    </a>
    <a href="https://github.com/sheerun/prettier-standard" target="_blank">
      <img alt="JavaScript Code Style" src="https://img.shields.io/badge/JavaScript_Code_Style-prettier_standard-ff69b4.svg" />
    </a>
    <br />
    <a target="_blank" rel="noopener noreferrer" href="https://github.com/stimulusreflex/stimulus_reflex/actions/workflows/prettier-standard.yml">
      <img src="https://github.com/stimulusreflex/stimulus_reflex/workflows/Prettier-Standard/badge.svg" alt="Prettier-Standard" style="max-width:100%;">
    </a>
    <a target="_blank" rel="noopener noreferrer" href="https://github.com/stimulusreflex/stimulus_reflex/actions/workflows/standardrb.yml">
      <img src="https://github.com/stimulusreflex/stimulus_reflex/workflows/StandardRB/badge.svg" alt="StandardRB" style="max-width:100%;">
    </a>
    <a target="_blank" rel="noopener noreferrer" href="https://github.com/stimulusreflex/stimulus_reflex/actions/workflows/tests.yml">
      <img src="https://github.com/stimulusreflex/stimulus_reflex/workflows/Tests/badge.svg" alt="Tests">
    </a>
  </p>
</p>
<br />


### 🎉 **An exciting new way to build modern, reactive, real-time apps with Ruby on Rails.**

StimulusReflex eliminates the complexity imposed by full-stack frontend frameworks.
And, it's fast.

It works seamlessly with the Rails tooling you already know and love.

- Server-rendered HTML, delivered in milliseconds over the wire via Websockets
- ERB templates and partials, with first-class [ViewComponent](https://github.com/github/view_component) support
- [Russian doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching) and [ActiveJob](https://guides.rubyonrails.org/active_job_basics.html)
- [StimulusJS](https://stimulus.hotwired.dev/) and [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA)/[Turbo Drive](https://turbo.hotwired.dev/reference/drive)
- Built with [CableReady](https://www.youtube.com/watch?v=dPzv2qsj5L8), our secret power-move

**Our goal is to help small teams do big things with familiar tools.**

This project strives to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/).

## 📚 Docs

- [StimulusReflex Documentation](https://docs.stimulusreflex.com)
- [CableReady Documentation](https://cableready.stimulusreflex.com)
- [StimulusReflex Cheatsheet](https://devhints.io/stimulus-reflex)

## ✨ Demos

- [Build a Twitter Clone in 10 Minutes](https://youtu.be/F5hA79vKE_E) (video)
- [BeastMode](https://beastmode.leastbad.com/) - faceted search, with filtering, sorting and pagination
- [StimulusReflex Patterns](https://www.stimulusreflexpatterns.com/patterns/) - single-file SR apps hosted on Glitch
- [Boxdrop](https://www.boxdrop.io) - a Dropbox-inspired [concept demo](https://github.com/marcoroth/boxdrop/)

## 👩‍👩‍👧 Discord Community

Please join over 2000 of us on [Discord](https://discord.gg/stimulus-reflex) for support getting started, as well as active discussions around Rails, Hotwire, Stimulus, Phlex and CableReady.

![](https://img.shields.io/discord/629472241427415060)

Stop by #newcomers and introduce yourselves!

## 💙 Support

Your best bet is to ask for help on Discord before filing an issue on GitHub. We are happy to help, and we ask people who need help to come with all relevant code to look at. A git repo is preferred, but Gists are fine, too. If you need a template for reproducing your issue, try [this](https://github.com/leastbad/stimulus_reflex_harness).

Please note that we are not actively providing support on Stack Overflow. If you post there, we likely won't see it.

## 🚀 Installation and upgrading

CLI and manual setup procedures are fully detailed in the [official docs](https://docs.stimulusreflex.com/hello-world/setup.html).

### Rubygem

```sh
bundle add stimulus_reflex
```

### JavaScript

There are a few ways to install the StimulusReflex JavaScript client, depending on your application setup.

#### ESBuild / Webpacker

```sh
yarn add stimulus_reflex
```

#### Importmaps

```ruby
# config/importmap.rb

# ...

pin 'stimulus_reflex', to: 'stimulus_reflex.js', preload: true
```

#### Rails Asset pipeline (Sprockets):

```html+erb
<!-- app/views/layouts/application.html.erb -->

<%= javascript_include_tag "stimulus_reflex.umd.js", "data-turbo-track": "reload" %>
```

## 🙏 Contributing

### Code of Conduct

Everyone interacting with the StimulusReflex project’s codebases, issue trackers, chat rooms and forum is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

### Coding Standards

This project uses [Standard](https://github.com/testdouble/standard) for Ruby code
and [Prettier-Standard](https://github.com/sheerun/prettier-standard) for JavaScript code to minimize bike shedding related to source formatting.

Please run `./bin/standardize` prior to submitting pull requests.

View the [wiki](https://github.com/stimulusreflex/stimulus_reflex/wiki/Editor-Configuration) to see recommendations for configuring your editor to work best with the project.

## 📦 Releasing

1. Always publish CableReady first!
1. Update the `cable_ready` dependency version in `stimulus_reflex.gemspec` and `package.json`
1. Make sure that you run `yarn` and `bundle` to pick up the latest.
1. Bump version number at `lib/stimulus_reflex/version.rb`. Pre-release versions use `.preN`
1. Run `bundle exec rake build` and `yarn build`
1. Run `bin/standardize`
1. Commit and push changes to GitHub
1. Run `bundle exec rake release`
1. Run `yarn publish --no-git-tag-version`
1. Yarn will prompt you for the new version. Pre-release versions use `-preN`
1. Commit and push changes to GitHub
1. Create a new release on GitHub ([here](https://github.com/stimulusreflex/stimulus_reflex/releases)) and generate the changelog for the stable release for it

## 📝 License

StimulusReflex is released under the [MIT License](LICENSE.txt).

---

_Originally inspired by [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670)._ 🙌
