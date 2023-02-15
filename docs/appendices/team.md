<script setup>
  import { VPTeamMembers } from 'vitepress/theme'

  const members = [
    {
      avatar: 'https://www.github.com/andrewmcodes.png',
      name: 'Andrew Mason',
      title: 'Core Team',
      links: [
        { icon: 'github', link: 'https://github.com/andrewmcodes' },
        { icon: 'twitter', link: 'https://twitter.com/andrewmcodes' },
        { icon: 'mastodon', link: 'https://ruby.social/@andrewmcodes' },
      ]
    },
    {
      avatar: 'https://www.github.com/julianrubisch.png',
      name: 'Julian Rubisch',
      title: 'Core Team',
      links: [
        { icon: 'github', link: 'https://github.com/julianrubisch' },
        { icon: 'twitter', link: 'https://twitter.com/julian_rubisch' },
        { icon: 'mastodon', link: 'https://ruby.social/@julianrubisch' },
      ]
    },
    {
      avatar: 'https://www.github.com/marcoroth.png',
      name: 'Marco Roth',
      title: 'Core Team',
      links: [
        { icon: 'github', link: 'https://github.com/marcoroth' },
        { icon: 'twitter', link: 'https://twitter.com/marcoroth_' },
        { icon: 'mastodon', link: 'https://ruby.social/@marcoroth' },
      ]
    },
    {
      avatar: 'https://www.github.com/hopsoft.png',
      name: 'Nate Hopkins',
      title: 'Creator and Core Team',
      links: [
        { icon: 'github', link: 'https://github.com/hopsoft' },
        { icon: 'twitter', link: 'https://twitter.com/hopsoft' },
        { icon: 'mastodon', link: 'https://ruby.social/@hopsoft' },
      ]
    },
  ]
</script>

# Core Team

The StimulusReflex and CableReady Core Team

<VPTeamMembers size="small" :members="members" />
