import { defineConfig } from 'vitepress'

const title = 'firestore_odm'
const description =
  'Type-safe Firestore ODM for Flutter and Dart — the maintained successor to cloud_firestore_odm.'
const site = 'https://sylphxai.github.io/firestore_odm/'

export default defineConfig({
  title,
  description,
  base: '/firestore_odm/',
  lang: 'en',
  // Extensionless page URLs, matching the links in the README and on pub.dev.
  cleanUrls: true,
  // Decision records stay in the repository, not on the site.
  srcExclude: ['adr/**'],
  appearance: 'force-dark',
  lastUpdated: true,
  markdown: { theme: { light: 'github-light', dark: 'github-dark-default' } },
  sitemap: { hostname: site },
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/firestore_odm/favicon.svg' }],
    ['meta', { name: 'theme-color', content: '#0F0A1C' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: title }],
    ['meta', { property: 'og:image', content: `${site}og.png` }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { property: 'og:image:width', content: '1280' }],
    ['meta', { property: 'og:image:height', content: '640' }],
    ['meta', { property: 'og:image:alt', content: 'firestore_odm: type-safe Firestore ODM for Flutter and Dart' }],
    ['meta', { name: 'twitter:image', content: `${site}og.png` }],
  ],
  transformPageData(pageData) {
    const pageTitle = pageData.frontmatter.title ?? pageData.title ?? title
    const pageDescription = pageData.frontmatter.description ?? description
    pageData.frontmatter.head ??= []
    const pageUrl = site + pageData.relativePath.replace(/(^|\/)index\.md$/, '$1').replace(/\.md$/, '')
    pageData.frontmatter.head.push(
      ['link', { rel: 'canonical', href: pageUrl }],
      ['meta', { property: 'og:title', content: pageTitle }],
      ['meta', { property: 'og:description', content: pageDescription }],
      ['meta', { property: 'og:url', content: pageUrl }],
    )
  },
  themeConfig: {
    logo: { src: '/logo.svg', alt: '' },
    lastUpdated: { formatOptions: { dateStyle: 'medium' } },
    search: { provider: 'local' },
    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Migrate', link: '/guide/migrate-from-cloud-firestore-odm' },
      { text: 'Comparison', link: '/guide/comparison' },
      { text: 'Benchmarks', link: '/guide/benchmarks' },
      {
        text: 'Packages',
        items: [
          { text: 'firestore_odm', link: 'https://pub.dev/packages/firestore_odm' },
          { text: 'firestore_odm_builder', link: 'https://pub.dev/packages/firestore_odm_builder' },
          { text: 'firestore_odm_annotation', link: 'https://pub.dev/packages/firestore_odm_annotation' },
          { text: 'API reference', link: 'https://pub.dev/documentation/firestore_odm/latest/' },
        ],
      },
    ],
    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
          items: [
            { text: 'What is firestore_odm?', link: '/guide/introduction' },
            { text: 'Getting started', link: '/guide/getting-started' },
            { text: 'Comparison', link: '/guide/comparison' },
            { text: 'Benchmarks', link: '/guide/benchmarks' },
          ],
        },
        {
          text: 'Migration',
          items: [
            { text: 'From cloud_firestore_odm', link: '/guide/migrate-from-cloud-firestore-odm' },
            { text: 'From cloud_firestore', link: '/guide/migration-guide' },
            { text: 'From firestore_odm 4.x', link: '/guide/migration-guide-5' },
          ],
        },
        {
          text: 'Models and schema',
          items: [
            { text: 'Data modeling', link: '/guide/data-modeling' },
            { text: 'Schema definition', link: '/guide/schema-definition' },
            { text: 'Document ID', link: '/guide/document-id' },
            { text: 'Server timestamps', link: '/guide/server-timestamps' },
            { text: 'Multiple ODM instances', link: '/guide/multiple-instances' },
          ],
        },
        {
          text: 'Documents',
          items: [
            { text: 'Reading documents', link: '/guide/reading-documents' },
            { text: 'Writing documents', link: '/guide/writing-documents' },
            { text: 'Subcollections', link: '/guide/subcollections' },
          ],
        },
        {
          text: 'Queries',
          items: [
            { text: 'Fetching data', link: '/guide/fetching-data' },
            { text: 'Filtering', link: '/guide/filtering-data' },
            { text: 'Ordering and limiting', link: '/guide/ordering-and-limiting' },
            { text: 'Pagination', link: '/guide/pagination' },
            { text: 'Aggregations', link: '/guide/aggregations' },
            { text: 'Bulk operations', link: '/guide/bulk-operations' },
          ],
        },
        {
          text: 'Atomic writes',
          items: [
            { text: 'Transactions', link: '/guide/transactions' },
            { text: 'Batches', link: '/guide/batch-operations' },
          ],
        },
        {
          text: 'Flutter',
          items: [
            { text: 'FirestoreBuilder', link: '/guide/firestore-builder' },
            { text: 'Field validators', link: '/guide/validators' },
          ],
        },
      ],
    },
    sylphx: {
      product: 'firestore_odm',
      license: 'https://github.com/SylphxAI/firestore_odm/blob/main/LICENSE',
      links: [
        { text: 'Getting started', href: '/guide/getting-started' },
        { text: 'Benchmarks', href: '/guide/benchmarks' },
        { text: 'Changelog', href: 'https://pub.dev/packages/firestore_odm/changelog' },
        { text: 'GitHub', href: 'https://github.com/SylphxAI/firestore_odm' },
        { text: 'pub.dev', href: 'https://pub.dev/packages/firestore_odm' },
      ],
    },
    socialLinks: [{ icon: 'github', link: 'https://github.com/SylphxAI/firestore_odm' }],
    editLink: {
      pattern: 'https://github.com/SylphxAI/firestore_odm/edit/main/docs/:path',
    },
  },
})
