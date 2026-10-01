import { h } from 'vue'
import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import SylphxFooter from './SylphxFooter.vue'
import HeroExtras from './HeroExtras.vue'
import HomeMedia from './HomeMedia.vue'
import './custom.css'
import './sylphx.css'

export default {
  extends: DefaultTheme,
  Layout: () =>
    h(DefaultTheme.Layout, null, {
      'home-hero-actions-after': () => h(HeroExtras),
      'home-features-before': () => h(HomeMedia),
      'doc-after': () => h(SylphxFooter, { where: 'doc' }),
      'layout-bottom': () => h(SylphxFooter, { where: 'page' }),
    }),
} satisfies Theme
