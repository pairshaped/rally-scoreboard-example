# Keep Page Domain Models Local

Page data shapes belong to the page that renders and updates them. A list page, detail page, and form page should duplicate similar fields instead of sharing one model just because their current shapes overlap.

Page modules must not import domain models from other page modules. If two pages both need game data, `games/index.gleam` can define `GameSummary`, `games/id_.gleam` can define `GameDetail`, and `games/edit.gleam` can define `GameForm`. Those types may share field names, but they describe different page needs and should be free to diverge.

Extract a shared type only when it is a stable app concept independent of a page, such as an identifier, enum, or value object. Page payloads, form models, table rows, detail data, and save responses stay page local. This keeps page protocols independent and prevents a shared shape from becoming a hidden app-wide contract.
