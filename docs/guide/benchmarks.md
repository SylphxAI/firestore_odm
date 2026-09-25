# Benchmarks

Two questions: how long does code generation take, and what does the ODM cost
at runtime compared with using `cloud_firestore` directly?

## Results

RESULTS

## Method

Everything is in the repository's
[`benchmarks/`](https://github.com/SylphxAI/firestore_odm/tree/main/benchmarks)
directory and runs with one command, `benchmarks/run.sh`, on a GitHub-hosted
Ubuntu runner (the [Benchmarks workflow](https://github.com/SylphxAI/firestore_odm/actions/workflows/benchmarks.yml)).

**Projects.** Two Flutter projects, each on the newest toolchain its ODM
supports:

- `benchmarks/firestore_odm`: firestore_odm 5.1, cloud_firestore 6,
  fake_cloud_firestore 4, current build_runner.
- `benchmarks/cloud_firestore_odm`: cloud_firestore_odm 1.0.0-dev.88 (its last
  release), cloud_firestore 5, fake_cloud_firestore 3, build_runner 2.4.13 and
  json_serializable 6.8 (the newest its generator resolves with).

**Code generation.** `benchmarks/generate_models.dart` writes the same 20
models into both projects (id plus eight fields: strings, ints, a double, a
bool, a nullable DateTime and a string list). cloud_firestore_odm models also
carry `@JsonSerializable`, which it requires; firestore_odm models are plain
classes. Timed with the wall clock:

- *First build*: no build cache, so it includes compiling the build script.
- *Rebuild after editing every model*: every model file changed, build script
  already compiled.
- *Rebuild after editing one model*: the everyday edit-and-rebuild loop.

**Runtime.** The same `Movie` model and workload run through each ODM and
through raw `cloud_firestore` typed with `withConverter` (the baseline), on
an in-memory Firestore (`fake_cloud_firestore`), in `flutter test`:

- *set*: 500 document writes.
- *get*: 500 single-document reads.
- *query*: 20 runs of `year >= 2000`, ordered by `likes` descending, limit 100,
  over 500 documents.
- *update*: 500 increments of `likes`.
- *mapping*: 20,000 model-to-map-to-model conversions, no Firestore involved.

Each measurement runs once to warm up, then seven times; the table reports the
median in microseconds per operation. Each ODM is compared with the raw
baseline on its own cloud_firestore major, because the two in-memory
Firestore versions differ.

**What this does not measure.** Network and server time dominate real
Firestore calls and are the same with or without an ODM, so these numbers
show the ODM's own overhead, not end-to-end latency.
