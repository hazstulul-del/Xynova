# XYNOVA V2 — MASTER BUILD PROMPT

Build a production-ready Flutter application named **Xynova**.

CREATED BY: X Shine
YEAR: 2026
TAGLINE: Your intelligent AI.
VERSION: 2.0

## NON-NEGOTIABLE

This is a real AI client, not a landing page and not a mockup.

Never fake:
- AI responses
- streaming
- thinking
- provider status
- model availability
- camera
- microphone
- TTS
- image generation
- token usage
- download URLs

If a capability is not configured, disable it or explain that it is unavailable.

Never expose provider API keys in Flutter.

## V2 VISUAL DIRECTION

Use a refined monochrome palette only:

LIGHT
- #FFFFFF
- #FAFAFA
- #F5F5F5
- #EBEBEB
- #D8D8D8
- #A6A6A6
- #666666
- #202020
- #000000

DARK
- #050505
- #0A0A0A
- #111111
- #181818
- #242424
- #666666
- #BDBDBD
- #E8E8E8
- #FFFFFF

No blue, cyan, purple, green, red, orange, yellow, pink, gold, or colored gradients.

Use Inter/system sans-serif.

The interface should be visually closer to a premium AI workspace than a generic Flutter demo:
- medium readable text, never tiny
- 15–17px normal body text
- 13–14px secondary text
- 20–28px section headings
- 44–52px minimum touch targets
- generous message line-height
- strong contrast
- subtle 1px borders
- restrained shadows
- 14–18px corner radius
- smooth 160–220ms transitions
- no oversized empty marketing areas

## CHAT EXPERIENCE

Open directly into chat. No login/signup.

Desktop:
- 280px sidebar
- flexible conversation column
- composer centered with max width around 820px
- header around 56px

Mobile:
- full-screen conversation
- drawer sidebar
- bottom composer
- model selector as bottom sheet
- respect keyboard insets
- no horizontal overflow

Header:
- left: menu/sidebar on mobile; Xynova mark + Xynova on desktop
- center: current model
- right: new chat + settings/theme
- never show pricing, upgrade, login, signup

## LOGO

Create an original monochrome Xynova mark:
- simple geometric X + soft orbital/spark motif
- no external logo asset required
- black/white only
- readable at 24px
- larger 64px empty-state version
- never use OpenAI/Anthropic/Google/DeepSeek/Groq/xKiro/OpenRouter logos

## EMPTY STATE

Large but compact logo.

Title:
Where should we begin?

Subtitle:
Ask anything. Build anything. Create anything.

Suggestion cards:
- Explain something
- Help me code
- Analyze an image
- Analyze a file
- Write something
- Translate something
- Create an image

## COMPOSER V2

The composer is the visual centerpiece.

Shape:
- 18px radius
- 1px monochrome border
- very soft shadow
- minimum 56px height
- expands to 180px maximum before scrolling
- attachment chips above input
- plus button on left
- microphone on right
- send button on right
- stop button replaces send while streaming

Placeholder:
Message Xynova...

Interactions:
- Enter sends
- Shift+Enter newline
- paste image
- drag/drop files where supported
- real camera
- real file picker
- real microphone

Use icons only as neutral monochrome glyphs. Do not put a giant Xynova logo inside every message.

## MESSAGE DESIGN

User:
- visually distinct but not huge
- rounded dark/white bubble depending on theme
- max width 82%

Assistant:
- full-width readable block
- no unnecessary bubble
- max content width 820px
- body 16px
- line-height 1.55–1.7

Actions:
Copy, Regenerate, Read aloud, Like, Dislike.

Code blocks:
- dark monochrome surface in light mode and lighter elevated surface in dark mode
- language badge
- copy button
- horizontal scroll only inside code block
- readable 13–14px monospace

Thinking:
Only display:
Thinking...
with a subtle 3-dot animation.
Never display chain-of-thought.

## PROVIDER ARCHITECTURE

Flutter talks only to a secure Base44 gateway.

Flutter:
Xynova UI
→ Base44 Function
→ SmartRouter
→ Provider Adapter
→ normalized stream
→ Flutter

Adapters:
- XkiroProvider
- GroqProvider
- OpenRouterProvider
- ImageProvider
- TTSProvider

Required secrets live only in Base44:
- XKIRO_API_KEY
- GROQ_API_KEY
- OPENROUTER_API_KEY

