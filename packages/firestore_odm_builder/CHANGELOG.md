## 4.0.0

Stable release of the 4.0 line. Key change since 3.x: migrated to the analyzer
8+ "new element model" (`analyzer >=9 <14`, source_gen 4, build 4; min Dart
3.9), enabling builds on current Flutter stable. See `4.0.0-dev.*` below.

## 4.0.0-dev.6

- Bump to match firestore_odm 4.0.0-dev.6 (experimental pipeline API). No builder changes.

## 4.0.0-dev.5

- Bump to match firestore_odm 4.0.0-dev.5 (cloud_firestore 6.x). No builder changes.

## 4.0.0-dev.4

- Migrate to the analyzer 8+ "new element model": `analyzer` `>=9.0.0 <14.0.0` (was `^7.4.5`), `source_gen` `^4.2.3`, `build` `^4.0.0`. Replaces removed/renamed APIs (`element3`→`element`, `name3`→`name`, `typeParameters2`→`typeParameters`, `lookUpConstructor2`/`lookUpMethod3`→`lookUp*`, `TypeChecker.fromRuntime`→`typeNamed`, `metadata`→`metadata.annotations`, unnamed constructor name `''`→`'new'`).
- **Min SDK raised to Dart `^3.9.0`** (required by analyzer 8+). Lets the package build on current Flutter stable.

## 4.0.0-dev.3

