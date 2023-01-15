export default {
  title: "StimulusReflex",
  description: "TODO",
  ignoreDeadLinks: false,
  lastUpdated: true,
  themeConfig: {
    siteTitle: "StimulusReflex",
    logo: "https://www.gitbook.com/cdn-cgi/image/width=40,height=40,fit=contain,dpr=1,format=auto/https%3A%2F%2F3036285672-files.gitbook.io%2F~%2Ffiles%2Fv0%2Fb%2Fgitbook-legacy-files%2Fo%2Fspaces%252F-Lpnm81iPOBUa9lAmLxg%252Favatar.png%3Fgeneration%3D1570308033034858%26alt%3Dmedia",
    outline: [2, 3],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/stimulusreflex/stimulus_reflex' },
      { icon: 'twitter', link: 'https://twitter.com/stimulusreflex' }
    ],
    editLink: {
      pattern: 'https://github.com/stimulusreflex/stimulus_reflex/edit/master/docs/:path',
      text: 'Edit this page on GitHub'
    },
    nav: [
      { text: 'GitHub', link: 'https://github.com/stimulusreflex/stimulus_reflex' },
      { text: 'Changelog', link: 'https://github.com/stimulusreflex/stimulus_reflex/releases' },
      { text: 'CableReady', link: 'https://cableready.stimulusreflex.com' },
    ],
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2023'
    },
    sidebar: [
      {
        text: "Hello World",
        collapisble: true,
        items: [
          { text: "Welcome", link: "/" },
          { text: "Setup", link: "/hello-world/setup" },
          { text: "Quick Start", link: "/hello-world/quickstart" },
        ]
      },
      {
        text: "Guide",
        collapisble: true,
        items: [
          { text: "Calling Reflexes", link: "/guide/reflexes" },
          { text: "Reflex Classes", link: "/guide/reflex-classes" },
          { text: "Integrating CableReady", link: "/guide/cableready" },
          { text: "Life-cycle", link: "/guide/lifecycle" },
          { text: "Morphs", link: "/guide/morph-modes" },
          { text: "Authentication", link: "/guide/authentication" },
          { text: "Persistence", link: "/guide/persistence" },
          { text: "Useful Patterns", link: "/guide/patterns" },
          { text: "Forms", link: "/guide/working-with-forms" },
        ]
      },
      {
        text: "Appendices",
        collapisble: true,
        items: [
          { text: "Working with Events", link: "/appendices/events" },
          { text: "Testing \(WIP\)", link: "/appendices/testing" },
          { text: "Deployment", link: "/appendices/deployment" },
          { text: "Troubleshooting", link: "/appendices/troubleshooting" },
          { text: "Release History", link: "/appendices/release-history" },
          { text: "Glossary", link: "/appendices/glossary" },
        ]
      }
    ]
  }
}
