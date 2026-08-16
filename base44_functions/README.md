# Base44 backend implementation notes

The Flutter client intentionally has **zero provider secrets**.

Create backend functions:
- chat
- routeModel
- processFile
- generateImage
- textToSpeech

Create separate adapters:
- xkiro
- groq
- openrouter
- image
- tts

Required secrets:
- XKIRO_API_KEY
- GROQ_API_KEY
- OPENROUTER_API_KEY

Optional:
- IMAGE_PROVIDER_API_KEY
- TTS_PROVIDER_API_KEY

The Flutter app expects the chat function to return SSE or NDJSON stream events:
`token`, `done`, `error`.

The included `chat.ts` is a contract/reference because Base44 projects can expose different function wrappers and runtime APIs. Adapt only the runtime handler/export syntax to the exact Base44 project. Do not copy provider keys into the mobile app.
