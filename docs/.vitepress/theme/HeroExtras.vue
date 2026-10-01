<script setup lang="ts">
// Home hero: a copyable install command and a row of measured proof points.
// Reads frontmatter.install (string) and frontmatter.proof ({ value, label, link }[]).
import { ref } from 'vue'
import { useData, withBase } from 'vitepress'

const { frontmatter } = useData()
const copied = ref(false)
async function copy() {
  try {
    await navigator.clipboard.writeText(frontmatter.value.install)
    copied.value = true
    setTimeout(() => (copied.value = false), 1600)
  } catch {
    copied.value = false
  }
}
const href = (link: string) => (link.startsWith('/') ? withBase(link) : link)
</script>

<template>
  <div v-if="frontmatter.install || frontmatter.proof" class="sx-hero-extras">
    <div v-if="frontmatter.install" class="sx-install">
      <code tabindex="0"><span class="sx-install__prompt" aria-hidden="true">$</span> {{ frontmatter.install }}</code>
      <button type="button" class="sx-install__copy" :aria-label="copied ? 'Copied' : 'Copy install command'" @click="copy">
        {{ copied ? 'Copied' : 'Copy' }}
      </button>
      <span class="sx-visually-hidden" aria-live="polite">{{ copied ? 'Install command copied' : '' }}</span>
    </div>
    <ul v-if="frontmatter.proof" class="sx-proof">
      <li v-for="p in frontmatter.proof" :key="p.value">
        <a :href="href(p.link)">
          <strong>{{ p.value }}</strong>
          <span>{{ p.label }}</span>
        </a>
      </li>
    </ul>
  </div>
</template>
