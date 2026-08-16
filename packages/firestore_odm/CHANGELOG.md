## 5.0.0

- **Stable release of the 5.0 clean break (ADR-0002)** — exact Firestore
  semantics: native Timestamp storage, create/set/patch/delete write verbs,
  no sentinels, one-shot server-side aggregates, typed Pipelines
  (experimental), chunked bulk writes, stable documentId tie-breaker
  pagination, real evidence gates (unit + goldens + benchmarks + emulator
  e2e) and release readback. See `docs/adr/0002-semantics-contract-v5.md`
  and `docs/guide/migration-guide-5.md`.

## 4.1.0-dev.1

- **EXPERIMENTAL**: redesign `collection.pipeline()` to be **fully type-safe via the generated `$.field` selector** — no more string `Field('age')` paths (which contradicted the ODM's purpose). `where`/`sort`/`limit`/`offset` preserve the model type; `select` projects into typed Dart records (`select(($) => (name: $.name.value, years: $.age.value)) → List<({String name, int years})>`); `aggregate` returns a typed record (`aggregate(($) => (count: $.count(), avgAge: $.age.average()))`). Compile-time type-checked; `select`/`aggregate` runtime behaviour still requires an Enterprise database to validate (the fake has no pipeline engine). Generic models don't get a pipeline surface yet. See `docs/adr/0001-firestore-pipelines.md` (#6).

## 4.0.0

Stable release of the 4.0 line. Highlights since 3.x:

- **BREAKING**: requires `cloud_firestore ^6.4.0` / `firebase_core ^4.x` (was cloud_firestore 5.x). The ODM query/CRUD/update API is unchanged.
- Enum support (`@JsonValue` string + numeric, enums in `orderBy`, defaults).
- Automatic nested-class imports for filter/patch/aggregate/orderBy selectors.
- Stronger nullable handling, incl. nested `fromJson` factories that accept nullable input (#5).
- Server timestamps applied on insert (not only update); batch & transaction patch builders.
- **Experimental**: `collection.pipeline()` for Firestore Pipelines (Enterprise edition only; see ADR-0001 / #6).
- Reworked code generator; builder now targets the analyzer 8+ element model and current Flutter stable.

See the `4.0.0-dev.*` entries below for the detailed history.

## 4.0.0-dev.6

- **EXPERIMENTAL**: add `collection.pipeline()` → `TypedPipeline<T>`, a type-safe wrapper over Firestore Pipelines (`where`/`sort`/`limit`/`execute`, results mapped back to the model). Pipelines are **Enterprise edition only**, one-shot (no realtime/offline), and unsupported by the emulator / `fake_cloud_firestore` — so execution is not covered by the test suite and needs a real Enterprise database. Re-exports `Field`/`Expression`/`Ordering` for building expressions. Design: `docs/adr/0001-firestore-pipelines.md` (#6).

## 4.0.0-dev.5

- **BREAKING**: require `cloud_firestore ^6.4.0` (was `^5.0.0`) and `cloud_firestore_platform_interface ^8.0.0` (was `^6.5.0`). No ODM API changes — the query/CRUD/snapshot surface is unchanged across cloud_firestore 5→6. Apps must upgrade to `cloud_firestore` 6.x and `firebase_core` 4.x (cloud_firestore 6.0 removed the deprecated persistence `Settings` toggles; use `Settings.localCache`).

## 4.0.0-dev.4

- Bump to match firestore_odm_builder 4.0.0-dev.4 (analyzer 8+ migration). No runtime API changes in this package.

## 4.0.0-dev.3

- Bump to match firestore_odm_builder 4.0.0-dev.3 (nested `fromJson` nullable-cast fix, #5). No runtime API changes in this package.

## 4.0.0-dev.2

- Fix nullable Map type constraint in DartMapFieldUpdate
- Fix MapFilterField.toJson return type to be nullable
- Add server timestamp replacement on insert

## 4.0.0-dev.1

 - **REFACTOR**: tests and update model serialization. ([75adad50](https://github.com/SylphxAI/firestore_odm/commit/75adad50194afbd8c5c9471d03c9e030685296f8))
 - **FEAT**: add comprehensive enum support with numeric and string @JsonValue handling, including orderBy functionality and default value generation. ([04edb090](https://github.com/SylphxAI/firestore_odm/commit/04edb09042d17f5ee49c1e236ff671509a7e5be8))

## 4.0.0-dev

 - **REFACTOR**: rename Node2 to Node for improved consistency across classes. ([a0b82da5](https://github.com/SylphxAI/firestore_odm/commit/a0b82da5cabc3a1c9191719549d49f657a95abfc))
 - **REFACTOR**: remove unused Node class for improved clarity and maintainability. ([8c61c42f](https://github.com/SylphxAI/firestore_odm/commit/8c61c42f0c2014b5078fe8e44f5c038878ed2749))
 - **REFACTOR**: remove unused BatchField and BatchConfiguration classes for improved clarity and maintainability. ([bc68c0b5](https://github.com/SylphxAI/firestore_odm/commit/bc68c0b56292c354ec3a2d4863d0f5ed28fb3656))
 - **REFACTOR**: enhance update operations to use PathFieldPath for improved consistency and clarity. ([b14de4aa](https://github.com/SylphxAI/firestore_odm/commit/b14de4aa210419ecbe70dbd73bc1be13594fc85a))
 - **REFACTOR**: update PatchBuilder and related classes to use FieldPath for improved consistency and clarity. ([5a86cc59](https://github.com/SylphxAI/firestore_odm/commit/5a86cc59a8ac5686cedd8f2834e518519041df12))
 - **REFACTOR**: update aggregate field handling to use field paths instead of names for improved clarity and consistency. ([358036f4](https://github.com/SylphxAI/firestore_odm/commit/358036f4e3167f7c3b27d708c25f46b0c0d06f75))
 - **REFACTOR**: update field handling in Node2 and related classes for improved consistency and clarity. ([9d1642d5](https://github.com/SylphxAI/firestore_odm/commit/9d1642d528dbf4723bfce85c232de624e85b32da))
 - **REFACTOR**: remove debug print statements from DocumentHandler. ([067eb207](https://github.com/SylphxAI/firestore_odm/commit/067eb20750282220a588695c41fe24daabc6575d))
 - **REFACTOR**: enhance filter operations to handle null values and improve default parameter handling. ([0be388bf](https://github.com/SylphxAI/firestore_odm/commit/0be388bf30bd6a1497d0210e3f267c478518f92f))
 - **REFACTOR**: update filter field implementations for improved type handling. ([23d48d7a](https://github.com/SylphxAI/firestore_odm/commit/23d48d7a4aa1898f4819c3591fc74ab7a58a18e5))
 - **REFACTOR**: rework filter builders and related. ([a69ccc56](https://github.com/SylphxAI/firestore_odm/commit/a69ccc561be220e6cb96dbcd6f5a8c4310dc7e6d))
 - **REFACTOR**: update converters and generator methods for improved type handling and custom converter support. ([1d543858](https://github.com/SylphxAI/firestore_odm/commit/1d543858b58e0cd3acb56ff91673469de6e2f22b))
 - **REFACTOR**: rework patch builders and converters. ([96438867](https://github.com/SylphxAI/firestore_odm/commit/96438867183f11197a891cf9048b4ad567a303b8))
 - **REFACTOR**: Firestore ODM to enhance filter and order by functionality. ([6b1fb6c0](https://github.com/SylphxAI/firestore_odm/commit/6b1fb6c0882a3196ce3158b9a1bb13c8a4b739b0))
 - **REFACTOR**: replace synchronous interfaces with asynchronous counterparts for batch operations. ([dab07f41](https://github.com/SylphxAI/firestore_odm/commit/dab07f41e4b6ada557258d684ae4b124a5ea348d))
 - **FIX**: update filter condition checks to use noValue for improved clarity. ([5cd2767a](https://github.com/SylphxAI/firestore_odm/commit/5cd2767a4168732e8f43d111599343e33fe1ae40))
 - **FIX**: process serverTimestamp. ([b2c91206](https://github.com/SylphxAI/firestore_odm/commit/b2c9120665de2015a5403518ea3e1be69fde69af))
 - **FIX**: enhance orderBy field handling with type parameter for document ID fields. ([91e4d0b7](https://github.com/SylphxAI/firestore_odm/commit/91e4d0b725a7c382a8a29a7e6b48ab38efcada19))
 - **FIX**: enhance type safety in aggregate context resolution methods. ([98a17613](https://github.com/SylphxAI/firestore_odm/commit/98a176139d2dc8ebcf9caa1fb01f0c9453a5c045))
 - **FIX**: translate comments to English for better readability and maintainability. ([73a2f9f2](https://github.com/SylphxAI/firestore_odm/commit/73a2f9f248a9e48974c6759b01d6fbf5a1925f43))
 - **FIX**: add patch builder parameter to getBatchCollection and schema generator. ([4d9ea480](https://github.com/SylphxAI/firestore_odm/commit/4d9ea4809b9493548c942195c465696ebf18c357))
 - **FEAT**: enhance type safety and validation for Firestore collections and subcollections. ([5afc1718](https://github.com/SylphxAI/firestore_odm/commit/5afc171883549e2205f9257563f0bb4fac2c4404))
 - **FEAT**: add convenience function for creating batch collections with patch builder support. ([28b9fa14](https://github.com/SylphxAI/firestore_odm/commit/28b9fa14bd3b6ebde0d926e50edbe226786fa779))
 - **FEAT**: enhance batch operations with patch builder support in BatchDocument and BatchCollection. ([a6b14d5c](https://github.com/SylphxAI/firestore_odm/commit/a6b14d5c3d94d49ff77338ef5b77b958baadc9f7))
 - **FEAT**: add patch builder support to TransactionCollection and TransactionDocument. ([cd293155](https://github.com/SylphxAI/firestore_odm/commit/cd29315569646d37925ed05cebc3eff684f7b70f))
 - **FEAT**: supporting nested class without manual importing, aggregate done. ([8fb29612](https://github.com/SylphxAI/firestore_odm/commit/8fb29612442c59fdd0e6c92709544ffe87847c30))
 - **FEAT**: enhance aggregation capabilities with new context classes and improved query interfaces. ([f58a6d44](https://github.com/SylphxAI/firestore_odm/commit/f58a6d4479a2dbfb18d9776db55ec61bc6ba2564))
 - **FEAT**: spporting nested class without manual import, orderbybuilder done. ([9d1bea02](https://github.com/SylphxAI/firestore_odm/commit/9d1bea024fe6956c8f82a25307224f252583c361))
 - **FEAT**: supporting nested class withot manual import, filter and patcher done. ([37bf6d4b](https://github.com/SylphxAI/firestore_odm/commit/37bf6d4bb3b32454fef7be8c7d9f918e55701cc9))

## 3.0.2

## 3.0.1

## 3.0.0

 - **REFACTOR**: ensure key conversion to string in MapFieldUpdate operations. ([5713124b](https://github.com/SylphxAI/firestore_odm/commit/5713124bafa988e5f8a1a6028cda3166834e01ac))
 - **REFACTOR**: simplify SetOperation instantiation in PatchBuilder. ([975182b6](https://github.com/SylphxAI/firestore_odm/commit/975182b61990fedcb5865aad429d0f63fde25475))
 - **REFACTOR**: rework to focus on extension-based architecture. ([945d8dd0](https://github.com/SylphxAI/firestore_odm/commit/945d8dd0cf63daf2d5862638d9cf932911812d1d))
 - **REFACTOR**: enhance type safety and streamline update operations across multiple classes. ([3bee1678](https://github.com/SylphxAI/firestore_odm/commit/3bee16789728a40abe96eed3d9e9aa9f52036454))
 - **REFACTOR**: streamline update operation classes and enhance type safety. ([82e3ad7d](https://github.com/SylphxAI/firestore_odm/commit/82e3ad7dfdde8e4cac512b31bf5efef4dc26de0b))
 - **REFACTOR**: update patch method signatures and improve import organization. ([ce678f25](https://github.com/SylphxAI/firestore_odm/commit/ce678f25ec2753f7b7743d0e1df39d2e8c6b4d3f))
 - **REFACTOR**: simplify converter and workflow. ([a681be50](https://github.com/SylphxAI/firestore_odm/commit/a681be508eadd68ce8dbce6e5d7e184fd7f2318a))
 - **REFACTOR**: firestore ODM Converter Logic. ([3a93e52e](https://github.com/SylphxAI/firestore_odm/commit/3a93e52e8f0e3f9c2d3ddfc2f212e43565dd8385))
 - **REFACTOR**: replace toJson/fromJson functions with FirestoreConverter for improved type safety and consistency. ([65e5a85f](https://github.com/SylphxAI/firestore_odm/commit/65e5a85f4ab906923004b24fe58b12afe256d3df))
 - **REFACTOR**: remove deprecated incrementalModify method and streamline update logic. ([fee7ef08](https://github.com/SylphxAI/firestore_odm/commit/fee7ef089fa262b9ed96312428206cf19dd2deec))
 - **REFACTOR**: rework converters. ([4c0fdf19](https://github.com/SylphxAI/firestore_odm/commit/4c0fdf1933e2faf57d358693cf14a7c56c2525c8))
 - **REFACTOR**: improve DurationFieldUpdate converter handling with type-safe method. ([42a85ab2](https://github.com/SylphxAI/firestore_odm/commit/42a85ab2b881d4b1a3202776ccf59a01d9f0ebcb))
 - **REFACTOR**(filter_builder): clean up whitespace and improve readability in UpdateBuilder class. ([c203cfe0](https://github.com/SylphxAI/firestore_odm/commit/c203cfe058ed6ed9e43bfe6aba801c7e8a78dd34))
 - **REFACTOR**: streamline JSON converter handling and enhance type reference management. ([4470a1be](https://github.com/SylphxAI/firestore_odm/commit/4470a1bea69a649b98293cab5f2da07242c872fa))
 - **REFACTOR**: reworking builder. ([e076e310](https://github.com/SylphxAI/firestore_odm/commit/e076e310154e9fe94e7e6665c3e974f7ff682e50))
 - **REFACTOR**(firestore_converters): simplify parameter passing for list and map converter creation. ([07bc60da](https://github.com/SylphxAI/firestore_odm/commit/07bc60daa2ca371137f7cd68a121990f9357ac43))
 - **REFACTOR**(model_converter): simplify constructor parameters for MapConverter and ListConverter. ([90b483a0](https://github.com/SylphxAI/firestore_odm/commit/90b483a024ccbbc4287896f61909a8174ecb1ff3))
 - **FEAT**: supports map field clear and set operation. ([1f1e3773](https://github.com/SylphxAI/firestore_odm/commit/1f1e3773a77f2398d40f0cf7b99734809ad6b601))
 - **FEAT**: rework builders. ([c96df342](https://github.com/SylphxAI/firestore_odm/commit/c96df342c5140bbb48d74af1a8d64f65b9f80e28))
 - **FEAT**(model_converter): add DefaultConverter for custom fromJson/toJson handling. ([8c467ef3](https://github.com/SylphxAI/firestore_odm/commit/8c467ef32e61fe42c3bbc4784b2e14e7d71535e2))
 - **FEAT**(converters): introduce generic converters for custom types and enhance type analysis. ([534f391a](https://github.com/SylphxAI/firestore_odm/commit/534f391a6c79f7c78ac025a205b5a012cdd5d54a))

## 2.7.1

 - **REFACTOR**(generator): simplify update builder generation by using converter parameter. ([99923a5f](https://github.com/SylphxAI/firestore_odm/commit/99923a5fadfda8d8c7ae60938ed71817d8689b58))

## 2.7.0

 - **REFACTOR**: replace batch operation interfaces with synchronous variants for improved transaction handling. ([aab9f767](https://github.com/SylphxAI/firestore_odm/commit/aab9f767612c90365cf022c6c4a1a1f048ec8f68))
 - **REFACTOR**: remove IListConverter, IMapConverter, and ISetConverter implementations for cleaner code. ([374f5da2](https://github.com/SylphxAI/firestore_odm/commit/374f5da217e490377d4e67921519049e3ef7f6bb))
 - **REFACTOR**: Firestore ODM to use FirestoreConverter instead of ModelConverter. ([40acf7dc](https://github.com/SylphxAI/firestore_odm/commit/40acf7dc20d5c76d724992457dca47bf2f688809))
 - **FEAT**: Add detailed English comments to Firestore ODM interfaces. ([bce08cf3](https://github.com/SylphxAI/firestore_odm/commit/bce08cf32e550d16f0fc973cdad74f89a84ab9ad))
 - **FEAT**: enhance DateTimeConverter to handle server timestamp constant. ([a3aa5ace](https://github.com/SylphxAI/firestore_odm/commit/a3aa5ace4d67487599b132a4117c805aee5a2b82))
 - **FEAT**: enhance Firestore converters to support custom IList, ISet, and IMap types with dynamic conversion expressions. ([6e7456c0](https://github.com/SylphxAI/firestore_odm/commit/6e7456c0d4a2d2f10d4822207186bbd3429abdfd))
 - **FEAT**: implement FirestoreConverter interface and add DateTimeConverter and DurationConverter classes. ([a6226eaf](https://github.com/SylphxAI/firestore_odm/commit/a6226eaf78283b7f9c1c3d1f44e7dc16f9df5f10))
 - **FEAT**: add DurationFieldUpdate class and support for Duration type in update generator. ([5cca1de8](https://github.com/SylphxAI/firestore_odm/commit/5cca1de88bfd417172336f9ac5832be68bfc1e5b))
 - **FEAT**: enhance update builder with DefaultUpdateBuilder and streamline field update methods. ([1b277aa0](https://github.com/SylphxAI/firestore_odm/commit/1b277aa03a5b543ef23fa9380e58b4e9796a4d67))
 - **DOCS**: add warnings about arithmetic operations on server timestamps. ([03790b36](https://github.com/SylphxAI/firestore_odm/commit/03790b3615eb55e8bcb9dfeda726bcc53c7273d8))

## 2.6.0

 - **FEAT**: add map operations for bulk updates and removals in UpdateBuilder. ([df9dee07](https://github.com/SylphxAI/firestore_odm/commit/df9dee076c53a74cc39cd97a75cc56de6f843e9e))
 - **FEAT**: enhance iterable support in UpdateBuilder to accept any Iterable for addAll and removeAll operations. ([267b3223](https://github.com/SylphxAI/firestore_odm/commit/267b32233f62a1bed42e77b3734b9c2a13f33fda))

## 2.5.0

 - **FEAT**: enhance UpdateBuilder to respect operation precedence for set and array operations. ([a772c0d6](https://github.com/SylphxAI/firestore_odm/commit/a772c0d6fefdda6e7c1fbcf1faca221e906704ca))
 - **FEAT**: implement arrayAddAll and arrayRemoveAll operations in UpdateBuilder and update documentation. ([df7da59c](https://github.com/SylphxAI/firestore_odm/commit/df7da59c1161a369de05a90cd9e4e0aa4ab72d54))

## 2.4.0

 - **FEAT**: deprecate incrementalModify and enhance modify with atomic parameter. ([b1b95e1a](https://github.com/SylphxAI/firestore_odm/commit/b1b95e1a206ecde7faa54dd8e2d5514fe068b244))

## 2.3.1

 - **REFACTOR**: remove lazyBroadcast and use native Firestore streams. ([971b472f](https://github.com/SylphxAI/firestore_odm/commit/971b472f857bbea14d3523b967192dd44f4d0461))

## 2.3.0

 - **FEAT**: enhance aggregate and batch operations with detailed documentation. ([5e05ce2e](https://github.com/SylphxAI/firestore_odm/commit/5e05ce2e4c3d693779d2fb0416b1fc91ecc15487))

## 2.2.0

 - **FIX**: prevent auto-generated IDs in update operations. ([0389c6a8](https://github.com/SylphxAI/firestore_odm/commit/0389c6a84e83a3e0e3385a08d4c5687860dac946))
 - **FIX**: prevent auto-generated IDs in upsert operations. ([240f6ea2](https://github.com/SylphxAI/firestore_odm/commit/240f6ea2528197370cfb6b16396a7e27527b806c))
 - **FEAT**: implement auto-generated document ID with FirestoreODM.autoGeneratedId constant. ([ad5c75df](https://github.com/SylphxAI/firestore_odm/commit/ad5c75df0e5d0d04db0623a46e3ef50c9fcbae57))

## 2.1.0

 - **FIX**: specify version for firestore_odm_annotation dependency in pubspec.yaml. ([934810fa](https://github.com/SylphxAI/firestore_odm/commit/934810fa1a07464652636e28e6b65f3cc1e8b12c))
 - **FEAT**: Add comprehensive batch operations support. ([802a629b](https://github.com/SylphxAI/firestore_odm/commit/802a629b2efe4e8c95b8efeb9766dff0b69f62d3))
 - **FEAT**: refactor project folder structure. ([d4907075](https://github.com/SylphxAI/firestore_odm/commit/d49070757a19ea643d73e2aa0664754f0c67da44))
 - **DOCS**: Update all documentation URLs to GitHub Pages. ([321ccdcd](https://github.com/SylphxAI/firestore_odm/commit/321ccdcd10f31374f6cd5b955fa3b7cb2d7f17fa))
 - **DOCS**: refactor and centralize README.md. ([7c121c62](https://github.com/SylphxAI/firestore_odm/commit/7c121c62981001803322ff5af1e2bb3f4593c46c))
 - **DOCS**: update README to enhance structure and add flexible data modeling section. ([801a242c](https://github.com/SylphxAI/firestore_odm/commit/801a242c1f393a3a74ac3428b0f8b3e383b2215c))
 - **DOCS**: enhance README with flexible data modeling options and examples. ([d33115d9](https://github.com/SylphxAI/firestore_odm/commit/d33115d9aa579f3c90158695286482f6f4729595))

## 2.0.2

 - **REFACTOR**: improve formatting and readability in MapFieldFilter and OrderByField classes. ([4e8f1877](https://github.com/SylphxAI/firestore_odm/commit/4e8f187744dcd984d60bac976f6f1f5784c7c82a))

## 2.0.1

 - **REFACTOR**: code formatting and improve readability across multiple files. ([4a7876b7](https://github.com/SylphxAI/firestore_odm/commit/4a7876b7a16fb389301b9bdb924b24b9e4bbbde6))
 - **REFACTOR**: update to use element2 API for improved type handling. ([77260aa7](https://github.com/SylphxAI/firestore_odm/commit/77260aa7d8ffcb22fadd8414e9e4a89aed8ffcf9))
 - **REFACTOR**: firestore ODM code generation to utilize ModelAnalysis. ([1e82daab](https://github.com/SylphxAI/firestore_odm/commit/1e82daaba984ebd3d3d3ec15d80d855e29869221))
 - **REFACTOR**: refactor and clean up code across multiple files. ([cc44c322](https://github.com/SylphxAI/firestore_odm/commit/cc44c322b43fb72bdeebb20b0a87ccd8fcb64607))
 - **FIX**: correct fieldPath concatenation and update empty check for updateMap. ([d5d2db74](https://github.com/SylphxAI/firestore_odm/commit/d5d2db7462ee17016e098fc2f48a73d4c105c211))

## 2.0.0

> Note: This release has breaking changes.

 - **REFACTOR**: rename update methods to patch for consistency and enhance FirestoreDocument interface. ([fdb5547e](https://github.com/SylphxAI/firestore_odm/commit/fdb5547ef78c5520da5f13acbdb7c483f9df01e1))
 - **REFACTOR**: firestore query handling and update operations. ([46ee6360](https://github.com/SylphxAI/firestore_odm/commit/46ee6360247f38ff3d1ab598d58711926886692d))
 - **REFACTOR**: remove TupleAggregateQuery and UpdateBuilder, introduce utility functions for Firestore data processing. ([8a224de8](https://github.com/SylphxAI/firestore_odm/commit/8a224de8d9dea2cc9938c707f53ef4210965d47a))
 - **FIX**: implement defer writes pattern to resolve read-write ordering. ([cf1ae907](https://github.com/SylphxAI/firestore_odm/commit/cf1ae907eb91b926bbf8e0b116e7dc3e5e72da5d))
 - **FEAT**: add map operations, bulk delete, and collection bulk operations with comprehensive testing. ([d5612029](https://github.com/SylphxAI/firestore_odm/commit/d5612029e4c662d9054716a85f19076defc6e14a))
 - **FEAT**: Complete missing methods and fix critical bugs. ([caa23ab0](https://github.com/SylphxAI/firestore_odm/commit/caa23ab064fc748a412de111574291f77cc8f8ed))
 - **FEAT**: Enhance transaction support in Firestore ODM. ([5ba0b618](https://github.com/SylphxAI/firestore_odm/commit/5ba0b618605f8e8c28ae6d20234de55ee26e1d0d))
 - **FEAT**: Implement pagination support in Firestore ODM. ([6abde897](https://github.com/SylphxAI/firestore_odm/commit/6abde8976e51ec63cededee286b750e85ba6dd3a))
 - **FEAT**: implement callable update and order by instances to reduce generated code. ([cf16cea8](https://github.com/SylphxAI/firestore_odm/commit/cf16cea8a10fddd89f88a3fc6063cff5b5c9b2d9))
 - **BREAKING** **FEAT**: add aggregation and pagination support with builder-to-selector refactor. ([8978198c](https://github.com/SylphxAI/firestore_odm/commit/8978198c704dc3e8600ac6f5ffdcd64ae090352c))

## 1.1.1

 - **REFACTOR**: implement callable filter instances to reduce generated code. ([a19b2f11](https://github.com/SylphxAI/firestore_odm/commit/a19b2f11708ff2a74ccc0cfa0c7055e6bf5beb81))
 - **REFACTOR**: integrate ModelConverter for data transformation across services. ([90979671](https://github.com/SylphxAI/firestore_odm/commit/90979671500403715b910e436ba2108264efc1d3))
 - **REFACTOR**: remove local path references to firestore_odm_annotation. ([48b84db7](https://github.com/SylphxAI/firestore_odm/commit/48b84db75f4947c122bc57a7090d716b9127dedd))

## 1.1.0

 - **REFACTOR**: enhance documentation structure with quick navigation and feature overview. ([8c21f3c6](https://github.com/SylphxAI/firestore_odm/commit/8c21f3c63adf47079d53afa47faaf7e00cef132f))
 - **REFACTOR**: implement SubscribeOperations interface and unify stream handling. ([b21b4de4](https://github.com/SylphxAI/firestore_odm/commit/b21b4de47a27f1812ea9368399221105d487715e))
 - **REFACTOR**: unify stream handling by renaming 'snapshots' to 'stream' across aggregate and query implementations. ([d637ed91](https://github.com/SylphxAI/firestore_odm/commit/d637ed91f1c0e922e7fb6dbb91214af200934570))
 - **REFACTOR**: enhance aggregate query execution and result handling with native Firestore support. ([a6e46f7f](https://github.com/SylphxAI/firestore_odm/commit/a6e46f7f11520ef17a98c11f4750450adc8b1628))
 - **REFACTOR**: rename 'snapshots' to 'stream' for consistency across interfaces and implementations. ([ec6c6e54](https://github.com/SylphxAI/firestore_odm/commit/ec6c6e54790ec3700e1c394872a9fdad91beddd1))
 - **REFACTOR**: rename 'changes' to 'snapshots' for clarity in subscription interfaces. ([89d0c637](https://github.com/SylphxAI/firestore_odm/commit/89d0c6373c889904ae6ff607010e0c0e4a0df063))
 - **REFACTOR**: remove special timestamp handling from Firestore ODM classes. ([8d5658af](https://github.com/SylphxAI/firestore_odm/commit/8d5658af7cdbde0e836f3f7c507865e8b4924e27))
 - **REFACTOR**: Remove all hardcoded field names and simplify generator. ([8afa7ecd](https://github.com/SylphxAI/firestore_odm/commit/8afa7ecd03141a8f19aeeecf30cfdfd767009daf))
 - **REFACTOR**: reduce generated code by 60% using filter extensions and enums. ([dd61bc2d](https://github.com/SylphxAI/firestore_odm/commit/dd61bc2db63ccccb899728cf60eeb455657db650))
 - **REFACTOR**: Move basic field builders from generator to core package. ([eb71eaea](https://github.com/SylphxAI/firestore_odm/commit/eb71eaeaaf7eed1ecc06a7303dfcec2998f31556))
 - **REFACTOR**: remove deprecated update method for clarity and maintainability. ([19ed3f08](https://github.com/SylphxAI/firestore_odm/commit/19ed3f081bc50d4a20f178eca3e61de31837fe82))
 - **FIX**: Restore path dependencies for proper development workflow. ([d4d555c0](https://github.com/SylphxAI/firestore_odm/commit/d4d555c02101ca1fa2d560e74f360d16b8a8e575))
 - **FIX**: correct method roles - modify() non-atomic vs incrementalModify() atomic. ([d515b215](https://github.com/SylphxAI/firestore_odm/commit/d515b2151d5e36e2decbf070ec1bec11b590ff2d))
 - **FEAT**: implement type-safe aggregate operations and count queries with generated field selectors. ([8e95df5b](https://github.com/SylphxAI/firestore_odm/commit/8e95df5b4a741af567c452fe32c480f8abb3813e))
 - **FEAT**: add collection-level operations for insert, update, and upsert. ([23bae871](https://github.com/SylphxAI/firestore_odm/commit/23bae871dd7342ceca9473587aeb9169a38df08d))
 - **FEAT**: Introduce schema-based architecture for Firestore ODM. ([de939d90](https://github.com/SylphxAI/firestore_odm/commit/de939d903821a94c962f0d354e982c3b062dfc30))
 - **FEAT**: Successfully publish all packages to pub.dev. ([9e10b6c6](https://github.com/SylphxAI/firestore_odm/commit/9e10b6c61897fc4c876c8d30a3b9f2ff3302edb7))
 - **FEAT**: Complete CI/CD pipeline setup with melos for publishing. ([5f3e440c](https://github.com/SylphxAI/firestore_odm/commit/5f3e440ca1b177a9fa3361792bda02949b3743fe))
 - **FEAT**: convert FirestoreODM constructor to named parameters. ([519b3e14](https://github.com/SylphxAI/firestore_odm/commit/519b3e14d7890bb7be206243633ebbd300fba1d5))
 - **FEAT**: Add callable collection syntax and fix serialization. ([4632a55d](https://github.com/SylphxAI/firestore_odm/commit/4632a55d0fb0d1df8c761ae3f15bf7b9bdc46336))
 - **FEAT**: add @DocumentIdField annotation support. ([9cfb884d](https://github.com/SylphxAI/firestore_odm/commit/9cfb884d59d8922ff2b64e819c05f404575c365e))
 - **FEAT**: Update test cases to support mixed update syntax and update README. ([5785fc80](https://github.com/SylphxAI/firestore_odm/commit/5785fc8055ce297358a1e2050b79b3b6b94e2c83))
 - **FEAT**: unify atomic operations support across modify methods. ([4df3af73](https://github.com/SylphxAI/firestore_odm/commit/4df3af7309ddfa331830c3cce3ba4b40f8486090))
 - **FEAT**: complete Firestore ODM library implementation. ([f7b0da36](https://github.com/SylphxAI/firestore_odm/commit/f7b0da366e149110f855e69eacbdcfbcfa0bc19c))
 - **FEAT**: implement chained updates and enhanced ODM features. ([59460a10](https://github.com/SylphxAI/firestore_odm/commit/59460a1083e26efbaa749ea56fb8e2d97b915e95))
 - **FEAT**: implement RxDB-style API with atomic operations. ([08af4f52](https://github.com/SylphxAI/firestore_odm/commit/08af4f52da200d4522380c95954fe25311b6df46))
 - **FEAT**: restructure as monorepo with strong-typed Firestore ODM. ([b9e6ced0](https://github.com/SylphxAI/firestore_odm/commit/b9e6ced07c38c798ec594a0c96292c86888422f7))
 - **DOCS**: enhance documentation for limit and limitToLast methods with usage limitations. ([7109d26b](https://github.com/SylphxAI/firestore_odm/commit/7109d26b75425cab6501b2ab99d4dc0bc4068586))

# Changelog

## [1.0.0] - 2025-01-09

### Added
- Initial release of firestore_odm
- Type-safe Firestore operations
- Automatic serialization/deserialization
- Query builder with IntelliSense support
- Real-time updates with snapshots
- Subcollection support
- Transaction and batch operation support
- Comprehensive documentation and examples
## 5.0.0-dev.1

- **BREAKING (clean break, ADR-0002):** exact Firestore semantics.
- DateTime is a native Timestamp both directions; the ODM owns storage
  serialization (model `toJson`/`fromJson` remain for JSON interchange).
- Write verbs: `create` (returns the generated ID), `set`, `patch` (six
  FieldValue-shaped ops), `delete`. Removed `insert`/`update`/`upsert`,
  `modify()`, sentinels, fake aggregate streaming, `exists()`.
- Typed bulk writes chunked to Firestore's 500-write limit.
- Schema classes are user-declared; generated code lands in `<library>.g.dart`.
- Root collections are getters with callable `doc(id)`; subcollections use
  path-derived accessors (`users/*/posts` -> `usersPosts`).
- Recorded benchmark harness and emulator e2e lane.
