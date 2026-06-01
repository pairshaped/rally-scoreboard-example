# Keep Generated Dispatch Inside Backend Update

The generator's root dispatch routes a Mount `ToServer` command to the one handler for that constructor. It receives the current `backend.Model`, `RequestContext`, and `ServerContext`, then returns `#(backend.Model, Effect(ToClient))`.

The runtime decodes the wire frame, builds `backend.Msg.FromClient(ToServer, RequestContext)`, and calls `backend.update`. The backend update may handle that message itself or delegate to generated dispatch. Dispatch owns generated routing logic once the backend delegates.

Generated dispatch does not decode wire frames, encode responses, or choose transport framing. The WebSocket runtime owns decoding, effect execution, and fanout behavior. `ToServer` command frames are fire-and-forget at the transport layer; app-visible outcomes are emitted as `ToClient` pushes.

Internal compatibility modules may use their own dispatch result shapes. Those shapes are not the root API contract.
