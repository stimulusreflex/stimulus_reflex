export default {
  title: "StimulusReflex",
  description: "TODO",
  ignoreDeadLinks: false,
  lastUpdated: true,
  themeConfig: {
    siteTitle: "StimulusReflex",
    logo: "",
    nav: [
      { text: 'GitHub', link: 'https://github.com/stimulusreflex/stimulus_reflex' },
      { text: 'Changelog', link: 'https://github.com/stimulusreflex/stimulus_reflex/releases' },
      { text: 'CableReady', link: 'https://cableready.stimulusreflex.com' },
    ],
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
