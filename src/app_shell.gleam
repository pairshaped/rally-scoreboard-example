import authentication_context.{type AuthenticationContext}
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event

pub fn public(
  current_path current_path: String,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  can_access_admin can_access_admin: Bool,
  on_dark_mode_change on_dark_mode_change: fn(Bool) -> msg,
  content content: Element(msg),
) -> Element(msg) {
  html.div([attribute.class("scoreboard-app")], [
    public_topbar(
      subtitle: "Public scores",
      current_path:,
      dark_mode:,
      authentication_context:,
      can_access_admin:,
      on_dark_mode_change:,
    ),
    content,
  ])
}

pub fn admin(
  current_path current_path: String,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  on_dark_mode_change on_dark_mode_change: fn(Bool) -> msg,
  content content: Element(msg),
) -> Element(msg) {
  html.div([attribute.class("scoreboard-app admin-shell")], [
    admin_topbar(
      subtitle: "Admin score desk",
      current_path:,
      dark_mode:,
      authentication_context:,
      on_dark_mode_change:,
    ),
    content,
  ])
}

fn public_topbar(
  subtitle subtitle: String,
  current_path current_path: String,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  can_access_admin can_access_admin: Bool,
  on_dark_mode_change on_dark_mode_change: fn(Bool) -> msg,
) -> Element(msg) {
  html.header([attribute.class("topbar")], [
    html.div([attribute.class("brand")], [
      html.span([attribute.class("brand-mark")], [html.text("S")]),
      html.div([], [
        html.strong([], [html.text("Scoreboard")]),
        html.p([attribute.class("muted")], [html.text(subtitle)]),
      ]),
    ]),
    html.nav([attribute.class("nav")], [
      nav_link(
        href: "/games",
        label: "Games",
        active: is_games_path(current_path),
      ),
      nav_link(
        href: "/standings",
        label: "Standings",
        active: current_path == "/standings",
      ),
      case can_access_admin {
        True ->
          doc_link(
            href: "/admin/games",
            label: "Admin",
            active: is_admin_path(current_path),
          )
        False -> html.text("")
      },
      session_link(authentication_context, current_path),
      theme_switch(dark_mode:, on_change: on_dark_mode_change),
    ]),
  ])
}

fn admin_topbar(
  subtitle subtitle: String,
  current_path current_path: String,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  on_dark_mode_change on_dark_mode_change: fn(Bool) -> msg,
) -> Element(msg) {
  html.header([attribute.class("topbar")], [
    html.div([attribute.class("brand")], [
      html.span([attribute.class("brand-mark")], [html.text("S")]),
      html.div([], [
        html.strong([], [html.text("Scoreboard")]),
        html.p([attribute.class("muted")], [html.text(subtitle)]),
      ]),
    ]),
    html.nav([attribute.class("nav")], [
      doc_link(
        href: "/games",
        label: "Games",
        active: is_games_path(current_path),
      ),
      doc_link(
        href: "/standings",
        label: "Standings",
        active: current_path == "/standings",
      ),
      nav_link(
        href: "/admin/games",
        label: "Admin",
        active: is_admin_path(current_path),
      ),
      session_link(authentication_context, current_path),
      theme_switch(dark_mode:, on_change: on_dark_mode_change),
    ]),
  ])
}

fn session_link(
  authentication_context: Option(AuthenticationContext),
  current_path: String,
) -> Element(msg) {
  case authentication_context {
    Some(_) ->
      doc_link(
        href: "/sign_out?return_to=/games",
        label: "Sign Out",
        active: False,
      )
    None ->
      doc_link(
        href: "/sign_in",
        label: "Sign In",
        active: current_path == "/sign_in",
      )
  }
}

fn nav_link(
  href href: String,
  label label: String,
  active active: Bool,
) -> Element(msg) {
  html.a(
    [
      attribute.href(href),
      attribute.attribute("data-scoreboard-spa-nav", "1"),
      active_class(active),
    ],
    [html.text(label)],
  )
}

fn doc_link(
  href href: String,
  label label: String,
  active active: Bool,
) -> Element(msg) {
  html.a(
    [
      attribute.href(href),
      active_class(active),
    ],
    [html.text(label)],
  )
}

fn active_class(active: Bool) -> attribute.Attribute(msg) {
  attribute.class(case active {
    True -> "active"
    False -> ""
  })
}

fn theme_switch(
  dark_mode dark_mode: Bool,
  on_change on_change: fn(Bool) -> msg,
) -> Element(msg) {
  html.label([attribute.class("theme-switch")], [
    sun_icon(),
    html.input([
      attribute.type_("checkbox"),
      attribute.role("switch"),
      attribute.checked(dark_mode),
      event.on_check(on_change),
    ]),
    moon_icon(),
  ])
}

fn sun_icon() -> Element(msg) {
  svg.svg(icon_attrs("Light mode"), [
    svg.circle([
      attribute.attribute("cx", "12"),
      attribute.attribute("cy", "12"),
      attribute.attribute("r", "5"),
    ]),
    svg.line(line_attrs(x1: "12", y1: "1", x2: "12", y2: "3")),
    svg.line(line_attrs(x1: "12", y1: "21", x2: "12", y2: "23")),
    svg.line(line_attrs(x1: "4.22", y1: "4.22", x2: "5.64", y2: "5.64")),
    svg.line(line_attrs(x1: "18.36", y1: "18.36", x2: "19.78", y2: "19.78")),
    svg.line(line_attrs(x1: "1", y1: "12", x2: "3", y2: "12")),
    svg.line(line_attrs(x1: "21", y1: "12", x2: "23", y2: "12")),
    svg.line(line_attrs(x1: "4.22", y1: "19.78", x2: "5.64", y2: "18.36")),
    svg.line(line_attrs(x1: "18.36", y1: "5.64", x2: "19.78", y2: "4.22")),
  ])
}

fn moon_icon() -> Element(msg) {
  svg.svg(icon_attrs("Dark mode"), [
    svg.path([
      attribute.attribute(
        "d",
        "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z",
      ),
    ]),
  ])
}

fn icon_attrs(label: String) -> List(attribute.Attribute(msg)) {
  [
    attribute.width(16),
    attribute.height(16),
    attribute.attribute("viewBox", "0 0 24 24"),
    attribute.attribute("fill", "none"),
    attribute.attribute("stroke", "currentColor"),
    attribute.attribute("stroke-width", "2"),
    attribute.class("theme-icon"),
    attribute.role("img"),
    attribute.aria("label", label),
  ]
}

fn line_attrs(
  x1 x1: String,
  y1 y1: String,
  x2 x2: String,
  y2 y2: String,
) -> List(attribute.Attribute(msg)) {
  [
    attribute.attribute("x1", x1),
    attribute.attribute("y1", y1),
    attribute.attribute("x2", x2),
    attribute.attribute("y2", y2),
  ]
}

fn is_games_path(path: String) -> Bool {
  path == "/" || string.starts_with(path, "/games")
}

fn is_admin_path(path: String) -> Bool {
  path == "/admin" || string.starts_with(path, "/admin/")
}
