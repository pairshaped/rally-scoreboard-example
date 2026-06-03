# Generate Target Specific Framework Glue

Whole modules where every import and declaration is target annotated are framework glue, not user-authored page code. Rally should generate or own those modules so user pages keep the clean shared, client, and server section shape.

Browser boot, hydration, client transport, per-page server dispatch, SSR handlers, and page protocol codecs are generator-owned. User-owned modules should not be files that exist only to wrap target-specific generated plumbing.

Scoreboard Unified still compiles as one package for JavaScript and Erlang. Target annotations remain the mechanism for separating platform-specific code, but generated framework glue should carry most of the repetitive annotation burden.