- Fix nested `fromJson` factories that accept a nullable map generating a non-nullable cast, which crashed (`type 'Null' is not a subtype of type 'Map<String, Object?>'`) when the field was absent from a document (closes #5)

## 4.0.0-dev.2

- Fix enum null assertion for non-nullable enum types
- Fix fromJson type casting to use actual constructor parameter type

## 4.0.0-dev.1

 - **REFACTOR**: tests and update model serialization. ([75adad50](https://github.com/SylphxAI/firestore_odm/commit/75adad50194afbd8c5c9471d03c9e030685296f8))
 - **FEAT**: add comprehensive enum support with numeric and string @JsonValue handling, including orderBy functionality and default value generation. ([04edb090](https://github.com/SylphxAI/firestore_odm/commit/04edb09042d17f5ee49c1e236ff671509a7e5be8))
 - **FEAT**: add EnumUser model with AccountType enum and default value handling. ([66cd2676](https://github.com/SylphxAI/firestore_odm/commit/66cd2676fc3f68c2416865ba660ad1cd1c11ddfc))

## 4.0.0-dev

 - **REFACTOR**: remove unused ODM parts and update build configurations for Firestore ODM. ([a8927b4f](https://github.com/SylphxAI/firestore_odm/commit/a8927b4ffed7beeac6b32600f556790e13175bd4))
 - **REFACTOR**: simplify type checking methods and improve field accessor generation in aggregate and filter generators. ([7604674f](https://github.com/SylphxAI/firestore_odm/commit/7604674f69a72b9e3c45cd14ef796027d3340745))
 - **REFACTOR**: streamline field getter generation and improve filter selector class structure. ([a320ccc8](https://github.com/SylphxAI/firestore_odm/commit/a320ccc8d59b88340cb70b30fcba7ed8c420d176))
 - **REFACTOR**: consolidate type handling by introducing TypeDefinition class and streamline order by field generation. ([a1489fd7](https://github.com/SylphxAI/firestore_odm/commit/a1489fd7c14fd97a2505e005b3406526459699b5))
 - **REFACTOR**: update PatchBuilder and related classes to use FieldPath for improved consistency and clarity. ([5a86cc59](https://github.com/SylphxAI/firestore_odm/commit/5a86cc59a8ac5686cedd8f2834e518519041df12))
 - **REFACTOR**: update aggregate field handling to use field paths instead of names for improved clarity and consistency. ([358036f4](https://github.com/SylphxAI/firestore_odm/commit/358036f4e3167f7c3b27d708c25f46b0c0d06f75))
 - **REFACTOR**: update field handling in Node2 and related classes for improved consistency and clarity. ([9d1642d5](https://github.com/SylphxAI/firestore_odm/commit/9d1642d528dbf4723bfce85c232de624e85b32da))
 - **REFACTOR**: update filter field implementations for improved type handling. ([23d48d7a](https://github.com/SylphxAI/firestore_odm/commit/23d48d7a4aa1898f4819c3591fc74ab7a58a18e5))
 - **REFACTOR**: rework filter builders and related. ([a69ccc56](https://github.com/SylphxAI/firestore_odm/commit/a69ccc561be220e6cb96dbcd6f5a8c4310dc7e6d))
 - **REFACTOR**: update converters and generator methods for improved type handling and custom converter support. ([1d543858](https://github.com/SylphxAI/firestore_odm/commit/1d543858b58e0cd3acb56ff91673469de6e2f22b))
 - **REFACTOR**: SchemaGenerator and related classes to remove ModelAnalyzer and ConverterFactory dependencies. ([5358ecc8](https://github.com/SylphxAI/firestore_odm/commit/5358ecc822b0254fce577e6af57ceb9d5558c3bd))
 - **REFACTOR**: rework patch builders and converters. ([96438867](https://github.com/SylphxAI/firestore_odm/commit/96438867183f11197a891cf9048b4ad567a303b8))
 - **REFACTOR**: Firestore ODM to enhance filter and order by functionality. ([6b1fb6c0](https://github.com/SylphxAI/firestore_odm/commit/6b1fb6c0882a3196ce3158b9a1bb13c8a4b739b0))
 - **FIX**: update list type handling in getJsonType method for improved type conversion. ([0ea81e89](https://github.com/SylphxAI/firestore_odm/commit/0ea81e89b14ffcaa218666e5a608624a0930e444))
 - **FIX**: enhance orderBy field handling with type parameter for document ID fields. ([91e4d0b7](https://github.com/SylphxAI/firestore_odm/commit/91e4d0b725a7c382a8a29a7e6b48ab38efcada19))
 - **FIX**: update source type handling in JsonMethodConverter for improved type safety. ([d50b9e07](https://github.com/SylphxAI/firestore_odm/commit/d50b9e07f1a8d932ead5974f7de136ac3e64b9e3))
 - **FIX**: enhance type handling in isHandledType and isPrimitive methods. ([879593f6](https://github.com/SylphxAI/firestore_odm/commit/879593f68383385577b1b284ed7a9483a491341e))
 - **FIX**: add patch builder parameter to getBatchCollection and schema generator. ([4d9ea480](https://github.com/SylphxAI/firestore_odm/commit/4d9ea4809b9493548c942195c465696ebf18c357))
 - **FEAT**: add convenience function for creating batch collections with patch builder support. ([28b9fa14](https://github.com/SylphxAI/firestore_odm/commit/28b9fa14bd3b6ebde0d926e50edbe226786fa779))
 - **FEAT**: enhance batch operations with patch builder support in BatchDocument and BatchCollection. ([a6b14d5c](https://github.com/SylphxAI/firestore_odm/commit/a6b14d5c3d94d49ff77338ef5b77b958baadc9f7))
 - **FEAT**: add patch builder support to TransactionCollection and TransactionDocument. ([cd293155](https://github.com/SylphxAI/firestore_odm/commit/cd29315569646d37925ed05cebc3eff684f7b70f))
 - **FEAT**: supporting nested class without manual importing, aggregate done. ([8fb29612](https://github.com/SylphxAI/firestore_odm/commit/8fb29612442c59fdd0e6c92709544ffe87847c30))
 - **FEAT**: spporting nested class without manual import, orderbybuilder done. ([9d1bea02](https://github.com/SylphxAI/firestore_odm/commit/9d1bea024fe6956c8f82a25307224f252583c361))
 - **FEAT**: supporting nested class withot manual import, filter and patcher done. ([37bf6d4b](https://github.com/SylphxAI/firestore_odm/commit/37bf6d4bb3b32454fef7be8c7d9f918e55701cc9))

## 3.1.1

 - **FEAT**: refactor model analysis and converter factory for improved instance management. ([d078ba72](https://github.com/SylphxAI/firestore_odm/commit/d078ba726052b08bebc9bf478a7a7a18fce789d3))

## 3.1.0

 - **FEAT**: add tests for snake_case to camelCase conversion in Firestore collections. ([742a3bc3](https://github.com/SylphxAI/firestore_odm/commit/742a3bc31371a40797227272026ed452fde9a4e2))

## 3.0.2

 - **REFACTOR**: simplify JSON method checks and improve converter naming conventions. ([6d55a580](https://github.com/SylphxAI/firestore_odm/commit/6d55a5801d6982f53a4ea0096aeacff2d944ca51))

## 3.0.1

 - **FIX**: update parameter types for fromJson and toJson methods in ConverterFactory. ([d424c904](https://github.com/SylphxAI/firestore_odm/commit/d424c9041f4a33b56a37d7f34cdffd52c9dcd04e))

## 3.0.0

 - **REFACTOR**(model_analyzer): streamline JsonConverter support check and remove unused getBaseTypeName method. ([89921d46](https://github.com/SylphxAI/firestore_odm/commit/89921d46fc32e808fae43169313b754bf67a7fd7))
 - **REFACTOR**: enhance type safety and streamline update operations across multiple classes. ([3bee1678](https://github.com/SylphxAI/firestore_odm/commit/3bee16789728a40abe96eed3d9e9aa9f52036454))
 - **REFACTOR**: update patch method signatures and improve import organization. ([ce678f25](https://github.com/SylphxAI/firestore_odm/commit/ce678f25ec2753f7b7743d0e1df39d2e8c6b4d3f))
 - **REFACTOR**: update constant property in UpdateGenerator and ConverterFactory for better type handling. ([bc372a1a](https://github.com/SylphxAI/firestore_odm/commit/bc372a1a29a57bd36b855eb93350327b918bb1c0))
 - **REFACTOR**: replace createConverter with getConverter in converter-related classes. ([e88ffa84](https://github.com/SylphxAI/firestore_odm/commit/e88ffa84e9e5cb78dd6229d4bb03365dac0c9ad8))
 - **REFACTOR**: update import statements to use reference_utils in filter and order by generators. ([5121f1df](https://github.com/SylphxAI/firestore_odm/commit/5121f1dfcb41ff7cdc180c06eeac0a89023b4723))
 - **REFACTOR**: update import statement and simplify class name retrieval in AggregateGenerator. ([8e559a9e](https://github.com/SylphxAI/firestore_odm/commit/8e559a9eee5b0a39918bf8e6f3997c09ee20da9e))
 - **REFACTOR**: remove unused Generater class and streamline converter creation process. ([56cc0acd](https://github.com/SylphxAI/firestore_odm/commit/56cc0acd4b2e690a3c4950987da37bcbcacc3f73))
 - **REFACTOR**: replace StringHelpers with StringUtils and update string manipulation methods. ([916daaf4](https://github.com/SylphxAI/firestore_odm/commit/916daaf42d86a2301c9fb45828774d0431de2d10))
 - **REFACTOR**: simplify converter and workflow. ([a681be50](https://github.com/SylphxAI/firestore_odm/commit/a681be508eadd68ce8dbce6e5d7e184fd7f2318a))
 - **REFACTOR**(model_analyzer): streamline type converter implementations and enhance JSON handling. ([a01c8be8](https://github.com/SylphxAI/firestore_odm/commit/a01c8be8c6f8b6de19bd017c4f6a471f619ebea3))
 - **REFACTOR**: firestore ODM Converter Logic. ([3a93e52e](https://github.com/SylphxAI/firestore_odm/commit/3a93e52e8f0e3f9c2d3ddfc2f212e43565dd8385))
 - **REFACTOR**: remove unused ConverterService and related code. ([b55c13b7](https://github.com/SylphxAI/firestore_odm/commit/b55c13b7a430e25391038fa537f7e5ded581deaa))
 - **REFACTOR**: rework converters. ([4c0fdf19](https://github.com/SylphxAI/firestore_odm/commit/4c0fdf1933e2faf57d358693cf14a7c56c2525c8))
 - **REFACTOR**: update converter handling to use references instead of instances and improve type conversion logic. ([ceed64d8](https://github.com/SylphxAI/firestore_odm/commit/ceed64d8b608c2db935aa566c9b04e15a876090f))
 - **REFACTOR**: introduce TypeConverter interface and refactor ConverterService to use DefaultConverter. ([41273c31](https://github.com/SylphxAI/firestore_odm/commit/41273c31d4206ca3fd0af08fa2757ceb488df500))
 - **REFACTOR**: simplify Firestore type handling in ConverterService and ModelAnalyzer. ([d35aa8f0](https://github.com/SylphxAI/firestore_odm/commit/d35aa8f00e5397082b63b7a3f3ad421f8df69349))
 - **REFACTOR**: remove obsolete collection generator and validator classes. ([d25796cd](https://github.com/SylphxAI/firestore_odm/commit/d25796cdb2623c81a507c14ee2a5ca4b87531b01))
 - **REFACTOR**: remove unused imports and streamline code in various files. ([63b9891c](https://github.com/SylphxAI/firestore_odm/commit/63b9891cc4482d3d49d209a2e1c1a32efeb78c68))
 - **REFACTOR**: rework to focus on extension-based architecture. ([945d8dd0](https://github.com/SylphxAI/firestore_odm/commit/945d8dd0cf63daf2d5862638d9cf932911812d1d))
 - **REFACTOR**(converter_generator): enhance JSON support handling and add debug output for ManualUser2. ([003ed847](https://github.com/SylphxAI/firestore_odm/commit/003ed847451ff33c21585b2b124ef64452bc3b12))
 - **REFACTOR**(converter_service): remove unused UnderlyingConverter cases and enhance converter refinement logic. ([a1eba267](https://github.com/SylphxAI/firestore_odm/commit/a1eba2673904f85180cefa0b8e5da9c49d5fbdb5))
 - **REFACTOR**(update_generator): update field type check for tags and simplify return type comparison. ([7c1bb75d](https://github.com/SylphxAI/firestore_odm/commit/7c1bb75dbf29df1693b9ecd8a611f924a95020ae))
 - **REFACTOR**(model_analyzer): simplify model analysis method calls and remove unused code. ([496ad723](https://github.com/SylphxAI/firestore_odm/commit/496ad72350725ba0b54ba293fbd6cb0f575a1d70))
 - **REFACTOR**(schema_generator): add type handling methods and streamline model analysis process. ([5d906129](https://github.com/SylphxAI/firestore_odm/commit/5d906129999437d49bde1940fe298864ca812a10))
 - **REFACTOR**(model_analyzer): simplify model analysis by removing internal analysis method and updating references. ([c4583af3](https://github.com/SylphxAI/firestore_odm/commit/c4583af3e3060652055ea38e4550514ea10da008))
 - **REFACTOR**(converter): restructure converter generation with explicit typing and improved annotation handling. ([9e470ded](https://github.com/SylphxAI/firestore_odm/commit/9e470dedec87e026018a04ea909b1edf8d0934b7))
 - **REFACTOR**(filter_builder): clean up whitespace and improve readability in UpdateBuilder class. ([c203cfe0](https://github.com/SylphxAI/firestore_odm/commit/c203cfe058ed6ed9e43bfe6aba801c7e8a78dd34))
 - **REFACTOR**(update_generator): remove deprecated call method and clean up code. ([760e8356](https://github.com/SylphxAI/firestore_odm/commit/760e8356f331c2e66d98da1023bd3dab301060b3))
 - **REFACTOR**(name_util): improve error handling and enforce valid element checks in DartType extensions. ([00f9f752](https://github.com/SylphxAI/firestore_odm/commit/00f9f7521ec148005c36f9d639b8c1094d693b84))
 - **REFACTOR**(name_util): enhance nullability handling and update type reference logic. ([faf15f0f](https://github.com/SylphxAI/firestore_odm/commit/faf15f0fcfd8d4f7670bafb7573f260f76136125))
 - **REFACTOR**(converter_service): remove debug print statement from ConverterTemplate. ([4856442d](https://github.com/SylphxAI/firestore_odm/commit/4856442dd381e500297abcfb42644f54bae60675))
 - **REFACTOR**(update_generator): remove debug print statement from update method generation. ([67241f3f](https://github.com/SylphxAI/firestore_odm/commit/67241f3fe5210f5ae259a19acea7b98f9933186d))
 - **REFACTOR**(converter_service): enhance type handling and simplify converter logic. ([2661cf86](https://github.com/SylphxAI/firestore_odm/commit/2661cf86be3601c7ad3376c4841909baca2ee364))
 - **REFACTOR**(model_analyzer): simplify TypeConverter interface by removing unused parameters and enhancing method clarity. ([8920979b](https://github.com/SylphxAI/firestore_odm/commit/8920979b5403a204c8b57ca57d460f4c20346aa2))
 - **REFACTOR**(model_analyzer): remove unused TypeRegistry class and related methods. ([ce290277](https://github.com/SylphxAI/firestore_odm/commit/ce290277bc95ad5bf4d322526af7d46fecfb317d))
 - **REFACTOR**: reworking builder. ([e076e310](https://github.com/SylphxAI/firestore_odm/commit/e076e310154e9fe94e7e6665c3e974f7ff682e50))
 - **REFACTOR**: streamline JSON converter handling and enhance type reference management. ([4470a1be](https://github.com/SylphxAI/firestore_odm/commit/4470a1bea69a649b98293cab5f2da07242c872fa))
 - **REFACTOR**(order_by_generator): update generated OrderByFieldSelector to include type parameters in documentation. ([57c32bf5](https://github.com/SylphxAI/firestore_odm/commit/57c32bf50ef03617ba72bcb928be7d4cad368fa7))
 - **REFACTOR**(filter_generator): enhance filter generation methods using code_builder and improve method structure. ([3341ad2d](https://github.com/SylphxAI/firestore_odm/commit/3341ad2d93b5b5210046cf6c69389256a13b4c4d))
 - **REFACTOR**(schema_generator): enhance schema generation logic using code_builder, improve type handling, and streamline method structure. ([300e3f18](https://github.com/SylphxAI/firestore_odm/commit/300e3f182393ac2a57f2fca343f3c28a18d75480))
 - **REFACTOR**(aggregate_generator): enhance method generation for aggregate field selectors and improve type handling. ([4359e149](https://github.com/SylphxAI/firestore_odm/commit/4359e149e7deb1634f6080042804e6f6007d6acd))
 - **REFACTOR**(update_generator): enhance update builder generation and improve method structure. ([679dba07](https://github.com/SylphxAI/firestore_odm/commit/679dba079dc4f51e87fa909989df6e8f7ab076a4))
 - **REFACTOR**(order_by_generator): enhance method generation for order by selectors and improve nested type analysis. ([1a55bbdd](https://github.com/SylphxAI/firestore_odm/commit/1a55bbddab1c8be75771165084768e86cbfd8bb0))
 - **REFACTOR**(schema_generator): simplify condition for field analysis in schema generation. ([6ea3376f](https://github.com/SylphxAI/firestore_odm/commit/6ea3376fc58a7ba1099410dfe4308120d1e9486b))
 - **REFACTOR**(converter_generator): enhance type handling and improve converter generation logic. ([a61420e6](https://github.com/SylphxAI/firestore_odm/commit/a61420e6018e993de945ea1d04a6117f4d63af18))
 - **REFACTOR**(converter_generator): streamline toType getter and improve formatting in ConverterTemplate. ([58210ade](https://github.com/SylphxAI/firestore_odm/commit/58210adec3c7d20e1d0f4f1a1c6d67504f44deaf))
 - **FIX**(custom_converter): missing field converters in custom converter. ([d96ec5eb](https://github.com/SylphxAI/firestore_odm/commit/d96ec5ebd063dd00d59c4048085c40269cc8a22b))
 - **FEAT**: rework builders. ([c96df342](https://github.com/SylphxAI/firestore_odm/commit/c96df342c5140bbb48d74af1a8d64f65b9f80e28))
 - **FEAT**: Implement ConverterFactory for dynamic type conversion. ([d3c36136](https://github.com/SylphxAI/firestore_odm/commit/d3c3613639084e509266488de4881882f1deda2f))
 - **FEAT**(model_analyzer): simplify generic type handling and add debug output for ManualUser2. ([28eafbe0](https://github.com/SylphxAI/firestore_odm/commit/28eafbe026d51d565e4af60b5327a2eaa6090f7c))
 - **FEAT**(converter_generator): add type casting for single and two type parameters in toFirestore conversion. ([61a0bf09](https://github.com/SylphxAI/firestore_odm/commit/61a0bf09243814006ab5fbf7cdc0381581b3ec77))
 - **FEAT**(converter_generator): enhance generic type handling in converter generation. ([bd00d10e](https://github.com/SylphxAI/firestore_odm/commit/bd00d10ef4f9fbf71c4ddad52b321f7c65beacef))
 - **FEAT**(model_analyzer): enhance recursive analysis for deeper nested types in ModelAnalyzer. ([d236709c](https://github.com/SylphxAI/firestore_odm/commit/d236709c9c37052650ffa78b5501a0c54afe55a4))
 - **FEAT**(model_analyzer): skip analysis for type parameters in TypeRegistry and ModelAnalyzer. ([fb3cb32d](https://github.com/SylphxAI/firestore_odm/commit/fb3cb32d2fef52adeddb51d10a2737c294c173fb))
 - **FEAT**(generators): enhance aggregate, filter, order by, and update generators to support generic types. ([2f7e69c7](https://github.com/SylphxAI/firestore_odm/commit/2f7e69c7bca89b503c3dde9e44c5bc52c3bd0d9f))
 - **FEAT**(schema_generator): enhance converter generation for generic types and improve type analysis. ([21b2c7d2](https://github.com/SylphxAI/firestore_odm/commit/21b2c7d2948f94410561a433f4270c18cd0df92c))
 - **FEAT**(converters): introduce generic converters for custom types and enhance type analysis. ([534f391a](https://github.com/SylphxAI/firestore_odm/commit/534f391a6c79f7c78ac025a205b5a012cdd5d54a))

## 2.3.3

 - **FIX**(update_generator): enhance deprecation notice for update method and clarify usage of patch operations. ([519cb496](https://github.com/SylphxAI/firestore_odm/commit/519cb49609cb4f1bc2032ef9bb4ca4a38195411b))
 - **FIX**(update_generator): optimize null checks and improve data assignment in update method. ([8ee14379](https://github.com/SylphxAI/firestore_odm/commit/8ee143793ad433b4a24350bcb6eda291a5b1bb81))

## 2.3.2

 - **REFACTOR**(generator): simplify update builder generation by using converter parameter. ([99923a5f](https://github.com/SylphxAI/firestore_odm/commit/99923a5fadfda8d8c7ae60938ed71817d8689b58))

## 2.3.1

 - **FIX**(subcollections): implement path-specific isolation to prevent cross-collection access. ([95d31e58](https://github.com/SylphxAI/firestore_odm/commit/95d31e58d4bba91f7da2c9001ec23c7f5dabf809))
 - **FIX**(generator): correct extension placement for nested subcollections. ([9f64c681](https://github.com/SylphxAI/firestore_odm/commit/9f64c681111171a9049683b00e6f567cda445baa))

## 2.3.0

 - **REFACTOR**: improve JSON serialization support checks in ModelAnalyzer. ([407232c5](https://github.com/SylphxAI/firestore_odm/commit/407232c5d3ca48ffc7654cc97ae13442fbc237c9))
 - **REFACTOR**: streamline Firestore conversion methods and enhance type key generation with element annotations. ([3ff3aa2c](https://github.com/SylphxAI/firestore_odm/commit/3ff3aa2c6c90052e02bc8bcfede0074c146d6988))
 - **REFACTOR**: Firestore ODM to use FirestoreConverter instead of ModelConverter. ([40acf7dc](https://github.com/SylphxAI/firestore_odm/commit/40acf7dc20d5c76d724992457dca47bf2f688809))
 - **FIX**: list and map casting. ([349c29e9](https://github.com/SylphxAI/firestore_odm/commit/349c29e9e531ab4eb6873fc87a9f0f84799b53a8))
 - **FEAT**: update AnnotationConverter to use fromJson and toJson methods; refactor FieldInfo and ModelAnalysis to utilize TypeAnalysisResult. ([7cf6784d](https://github.com/SylphxAI/firestore_odm/commit/7cf6784d1a9491495c9800b5c6c940c3f4ccfc78))
 - **FEAT**: add support for manual serialization in ConverterGenerator. ([aa0ed533](https://github.com/SylphxAI/firestore_odm/commit/aa0ed53334398013d476749a5f0349ce976ff06f))
 - **FEAT**: enhance UpdateGenerator to support custom toFirestore expressions for fields with converters. ([c9fd3091](https://github.com/SylphxAI/firestore_odm/commit/c9fd3091a288a8d1d33af616027e0577e4de0c19))
 - **FEAT**: add nestedProfiles field to ListLengthModel and update JSON conversion logic. ([447a5f77](https://github.com/SylphxAI/firestore_odm/commit/447a5f77684382aa86b61c0f06889713b022706f))
 - **FEAT**: add automatic JSON conversion support for generic collections. ([c115bcfb](https://github.com/SylphxAI/firestore_odm/commit/c115bcfb0ca237452b20736a5b64accafee933f6))
 - **FEAT**: enhance Firestore converters to support custom IList, ISet, and IMap types with dynamic conversion expressions. ([6e7456c0](https://github.com/SylphxAI/firestore_odm/commit/6e7456c0d4a2d2f10d4822207186bbd3429abdfd))
 - **FEAT**: enhance Firestore type determination by incorporating @JsonConverter support. ([213b2821](https://github.com/SylphxAI/firestore_odm/commit/213b28215b37540b68695121a344800c962cb2e3))
 - **FEAT**: enhance FirestoreType enum and add Firestore type determination for Dart types. ([35c63402](https://github.com/SylphxAI/firestore_odm/commit/35c63402b0e90da4815716a63d9082bb9a5f6751))
 - **FEAT**: add DurationFieldUpdate class and support for Duration type in update generator. ([5cca1de8](https://github.com/SylphxAI/firestore_odm/commit/5cca1de88bfd417172336f9ac5832be68bfc1e5b))
 - **FEAT**: enhance update builder with DefaultUpdateBuilder and streamline field update methods. ([1b277aa0](https://github.com/SylphxAI/firestore_odm/commit/1b277aa03a5b543ef23fa9380e58b4e9796a4d67))

## 2.2.2

 - **FIX**: IMap bug fixes and patch operations in UpdateBuilder. ([579476a4](https://github.com/SylphxAI/firestore_odm/commit/579476a4e9039fb1416ec8e2ac271c7e9cb3a3a6))

## 2.2.1

 - **REFACTOR**: remove debug print statements from model analysis and firestore generator. ([98217a66](https://github.com/SylphxAI/firestore_odm/commit/98217a662835489eddfe034aa3a48c6b5171c92c))

## 2.2.0

 - **REFACTOR**: remove unused variables and simplify field analysis in ModelAnalyzer. ([1032f4e0](https://github.com/SylphxAI/firestore_odm/commit/1032f4e0e746c7965ab24491539747c9df427d60))
 - **FIX**: specify version for firestore_odm_annotation dependency in pubspec.yaml. ([a768af95](https://github.com/SylphxAI/firestore_odm/commit/a768af9501fab24a4b9680109bd089b22465bfa5))
 - **FEAT**: Add comprehensive batch operations support. ([802a629b](https://github.com/SylphxAI/firestore_odm/commit/802a629b2efe4e8c95b8efeb9766dff0b69f62d3))
 - **FEAT**: refactor project folder structure. ([d4907075](https://github.com/SylphxAI/firestore_odm/commit/d49070757a19ea643d73e2aa0664754f0c67da44))
 - **DOCS**: Update all documentation URLs to GitHub Pages. ([321ccdcd](https://github.com/SylphxAI/firestore_odm/commit/321ccdcd10f31374f6cd5b955fa3b7cb2d7f17fa))
 - **DOCS**: refactor and centralize README.md. ([7c121c62](https://github.com/SylphxAI/firestore_odm/commit/7c121c62981001803322ff5af1e2bb3f4593c46c))

## 2.1.0

 - **FEAT**: add json_annotation dependency to pubspec.yaml. ([f2c7f28d](https://github.com/SylphxAI/firestore_odm/commit/f2c7f28d17e698caeaad53777a7ce718534b1d03))

## 2.0.1

 - **REFACTOR**: code formatting and improve readability across multiple files. ([4a7876b7](https://github.com/SylphxAI/firestore_odm/commit/4a7876b7a16fb389301b9bdb924b24b9e4bbbde6))
 - **REFACTOR**: update Firestore ODM builders to enhance type handling and improve code structure. ([841f5073](https://github.com/SylphxAI/firestore_odm/commit/841f5073c553c3793d4c8f1e4bf887663ba28ff6))
 - **REFACTOR**: update to use element2 API for improved type handling. ([77260aa7](https://github.com/SylphxAI/firestore_odm/commit/77260aa7d8ffcb22fadd8414e9e4a89aed8ffcf9))
 - **REFACTOR**: firestore ODM code generation to utilize ModelAnalysis. ([1e82daab](https://github.com/SylphxAI/firestore_odm/commit/1e82daaba984ebd3d3d3ec15d80d855e29869221))
 - **REFACTOR**: refactor and clean up code across multiple files. ([cc44c322](https://github.com/SylphxAI/firestore_odm/commit/cc44c322b43fb72bdeebb20b0a87ccd8fcb64607))

## 2.0.0

> Note: This release has breaking changes.

 - **REFACTOR**: remove TupleAggregateQuery and UpdateBuilder, introduce utility functions for Firestore data processing. ([8a224de8](https://github.com/SylphxAI/firestore_odm/commit/8a224de8d9dea2cc9938c707f53ef4210965d47a))
 - **FIX**: implement defer writes pattern to resolve read-write ordering. ([cf1ae907](https://github.com/SylphxAI/firestore_odm/commit/cf1ae907eb91b926bbf8e0b116e7dc3e5e72da5d))
 - **FEAT**: enhance type analysis with robust iterable and map support in generators. ([0d4ed7bf](https://github.com/SylphxAI/firestore_odm/commit/0d4ed7bf835eae141783b5194c9ddd01dbbd31f4))
 - **FEAT**: add map operations, bulk delete, and collection bulk operations with comprehensive testing. ([d5612029](https://github.com/SylphxAI/firestore_odm/commit/d5612029e4c662d9054716a85f19076defc6e14a))
 - **FEAT**: Enhance transaction support in Firestore ODM. ([5ba0b618](https://github.com/SylphxAI/firestore_odm/commit/5ba0b618605f8e8c28ae6d20234de55ee26e1d0d))
 - **FEAT**: Implement pagination support in Firestore ODM. ([6abde897](https://github.com/SylphxAI/firestore_odm/commit/6abde8976e51ec63cededee286b750e85ba6dd3a))
 - **FEAT**: implement callable update and order by instances to reduce generated code. ([cf16cea8](https://github.com/SylphxAI/firestore_odm/commit/cf16cea8a10fddd89f88a3fc6063cff5b5c9b2d9))
 - **BREAKING** **FEAT**: add aggregation and pagination support with builder-to-selector refactor. ([8978198c](https://github.com/SylphxAI/firestore_odm/commit/8978198c704dc3e8600ac6f5ffdcd64ae090352c))

## 1.1.2

 - **REFACTOR**: remove unused _getSingularName method. ([8020f9e1](https://github.com/SylphxAI/firestore_odm/commit/8020f9e1dfbca4635ebc964468003fd500239134))
 - **REFACTOR**: remove obsolete document access method generation. ([09a25af4](https://github.com/SylphxAI/firestore_odm/commit/09a25af416f918108c076777f408943b31aabaf9))
 - **REFACTOR**: implement callable filter instances to reduce generated code. ([a19b2f11](https://github.com/SylphxAI/firestore_odm/commit/a19b2f11708ff2a74ccc0cfa0c7055e6bf5beb81))
 - **REFACTOR**: integrate ModelConverter for data transformation across services. ([90979671](https://github.com/SylphxAI/firestore_odm/commit/90979671500403715b910e436ba2108264efc1d3))
 - **REFACTOR**: remove local path references to firestore_odm_annotation. ([48b84db7](https://github.com/SylphxAI/firestore_odm/commit/48b84db75f4947c122bc57a7090d716b9127dedd))
 - **REFACTOR**: remove unused imports and obsolete schema generation method. ([86c0525a](https://github.com/SylphxAI/firestore_odm/commit/86c0525acdd3b91125fdec12d1b1007b02dd2bbb))
 - **REFACTOR**: simplify CollectionInfo and remove unused suffix generation. ([9087b3d1](https://github.com/SylphxAI/firestore_odm/commit/9087b3d1adee124ff461271a13cf5f24d652ea9f))

## 1.1.1

 - **REFACTOR**: improve schema class name generation and add assigned value extraction. ([997aa36a](https://github.com/SylphxAI/firestore_odm/commit/997aa36a53c6c740532ccb3923be9f11e7420aed))

## 1.1.0

 - **REFACTOR**: transform monolithic FirestoreGenerator into modular architecture. ([a3d79960](https://github.com/SylphxAI/firestore_odm/commit/a3d7996001948b1e9f85396b3451c36139b8cbf7))
 - **REFACTOR**: Remove all hardcoded field names and simplify generator. ([8afa7ecd](https://github.com/SylphxAI/firestore_odm/commit/8afa7ecd03141a8f19aeeecf30cfdfd767009daf))
 - **REFACTOR**: Move basic field builders from generator to core package. ([eb71eaea](https://github.com/SylphxAI/firestore_odm/commit/eb71eaeaaf7eed1ecc06a7303dfcec2998f31556))
 - **REFACTOR**: clean up API naming and remove legacy methods. ([d4045b14](https://github.com/SylphxAI/firestore_odm/commit/d4045b1477c6f9620ee688ba2a8c2cba1de871fb))
 - **FIX**: eliminate duplicate collection classes for same model. ([3142a19a](https://github.com/SylphxAI/firestore_odm/commit/3142a19aaf8f95f7126c151f153759771863ac3b))
 - **FIX**: refactor collection classes to be generic and reusable. ([f873b8be](https://github.com/SylphxAI/firestore_odm/commit/f873b8bec9b694816ff9712660f1020b088f1ff9))
 - **FIX**: Restore path dependencies for proper development workflow. ([d4d555c0](https://github.com/SylphxAI/firestore_odm/commit/d4d555c02101ca1fa2d560e74f360d16b8a8e575))
 - **FIX**: restore nested updater class generation. ([8b32dc96](https://github.com/SylphxAI/firestore_odm/commit/8b32dc967daf8ddf8f3c7bc07a1a0d087b7ea88d))
 - **FIX**: remove hardcoded 'id' references, use dynamic documentIdField. ([135af011](https://github.com/SylphxAI/firestore_odm/commit/135af01160b93c0043239a01574a38b1b1b47ae2))
 - **FIX**: Resolve remaining lint issues in generated code. ([13e6288e](https://github.com/SylphxAI/firestore_odm/commit/13e6288e353448162dfaf3d5563b69d1bb27cb5b))
 - **FIX**: Resolve lint issues in generated code. ([4133293c](https://github.com/SylphxAI/firestore_odm/commit/4133293cf8e3c2525c93ee06832152b0c71e4318))
 - **FIX**: Remove unnecessary null assertion from filter addition in Firestore generator. ([4f6fb294](https://github.com/SylphxAI/firestore_odm/commit/4f6fb2948925a555c1fa484c536a6d0c8f07edac))
 - **FEAT**: implement type-safe aggregate operations and count queries with generated field selectors. ([8e95df5b](https://github.com/SylphxAI/firestore_odm/commit/8e95df5b4a741af567c452fe32c480f8abb3813e))
 - **FEAT**: Introduce schema-based architecture for Firestore ODM. ([de939d90](https://github.com/SylphxAI/firestore_odm/commit/de939d903821a94c962f0d354e982c3b062dfc30))
 - **FEAT**: Successfully publish all packages to pub.dev. ([9e10b6c6](https://github.com/SylphxAI/firestore_odm/commit/9e10b6c61897fc4c876c8d30a3b9f2ff3302edb7))
 - **FEAT**: Complete CI/CD pipeline setup with melos for publishing. ([5f3e440c](https://github.com/SylphxAI/firestore_odm/commit/5f3e440ca1b177a9fa3361792bda02949b3743fe))
 - **FEAT**: convert FirestoreODM constructor to named parameters. ([519b3e14](https://github.com/SylphxAI/firestore_odm/commit/519b3e14d7890bb7be206243633ebbd300fba1d5))
 - **FEAT**: Add support for automatic document ID detection in models. ([6b0c1101](https://github.com/SylphxAI/firestore_odm/commit/6b0c1101d79dfe6c1678367f94754528217e0b89))
 - **FEAT**: unify Collection annotation to support multiple collection paths. ([9fbb73b6](https://github.com/SylphxAI/firestore_odm/commit/9fbb73b69385e2f1ed1fece91299102c3a3bd1c4))
 - **FEAT**: implement multiple @Collection annotations with subcollection support. ([10a9564b](https://github.com/SylphxAI/firestore_odm/commit/10a9564bde3d90a4caa4101d7c88bc03414f4233))
 - **FEAT**: add comprehensive @Collection validation system. ([12659528](https://github.com/SylphxAI/firestore_odm/commit/126595284c0e21d8ffb4cb5f6a46e75e1e17660d))
 - **FEAT**: refactor to unified @Collection annotation with subcollection support. ([c4330d39](https://github.com/SylphxAI/firestore_odm/commit/c4330d39a898bb6c8caaffffcfa7b2ff6e88cfdc))
 - **FEAT**: add @DocumentIdField annotation support. ([9cfb884d](https://github.com/SylphxAI/firestore_odm/commit/9cfb884d59d8922ff2b64e819c05f404575c365e))
 - **FEAT**: Remove legacy orderBy methods from implementation and tests. ([e77a6349](https://github.com/SylphxAI/firestore_odm/commit/e77a6349cf364125d3e31b82bc0e8ad394af6817))
 - **FEAT**: Update test cases to support mixed update syntax and update README. ([5785fc80](https://github.com/SylphxAI/firestore_odm/commit/5785fc8055ce297358a1e2050b79b3b6b94e2c83))
 - **FEAT**: complete Firestore ODM library implementation. ([f7b0da36](https://github.com/SylphxAI/firestore_odm/commit/f7b0da366e149110f855e69eacbdcfbcfa0bc19c))
 - **FEAT**: implement chained updates and enhanced ODM features. ([59460a10](https://github.com/SylphxAI/firestore_odm/commit/59460a1083e26efbaa749ea56fb8e2d97b915e95))
 - **FEAT**: implement nested field updates with copyWith-style API. ([a968695a](https://github.com/SylphxAI/firestore_odm/commit/a968695a9e5dfb1c8ae3790877651b7d3782d804))
 - **FEAT**: comprehensive testing of complex data types and extension methods. ([56ff7e93](https://github.com/SylphxAI/firestore_odm/commit/56ff7e936abac6ae8995908ecca880df6795be8a))
 - **FEAT**: implement RxDB-style API with atomic operations. ([08af4f52](https://github.com/SylphxAI/firestore_odm/commit/08af4f52da200d4522380c95954fe25311b6df46))
 - **FEAT**: restructure as monorepo with strong-typed Firestore ODM. ([b9e6ced0](https://github.com/SylphxAI/firestore_odm/commit/b9e6ced07c38c798ec594a0c96292c86888422f7))
 - **FEAT**: Complete Firestore ODM example with working code generation. ([77f515bf](https://github.com/SylphxAI/firestore_odm/commit/77f515bf93bcfb32010fe33ab1988a6fc7623055))
 - **FEAT**: Convert Firestore ODM to monorepo library. ([279e3547](https://github.com/SylphxAI/firestore_odm/commit/279e35473d592307bec352a9af359a798f2cc224))

# Changelog

## [1.0.0] - 2025-01-09

### Added
- Initial release of firestore_odm_builder
- Code generation for @Collection and @SubCollection annotations
- Type-safe query builder generation
- Automatic serialization/deserialization code generation
- Real-time snapshot support generation
- Transaction and batch operation support
- Comprehensive error handling and validation