import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Firestore ODM",
  description: "A type-safe ODM for Firestore on Dart & Flutter",
  base: '/firestore_odm/',
  themeConfig: {
    search: {
      provider: 'local'
    },
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/introduction' },
      {
        text: 'Packages',
        items: [
          { text: 'firestore_odm', link: 'https://pub.dev/packages/firestore_odm' },
          { text: 'firestore_odm_builder', link: 'https://pub.dev/packages/firestore_odm_builder' },
          { text: 'firestore_odm_annotation', link: 'https://pub.dev/packages/firestore_odm_annotation' },
        ]
      }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
          items: [
            { text: 'What is Firestore ODM?', link: '/guide/introduction' },
            { text: 'Getting Started', link: '/guide/getting-started' },
            { text: 'Migration Guide', link: '/guide/migration-guide' },
          ]
        },
        {
          text: 'Core Concepts',
          items: [
            { text: 'Data Modeling', link: '/guide/data-modeling' },
            { text: 'Schema Definition', link: '/guide/schema-definition' },
            { text: 'Document ID', link: '/guide/document-id' },
            { text: 'Server Timestamps', link: '/guide/server-timestamps' },
            { text: 'Multiple ODM Instances', link: '/guide/multiple-instances' },
          ]
        },
        {
          text: 'Working with Documents',
          items: [
            { text: 'Reading Documents', link: '/guide/reading-documents' },
            { text: 'Writing Documents', link: '/guide/writing-documents' },
          ]
        },
        {
          text: 'Querying',
          items: [
            { text: 'Fetching Data', link: '/guide/fetching-data' },
            { text: 'Filtering Data', link: '/guide/filtering-data' },
            { text: 'Ordering & Limiting', link: '/guide/ordering-and-limiting' },
            { text: 'Pagination', link: '/guide/pagination' },
            { text: 'Bulk Operations', link: '/guide/bulk-operations' },
          ]
        },
        {
          text: 'Advanced Features',
          items: [
            { text: 'Transactions', link: '/guide/transactions' },
            { text: 'Batch Operations', link: '/guide/batch-operations' },
            { text: 'Aggregations', link: '/guide/aggregations' },
            { text: 'Subcollections', link: '/guide/subcollections' },
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/SylphxAI/firestore_odm' }
    ]
  }
})