# Enforce Wire Boundaries

Wire-visible page protocols may reference only:

- types defined in the owning page module
- types defined under `src/wire/**`
- primitives
- standard containers such as `List`, `Result`, `Option`, tuples, and records that contain approved wire-visible types

The approved root wire namespace is `src/wire/**`.

Wire-visible page protocols must not reference helper, service, query, business, formatting, or display types. This rule is transitive: a type that contains an unapproved owned type is not wire-visible.

Helpers, services, query modules, business modules, formatting modules, and display modules are still allowed as behavior. Page code can call them. Their owned shapes cannot become wire contract shapes.

Proute owns URL routing and page identity. Rally consumes Proute's page, action, or channel identity when dispatching incoming wire messages, and decodes page-local payloads only after that destination is known. Page-local type names remain page-local, so two pages may both define `Item` without global type identity hashes.

Boundary diagnostics should name the violated contract, the page/action/channel, the offending type or import, the path that made it reachable, and the smallest likely fix.

The chase should stop and revisit the design if page-local decoding still requires global type identity hashes, boundary checking requires brittle whole-program magic, or Rally cannot produce humane diagnostics for bad type or import boundaries.
