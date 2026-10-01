<script setup lang="ts">
// Home: the product visual between the hero and the feature grid.
// Reads frontmatter.media: { kind: 'video' | 'image', src, poster?, alt, caption?, link?, linkText? }.
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const { frontmatter } = useData()
const m = computed(() => frontmatter.value.media)
const u = (s?: string) => (s && s.startsWith('/') ? withBase(s) : s)
</script>

<template>
  <figure v-if="m" class="sx-media">
    <video v-if="m.kind === 'video'" :src="u(m.src)" :poster="u(m.poster)" autoplay loop muted playsinline
      preload="metadata" :aria-label="m.alt" width="1600" height="1000" />
    <img v-else :src="u(m.src)" :alt="m.alt" width="1400" height="780" decoding="async" fetchpriority="high" />
    <figcaption v-if="m.caption">
      {{ m.caption }}
      <a v-if="m.link" :href="u(m.link)">{{ m.linkText }}</a>
    </figcaption>
  </figure>
</template>
