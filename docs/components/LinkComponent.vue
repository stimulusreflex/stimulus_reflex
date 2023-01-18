<script>
  export default {
    props: {
      name: { type: String },
      href: { type: String, default: '/' },
      title: { type: String, default: 'Section' }
    },
    data() {
      return {
        href: this.href,
        name: this.name,
        title: this.title,
      }
    }
  }
</script>

<template>
  <div class="pager">
    <a class="pager-link prev" :href="href" data-v-29ec59c0="">
      <span class="desc" data-v-29ec59c0="">{{ title }}</span>
      <span class="title" data-v-29ec59c0="">{{ name }}</span>
    </a>
  </div>
</template>
