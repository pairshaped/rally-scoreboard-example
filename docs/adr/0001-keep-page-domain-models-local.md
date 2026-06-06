# Keep Page Domain Models Local

## Status

Accepted

## Decision

Page data shapes belong to the page that renders and updates them. A list page,
detail page, and admin editing page may duplicate similar fields because they
describe different page needs.

Page modules should not import payload types from other page modules. In this
app, `public/pages/games.gleam` defines game list rows,
`public/pages/games/id_.gleam` defines game detail data, and
`admin/pages/games.gleam` defines admin game rows. These types may share fields,
but they are independent page contracts.

Extract a shared type only when it is a stable app concept independent of a
page, such as an identifier, enum, topic, or value object. Page payloads, table
rows, detail data, and save responses stay page local.

## Consequences

Public pages and admin pages can diverge without turning one page's current
data need into an app-wide contract.

The example stays close to Rally's page-local wire model while keeping product
shapes easy to inspect in the page that owns them.
