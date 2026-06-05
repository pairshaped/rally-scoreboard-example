# Use Proute For Routing And Page Glue

Proute owns Elm-land-style file routing for the unified source chase target. Rally consumes Proute output instead of owning route discovery, page enums, route params, query params, or page dispatch shape itself.

Generated routing and page modules live under `src/generated/proute/**`. Rally-generated transport, SSR, hydration, and browser boot code should compose with those modules. This keeps Rally focused on page protocol generation and runtime glue while Proute remains the routing boundary.

Proute is the only source of truth for route and page shape. Rally should not parse the page tree independently, generate a parallel route type, infer route aliases, or decide that one route stands in for another. If `/` should render the same workflow as `/games`, `/` is still a real `home_.gleam` page and that page owns any delegation to the games page.

This is true even when Rally needs generated SSR or browser load glue. Rally may consume Proute's route values, page enums, route params, query params, and dispatch helpers to decide which generated protocol wrapper to call. It must not replace Proute with Rally-owned routing logic.

For application authors, routing is expressed through page filenames and paths. Page code may receive generated route-param and query-param values, but user-authored root modules should not match route constructors, parse route params, wrap page messages by route, or decide page load dispatch from routes. That work belongs in generated Proute and Rally glue that consumes the page tree and Proute output.
