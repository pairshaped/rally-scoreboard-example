import generated/proute/public/page_input
import gleam/list
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import public/page_shared_state.{type PublicPageSharedState}

/// Proute page model for the sign-in route.
/// generated/proute/public/pages stores this inside the SignInPage variant.
pub type Model {
  Model(return_to: String, invalid: Bool)
}

/// Proute page message for the sign-in route.
/// generated/proute/public/pages wraps this as SignInMsg and routes it back into
/// this module's update function.
pub type Message {
  NoOp
}

/// Pure starting state for the sign-in page.
/// It keeps the return target and error flag in the model so SSR and browser
/// hydration render the same form without needing any init effects.
pub fn initial_model(
  _page_shared_state: PublicPageSharedState,
  query_params: page_input.QueryParams,
) -> Model {
  let page_input.QueryParams(values:) = query_params
  Model(
    return_to: find_query(values, "return_to") |> safe_admin_return_to,
    invalid: find_query(values, "error") == Ok("invalid"),
  )
}

/// Proute page update function for the sign-in route.
/// generated/proute/public/pages calls this when SignInMsg is active.
pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

/// Proute page view function for the sign-in route.
/// generated/proute/public/pages calls this when rendering SignInPage.
pub fn view(model model: Model) -> Element(Message) {
  html.section([attribute.class("panel")], [
    html.h1([], [html.text("Sign in")]),
    html.p([attribute.class("muted")], [
      html.text("Use the demo admin code to open the score desk."),
    ]),
    case model.invalid {
      True ->
        html.p([attribute.class("auth-error")], [
          html.text("Invalid sign-in code."),
        ])
      False -> html.text("")
    },
    html.form(
      [
        attribute.method("post"),
        attribute.action("/sign_in"),
        attribute.class("sign-in-form"),
      ],
      [
        html.input([
          attribute.type_("hidden"),
          attribute.name("return_to"),
          attribute.value(model.return_to),
        ]),
        html.label([attribute.for("code")], [html.text("Sign-in code")]),
        html.input([
          attribute.id("code"),
          attribute.name("code"),
          attribute.type_("text"),
          attribute.autocomplete("one-time-code"),
          attribute.placeholder("A1Z9Q"),
          attribute.required(True),
        ]),
        html.button([attribute.type_("submit")], [html.text("Sign In")]),
      ],
    ),
  ])
}

fn find_query(
  values: List(#(String, String)),
  key: String,
) -> Result(String, Nil) {
  list.find_map(values, fn(pair) {
    case pair.0 {
      name if name == key -> Ok(pair.1)
      _ -> Error(Nil)
    }
  })
}

fn safe_admin_return_to(path: Result(String, Nil)) -> String {
  case path {
    Ok("/admin") -> "/admin"
    Ok("/admin/" <> rest) -> "/admin/" <> rest
    _ -> "/admin/games"
  }
}
