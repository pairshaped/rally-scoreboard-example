# Keep Codec Runtime Dependencies

Libero and Rally remain runtime dependencies for the code they own.

Libero owns ETF wire encoding, decoding, decoder registration, atom registration, wire metadata, and contract metadata. Libero-generated modules live under `src/generated/libero/**`, and generated Rally protocol glue calls Libero-generated codec helpers instead of copying ETF runtime code into `src/generated/rally/**`.

Rally owns framework glue around those codecs: request ids, pending callback registration, websocket transport, result envelopes, push frame dispatch, hydration decoding, browser boot, SSR composition, and server dispatch. Rally-generated modules live under `src/generated/rally/**`, and may wrap Libero-generated helpers when the app-facing API needs a smaller surface.

The app depends on these runtime surfaces:

- `generated/libero/result` for page-local load and save error values at the Rally boundary.
- `generated/libero/codec_ffi.mjs` for browser ETF encode/decode of page-local request, result, and broadcast values.
- Libero Erlang codec helpers for safe server decode and ETF encode.
- `generated/rally/client_transport` for websocket connection, request ids, and result callback dispatch.
- `generated/rally/client_protocol` and `generated/rally/server_protocol` for request, result, and push frame envelopes.
- `generated/rally/browser`, boot, hydration, and mount helpers for browser-specific framework plumbing.

Rally should not generate ETF codec modules, atom modules, wire modules, decoder registration modules, or Libero contract JSON. If generated Rally code needs a server-side codec entrypoint, Libero should expose a neutral generated helper that is not typed around a root app protocol. Rally can call that helper from `generated/rally/server_protocol`.

The target page API remains:

```gleam
server.send(ServerMsg, on_result: fn(result) { Msg(result) })
```

`server.send` returns a Lustre `Effect(Msg)`. Rally owns request correlation and dispatching the selected callback. Libero owns the concrete ETF representation. Page code owns the `ServerMsg`, success payload, error payload, and local completion message.

Mutation replies and broadcasts stay separate. The initiating connection updates from the request result payload. Other subscribed connections update from broadcasts. The application owns the broadcast event shape and subscription policy.
