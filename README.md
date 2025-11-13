# crunchy-pgvectors-vectorchord

This exists because I couldn't get [Immich's documented migration instructions to work at all](https://github.com/immich-app/immich/issues/23821).

This repository provides a Docker image based on CrunchyData Postgres that bundles two vector-related Postgres extensions and migration tooling to support migrating from `pgvector` to Immich's recommended approach using the external VectorChord extension.

Purpose
-------
The image is intended as a transitional build used when migrating an existing Postgres instance that uses `pgvector` (or other vector extensions) to Immich's recommended VectorChord-based approach. It includes:

- VectorChord (vchord) — VectorChord extension binaries and SQL files are included and installed into the CrunchyData Postgres image.
- pgvecto.rs (vectors) — The vectors extension (pgvecto.rs) compiled assets are included.

These components are intended to help with migration workflows described by Immich and implemented by the referenced projects.

Why this image exists
---------------------
Immich documents a migration path for moving from `pgvector` to their own vector extension in the Administration docs:

- Immich migration guide: https://docs.immich.app/administration/postgres-standalone/#migrating-from-pgvectors

This repository assembles a CrunchyData-based Postgres image that includes the tooling and extensions used in community projects to convert or support vector data formats during migration.

Related projects / implementation references
-------------------------------------------
This image and the included logic are based on and borrow implementation details from these repositories:

- JanPretzel/crunchydata-vectorchord — https://github.com/JanPretzel/crunchydata-vectorchord
- chkpwd/cdpgvecto.rs — https://github.com/chkpwd/cdpgvecto.rs

These projects provide the GitHub Actions workflows, packaging and extraction logic used to fetch and install the appropriate extension binaries into a CrunchyData Postgres image.

Usage
-----
Build locally (example):

```bash
# From repository root
docker build -t crunchy-pgvectors-vectorchord .
```

Run a container (example):

```bash
docker run --rm -e POSTGRES_PASSWORD=secret -p 5432:5432 crunchy-pgvectors-vectorchord
```

Notes
-----
- The CrunchyData base image included in this repo already contains the `pgvector` extension. VectorChord requires `pgvector` and this repo preserves that compatibility.
- Adjust `versions.yaml` to change the matrix used by the included GitHub Actions workflow (.github/workflows/docker.yml).
- The provided image is intended for migration/testing — review security, user, and backup procedures before running in production.

Builder/asset note
------------------
- The `pgvecto.rs` (vectors) asset download used in the build is currently pinned to a specific package (pg16 amd64) in the builder stage. This choice keeps the build simple and predictable. If you need full multi-arch or multi-PG-major support for `pgvecto.rs`, we can update the builder to select the correct release asset per `PG_MAJOR` and `TARGETARCH` (recommended for production), but that is a slightly more invasive change.

License and attribution
-----------------------
This repository assembles upstream binaries and uses logic referenced from the listed projects. Check the individual project licenses for distribution terms of the included binaries.
