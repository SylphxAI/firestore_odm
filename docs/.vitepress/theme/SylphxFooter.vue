<script setup lang="ts">
// Sylphx shared docs footer. Identical in every Sylphx OSS docs site; per-site
// values come from themeConfig.sylphx in .vitepress/config.
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const props = defineProps<{ where: 'doc' | 'page' }>()
const { frontmatter, page, theme } = useData()

const isDocLayout = computed(() => {
  const layout = frontmatter.value.layout
  return !page.value.isNotFound && layout !== 'home' && layout !== 'page'
})
const show = computed(() => (props.where === 'doc') === isDocLayout.value)

const site = computed(() => theme.value.sylphx as {
  product: string
  links: { text: string; href: string }[]
  license: string
})

const family = [
  { name: 'anymd', href: 'https://sylphxai.github.io/anymd/' },
  { name: 'repomap', href: 'https://sylphxai.github.io/repomap/' },
  { name: 'lockdocs', href: 'https://sylphxai.github.io/lockdocs/' },
  { name: 'firestore_odm', href: 'https://sylphxai.github.io/firestore_odm/' },
  { name: 'Google Photos Delete Tool', href: 'https://sylphxai.github.io/Google-Photos-Delete-Tool/' },
]
const others = computed(() => family.filter((p) => p.name !== site.value.product))
const year = new Date().getFullYear()
const href = (link: string) => (link.startsWith('/') ? withBase(link) : link)
</script>

<template>
  <component :is="where === 'page' ? 'footer' : 'aside'" v-if="show" class="sx-footer" :class="`sx-footer--${where}`" aria-label="Sylphx">
    <div class="sx-footer__inner">
      <nav class="sx-footer__row" :aria-label="`${site.product} links`">
        <a v-for="l in site.links" :key="l.href" :href="href(l.href)">{{ l.text }}</a>
      </nav>
      <nav class="sx-footer__row" aria-label="More from Sylphx">
        <span class="sx-footer__label">More from Sylphx</span>
        <a v-for="p in others" :key="p.href" :href="p.href">{{ p.name }}</a>
      </nav>
      <p class="sx-footer__legal">
        © {{ year }} Sylphx Limited. Registered in England and Wales, company no. 16438428.
        Registered office: 128 City Road, London EC1V 2NX, United Kingdom.
        Phone <a href="tel:+443333357935">+44 333 335 7935</a>.
        Email <a href="mailto:hi@sylphx.com">hi@sylphx.com</a>.
      </p>
      <nav class="sx-footer__row sx-footer__row--legal" aria-label="Legal">
        <a href="https://sylphx.com/legal/privacy">Privacy</a>
        <a href="https://sylphx.com/legal/terms">Terms</a>
        <a href="https://sylphx.com/legal/cookies">Cookies</a>
        <a :href="site.license">MIT License</a>
        <a href="https://sylphx.com">sylphx.com</a>
      </nav>
    </div>
  </component>
</template>
