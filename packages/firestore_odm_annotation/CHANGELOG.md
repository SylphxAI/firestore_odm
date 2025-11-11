## 4.0.0-dev.1

 - Bump "firestore_odm_annotation" to `4.0.0-dev.1`.

## 4.0.0-dev

 - **FEAT**: supporting nested class withot manual import, filter and patcher done. ([37bf6d4b](https://github.com/SylphxAI/firestore_odm/commit/37bf6d4bb3b32454fef7be8c7d9f918e55701cc9))

## 3.0.2

 - Bump "firestore_odm_annotation" to `3.0.2`.

## 3.0.1

 - Bump "firestore_odm_annotation" to `3.0.1`.

## 3.0.0

## 1.3.0

 - **FEAT**: refactor project folder structure. ([d4907075](https://github.com/SylphxAI/firestore_odm/commit/d49070757a19ea643d73e2aa0664754f0c67da44))
 - **DOCS**: Update all documentation URLs to GitHub Pages. ([321ccdcd](https://github.com/SylphxAI/firestore_odm/commit/321ccdcd10f31374f6cd5b955fa3b7cb2d7f17fa))
 - **DOCS**: refactor and centralize README.md. ([7c121c62](https://github.com/SylphxAI/firestore_odm/commit/7c121c62981001803322ff5af1e2bb3f4593c46c))

## 1.2.0

 - **FEAT**: add Schema annotation for Firestore schema definitions. ([036425be](https://github.com/SylphxAI/firestore_odm/commit/036425beb89ff1331a68606d1a48b22402426e88))

## 1.1.0

 - **REFACTOR**: Remove all hardcoded field names and simplify generator. ([8afa7ecd](https://github.com/SylphxAI/firestore_odm/commit/8afa7ecd03141a8f19aeeecf30cfdfd767009daf))
 - **FEAT**: Introduce schema-based architecture for Firestore ODM. ([de939d90](https://github.com/SylphxAI/firestore_odm/commit/de939d903821a94c962f0d354e982c3b062dfc30))
 - **FEAT**: Successfully publish all packages to pub.dev. ([9e10b6c6](https://github.com/SylphxAI/firestore_odm/commit/9e10b6c61897fc4c876c8d30a3b9f2ff3302edb7))
 - **FEAT**: Complete CI/CD pipeline setup with melos for publishing. ([5f3e440c](https://github.com/SylphxAI/firestore_odm/commit/5f3e440ca1b177a9fa3361792bda02949b3743fe))
 - **FEAT**: add comprehensive @Collection validation system. ([12659528](https://github.com/SylphxAI/firestore_odm/commit/126595284c0e21d8ffb4cb5f6a46e75e1e17660d))
 - **FEAT**: refactor to unified @Collection annotation with subcollection support. ([c4330d39](https://github.com/SylphxAI/firestore_odm/commit/c4330d39a898bb6c8caaffffcfa7b2ff6e88cfdc))
 - **FEAT**: add @DocumentIdField annotation support. ([9cfb884d](https://github.com/SylphxAI/firestore_odm/commit/9cfb884d59d8922ff2b64e819c05f404575c365e))
 - **FEAT**: restructure as monorepo with strong-typed Firestore ODM. ([b9e6ced0](https://github.com/SylphxAI/firestore_odm/commit/b9e6ced07c38c798ec594a0c96292c86888422f7))
 - **FEAT**: Convert Firestore ODM to monorepo library. ([279e3547](https://github.com/SylphxAI/firestore_odm/commit/279e35473d592307bec352a9af359a798f2cc224))

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-09

### Added
- Initial release of firestore_odm_annotation
- `@Collection(path)` annotation for marking Firestore collections
- `@SubCollection(path)` annotation for marking Firestore subcollections
- `@DocumentId()` annotation for marking document ID fields
- `@FirestoreField(name)` annotation for field name mapping
- Comprehensive documentation and examples
- Full type safety support for code generation