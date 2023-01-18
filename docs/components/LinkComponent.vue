<style>
  .section-link-component {
    display: flex;
    flex-direction: column;
    flex-shrink: 0;
  }

  .section-link-component .link {
    display: block;
    border: 1px solid var(--vp-c-divider);
    border-radius: 8px;
    padding: 11px 16px 13px;
    width: 100%;
    height: 100%;
    transition: border-color .25s;
  }

  .section-link-component .desc {
    display: block;
    line-height: 20px;
    font-size: 12px;
    font-weight: 500;
    color: var(--vp-c-text-2);
  }

  .section-link-component .title {
    display: block;
    line-height: 20px;
    font-size: 14px;
    font-weight: 500;
    color: var(--vp-c-brand);
    transition: color .25s;
  }
</style>

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
  <div class="section-link-component">
    <a class="link" :href="href">
      <span class="desc">{{ title }}</span>
      <span class="title">{{ name }}</span>
    </a>
  </div>
</template>
