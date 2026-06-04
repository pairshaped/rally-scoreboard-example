# Separate Libero Proute And Rally Roles

Libero owns wire contract generation for ETF transport. It scans wire-visible types and handlers, writes ETF codec modules, decoder registration, atom and wire modules, and contract metadata. Libero-generated files live under the Libero generated namespace, such as `src/generated/libero/**`.

Proute owns routing and page glue. It discovers routes, generates route types, page enums, route params, query params, and page dispatch shape. Proute-generated files live under `src/generated/proute/**`.

Rally owns the framework glue that Libero and Proute do not own, plus the framework plumbing that can be extracted from the application without stealing application behavior. It consumes Proute route and page identity, drives Libero for Rally-managed wire contracts, and generates app-facing modules for transport, request/result correlation, hydration, SSR composition, browser boot, server dispatch, and build metadata. Rally-generated files live under `src/generated/rally/**`.

Rally may orchestrate Libero generation for Rally-managed surfaces. The generated ETF codec modules, atom modules, wire modules, decoder registration modules, and contract JSON remain Libero-owned artifacts under `src/generated/libero/**`, produced through Libero's generator API. If Rally needs a wrapper around Libero output, request/result envelope, or Rally boundary value, that wrapper belongs under `src/generated/rally/**` and should be named as Rally protocol or framework glue.

Rally must not generate Proute-owned files. Rally can consume Proute output, but it should not rediscover routes, define route params, generate page enums, or decide page dispatch shape.

This separation keeps user code simple without merging the libraries into one generator. User-authored pages should interact with a small Rally-facing API, while Libero and Proute remain the lower-level generation engines that Rally composes.

Application-owned code stays in the application. Rally should not generate domain decisions, page update behavior, view behavior, business rules, query ownership, or page-specific result-to-message choices that need product knowledge. When a repeated app pattern is noisy but still encodes page behavior, Rally should expose a simpler API or compose an application-owned callback rather than generating the behavior itself.