Configured xKiro IDs are configuration, not assumptions. Models can be disabled centrally.

## MODEL REGISTRY

Every model:
id, provider, category, speed, reasoning, coding, vision, context, enabled.

Only enabled models appear.

Auto mode routes deterministically using:
- attachment type
- coding/debug keywords
- math/reasoning keywords
- task length
- model capability metadata
- provider availability

Never make an expensive AI call just to classify every message.

Manual model selection is respected unless technically incapable of an attachment/task.

## STREAMING

Backend normalizes all providers to:
{"type":"token","text":"..."}
{"type":"done"}
{"type":"error","message":"..."}

Flutter must:
- show Thinking immediately
- hide Thinking on first token
- append tokens progressively
- preserve scroll position intelligently
- show Stop while active
- abort request
- never duplicate assistant messages

If stream fails after tokens have started:
"The connection was interrupted. Please try again."

Never silently start a second answer after partial output.

## FILES

Support:
PDF TXT DOC DOCX CSV JSON MD HTML CSS JS TS PY JAVA C CPP ZIP
PNG JPG JPEG WEBP

Never execute uploaded files.

Limits:
- 20 MB individual file
- 50 MB total request
- ZIP extraction limits enforced by backend
- reject dangerous binaries

Extract text locally for text/code where safe.
PDF/ZIP/DOC processing belongs in the secure backend.

## CAMERA

Use the real device camera through Flutter's image picker.
Request permission.
Capture.
Preview.
Retake.
Use photo.
Cancel.

No fake camera screen.

## VOICE

Use speech recognition package when platform supports it.
States:
Ready
Listening...
Processing...

If unavailable:
Voice input tidak tersedia di browser/perangkat ini.

## TTS

Use real `SpeechSynthesis`/native TTS.
No fake audio.

If an external TTS provider is configured, route through Base44.
Never assume chat providers provide TTS.

## IMAGE GENERATION

Separate ImageProvider.
Only enable when configured.
Never pretend a chat model generated an image.

## LOCAL HISTORY

Store:
id, title, messages, createdAt, updatedAt, pinned.

Keep history local to the device.
No cross-device sync claims.

Use SharedPreferences for the release starter implementation; if message volume grows, migrate to IndexedDB/SQLite without changing the UI contract.

## SETTINGS

Appearance:
Light / Dark / System

Language:
Auto / Indonesian / English / Japanese / Korean / Chinese / Spanish / French / German / Portuguese / Arabic

Default model:
Xynova Auto + enabled models

Voice:
voice selection, speech rate

Providers:
xKiro, Groq, OpenRouter, Image, TTS
show Connected / Not configured only.

About:
Xynova
Your intelligent AI.
Created by X Shine
© 2026 X Shine
Version 2.0

## ACCESSIBILITY

- semantic labels on icon buttons
- minimum 44px touch targets
- contrast ratio suitable for normal text
- keyboard focus states
- screen-reader-friendly buttons
- no information conveyed by color

## PERFORMANCE

- lazy list rendering
- avoid rebuilding the whole conversation for each token
- debounce search
- cancel requests
- do not health-check providers before every message
- no multi-provider fan-out
- compress/resize camera images before upload where appropriate
- keep UI responsive while streaming

## ERROR MESSAGES

401/403:
AI provider authentication failed.

429:
Provider sedang sibuk. Silakan coba lagi.

408/timeout:
Request terlalu lama. Silakan coba lagi.

404/model:
Model ini sedang tidak tersedia.

All unavailable:
Maaf, Xynova sedang mengalami gangguan. Silakan coba lagi.

## ACCEPTANCE

1. App opens directly to chat.
2. Hello streams.
3. Coding routes to coding-capable model.
4. Image routes to vision-capable model.
5. Text files are safely extracted.
6. Camera is real.
7. Microphone is real when supported.
8. Read aloud is real.
9. Image generation only works when configured.
10. Manual model selection works.
11. Fallback occurs only after a real provider failure.
12. Stop generation works.
13. Refresh keeps local history.
14. Language changes UI/response language.
15. Theme remains strictly monochrome.
16. Security scan finds no client secrets.

## FINAL FEEL

The app must feel:
- fast
- calm
- premium
- readable
- intentional
- modern
- polished
- unmistakably Xynova

The most important visual rule:
**medium-sized readable UI, not tiny text.**

The most important product rule:
**real functionality, no fake behavior.**
