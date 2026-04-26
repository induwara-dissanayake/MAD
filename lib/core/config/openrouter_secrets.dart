/// OpenRouter API settings for the in-app AI chat.
/// Remove or replace the key value after your viva if you publish the repo.
const String openRouterApiKey =
    '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';

/// Free inference: `openrouter/free` picks a working free model (avoids 404s when
/// a specific `*:free` slug is removed). Alternatives: `meta-llama/llama-3.2-3b-instruct:free`
const String openRouterModel = 'openrouter/free';
