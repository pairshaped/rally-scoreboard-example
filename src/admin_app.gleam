@target(javascript)
import browser
@target(javascript)
import client/api as api_client
@target(javascript)
import client/to_client
@target(javascript)
import generated/proute/admin/page_input
@target(javascript)
import generated/proute/admin/pages
@target(javascript)
import generated/proute/admin/routes
@target(javascript)
import lustre
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import lustre/element.{type Element}
@target(javascript)
import page_context.{PageContext}

@target(javascript)
type Model {
  Model(page: pages.Page)
}

@target(javascript)
type Msg {
  PageMsg(pages.Message)
  ServerFrame(BitArray)
}

@target(javascript)
pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let _started = lustre.start(app, "#app", Nil)
  Nil
}

@target(javascript)
fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let route = routes.parse_path(browser.path())
  let #(page, page_effect) =
    pages.load(PageContext, page_input.empty_query_params(), route)

  #(
    Model(page: page),
    effect.batch([
      effect.map(page_effect, PageMsg),
      api_client.connect(url: browser.websocket_url(), on_frame: ServerFrame),
    ]),
  )
}

@target(javascript)
fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    PageMsg(inner) -> {
      let #(page, page_effect) = pages.update(PageContext, model.page, inner)
      #(Model(page: page), effect.map(page_effect, PageMsg))
    }
    ServerFrame(bytes) -> {
      let #(page, page_effect) =
        to_client.decode_and_apply_admin(page: model.page, bytes: bytes)
      #(Model(page: page), effect.map(page_effect, PageMsg))
    }
  }
}

@target(javascript)
fn view(model: Model) -> Element(Msg) {
  pages.view(model.page)
  |> element.map(PageMsg)
}
