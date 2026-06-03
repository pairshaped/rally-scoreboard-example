# Use Proute For Routing And Page Glue

Proute owns Elm-land-style file routing for the unified source chase target. Rally consumes Proute output instead of owning route discovery, page enums, route params, query params, or page dispatch shape itself.

Generated routing and page modules live under `src/generated/proute/**`. Rally-generated transport, SSR, hydration, and browser boot code should compose with those modules. This keeps Rally focused on page protocol generation and runtime glue while Proute remains the routing boundary.
