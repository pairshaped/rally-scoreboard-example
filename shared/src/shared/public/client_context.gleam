//// Per-Mount client context for the public Mount.
////
//// Shell-level state that public pages can read without keeping it as local
//// page state. The server SSR handler encodes this into the boot payload;
//// the client setup bridge decodes it and passes it into the Lustre app init.

pub type PublicClientContext {
  PublicClientContext(league_name: String, active_section: String)
}
