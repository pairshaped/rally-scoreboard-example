# Separate Libero Proute And Rally Roles

Libero owns wire contract generation for ETF transport. It scans wire-visible types and handlers, writes ETF codec modules, decoder registration, atom and wire modules, and contract metadata. Libero-generated files live under the Libero generated namespace, such as `src/generated/libero/**`.

Proute owns routing and page glue. It discovers routes, generates route types, page enums, route params, query params, and page dispatch shape. Proute-generated files live under `src/generated/proute/**`.

Rally owns the framework glue that Libero and Proute do not own, plus the framework plumbing that can be extracted from the application without stealing application behavior. It consumes Proute route and page identity, consumes Libero ETF codecs and contract output, and generates app-facing modules for transport, request/result correlation, hydration, SSR composition, browser boot, server dispatch, and build metadata. Rally-generated files live under `src/generated/rally/**`.

Rally must not generate Libero-owned files. Rally can import Libero-generated codec modules and call Libero helpers, but it should not write ETF codec modules, atom modules, wire modules, decoder registration modules, or contract JSON. If Rally needs a wrapper around Libero output, that wrapper belongs under `src/generated/rally/**` and should be named as Rally protocol or framework glue.

Rally must not generate Proute-owned files. Rally can consume Proute output, but it should not rediscover routes, define route params, generate page enums, or decide page dispatch shape.

This separation keeps user code simple without merging the libraries into one generator. User-authored pages should interact with a small Rally-facing API, while Libero and Proute remain the lower-level generated boundaries that Rally composes.

Application-owned code stays in the application. Rally should not generate domain decisions, page update behavior, view behavior, business rules, query ownership, or page-specific result-to-message choices that need product knowledge. When a repeated app pattern is noisy but still encodes page behavior, Rally should expose a simpler API or compose an application-owned callback rather than generating the behavior itself.
