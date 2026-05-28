//// Shared UI components usable by both client and server.
////
//// These are pure Lustre elements. They do not import transport, modem,
//// browser setup, or route modules.

import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event
import shared/api/domain/game

pub fn theme_switch(
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

pub fn section_head(title: String, subtitle: String) -> Element(msg) {
  html.div([attribute.class("section-head")], [
    html.div([], [
      html.h1([], [html.text(title)]),
      case subtitle {
        "" -> html.span([], [])
        _ -> html.p([attribute.class("muted")], [html.text(subtitle)])
      },
    ]),
  ])
}

pub fn page_explainer(summary: String, points: List(String)) -> Element(msg) {
  html.section([attribute.class("page-explainer")], [
    html.details([], [
      html.summary([], [html.text(summary)]),
      html.ul(
        [],
        list.map(points, fn(point) { html.li([], [html.text(point)]) }),
      ),
    ]),
  ])
}

pub fn nav_link_external(
  path path: String,
  label label: String,
  active active: Bool,
) -> Element(msg) {
  html.a(
    [
      attribute.href(path),
      attribute.class(case active {
        True -> "active"
        False -> ""
      }),
    ],
    [html.text(label)],
  )
}

pub fn status_badge(status: game.GameStatus) -> Element(msg) {
  case status {
    game.Scheduled ->
      html.span([attribute.class("badge")], [html.text("Scheduled")])
    game.Live(period) ->
      html.span([attribute.class("badge live")], [html.text(period)])
    game.Final ->
      html.span([attribute.class("badge final")], [html.text("Final")])
  }
}

pub fn not_found_view() -> Element(msg) {
  html.main([attribute.class("panel")], [
    html.h1([], [html.text("Not found")]),
    html.p([attribute.class("muted")], [
      html.text("This page does not exist."),
    ]),
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
