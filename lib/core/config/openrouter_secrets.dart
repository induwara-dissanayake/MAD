/// OpenRouter API settings for the in-app AI chat.
/// Remove or replace the key value after your viva if you publish the repo.
const String openRouterApiKey =
    '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';

/// Free inference: `openrouter/free` picks a working free model (avoids 404s when
/// a specific `*:free` slug is removed). Alternatives: `meta-llama/llama-3.2-3b-instruct:free`
const String openRouterModel = 'openrouter/free';
