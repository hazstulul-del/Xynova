/**
 * Xynova v2 Base44 backend reference.
 *
 * Put provider secrets in Base44 Secrets:
 * XKIRO_API_KEY
 * GROQ_API_KEY
 * OPENROUTER_API_KEY
 *
 * This function should receive:
 * { message, conversation, selectedModel, attachments, language }
 *
 * Response: SSE / NDJSON:
 * data: {"type":"token","text":"..."}
 * data: {"type":"done"}
 *
 * SECURITY:
 * - Never return provider keys.
 * - Never log request headers containing secrets.
 * - Never execute uploaded files.
 * - Enforce attachment limits.
 * - Never expose hidden system prompts.
 */

type ChatRequest = {
  message: string;
  conversation: unknown[];
  selectedModel: string;
  attachments: unknown[];
  language: string;
};

type StreamEvent =
  | { type: "token"; text: string }
  | { type: "done" }
  | { type: "error"; message: string };

const XKIRO_URL = "https://api.xkiro.com/v1/chat/completions";
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

function friendlyStatus(status: number): string {
  if (status === 401 || status === 403) return "AI provider authentication failed.";
  if (status === 404) return "Model ini sedang tidak tersedia.";
  if (status === 408) return "Request terlalu lama. Silakan coba lagi.";
  if (status === 429) return "Provider sedang sibuk. Silakan coba lagi.";
  if (status >= 500) return "Maaf, Xynova sedang mengalami gangguan. Silakan coba lagi.";
  return "Request gagal. Silakan coba lagi.";
}

/**
 * Provider adapters should live in separate modules in the actual Base44 project.
 * Keep this file as an implementation contract rather than pretending it is
 * already deployed, because Base44 function runtime/config differs by project.
 */
export async function routeAndStream(
  req: ChatRequest,
  env: Record<string, string | undefined>,
  send: (event: StreamEvent) => void,
) {
  const providers = [
    { name: "xkiro", key: env.XKIRO_API_KEY, url: XKIRO_URL },
    { name: "openrouter", key: env.OPENROUTER_API_KEY, url: OPENROUTER_URL },
  ];

  if (!providers.some((p) => !!p.key)) {
    send({ type: "error", message: "Backend AI belum dikonfigurasi." });
    return;
  }

  // Implement SmartRouter/model registry here in the Base44 project.
  // Do not call all providers simultaneously.
  // Start fallback only on a real pre-stream provider failure.
  //
  // For each provider:
  // 1. build OpenAI-compatible request
  // 2. stream provider SSE
  // 3. normalize delta text to StreamEvent token
  // 4. send done when provider completes
  // 5. if failure happens before first token, try compatible fallback
  //
  // If tokens were already emitted and the stream breaks, send:
  // "The connection was interrupted. Please try again."
}
