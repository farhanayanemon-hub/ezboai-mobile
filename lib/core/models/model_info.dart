class ModelInfo {
  final String name;
  final String displayName;
  final String provider;
  final int maxTokens;
  final bool supportsStreaming;
  final bool supportsImageInput;
  final bool isLocked;
  final String badge;
  final String description;

  const ModelInfo({
    required this.name,
    required this.displayName,
    required this.provider,
    this.maxTokens = 4096,
    this.supportsStreaming = true,
    this.supportsImageInput = false,
    this.isLocked = false,
    this.badge = '',
    this.description = '',
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? '';
    final rawDisplayName = json['displayName'] as String? ?? rawName;
    final rawProvider = (json['provider'] as String? ?? '').trim();

    String resolvedProvider = 'Other';
    final lowerName = rawName.toLowerCase();
    final lowerProv = rawProvider.toLowerCase();

    if (lowerName.startsWith('ezbo/') || lowerProv == 'ezbo' || lowerProv == 'ezboai' || lowerProv == 'ezbo ai') {
      resolvedProvider = 'Ezbo AI';
    } else if (lowerName.startsWith('openai/') || lowerProv.contains('openai')) {
      resolvedProvider = 'OpenAI';
    } else if (lowerName.startsWith('anthropic/') || lowerProv.contains('anthropic')) {
      resolvedProvider = 'Anthropic';
    } else if (lowerName.startsWith('google/') || lowerProv.contains('google')) {
      resolvedProvider = 'Google';
    } else if (lowerName.startsWith('deepseek/') || lowerProv.contains('deepseek')) {
      resolvedProvider = 'DeepSeek';
    } else if (lowerName.startsWith('meta-llama/') || lowerName.startsWith('meta/') || lowerProv.contains('meta')) {
      resolvedProvider = 'Meta';
    } else if (lowerName.startsWith('mistralai/') || lowerName.startsWith('mistral/') || lowerProv.contains('mistral')) {
      resolvedProvider = 'Mistral';
    } else if (lowerName.startsWith('x-ai/') || lowerProv.contains('x-ai') || lowerName.contains('grok')) {
      resolvedProvider = 'xAI';
    } else if (lowerName.startsWith('qwen/') || lowerProv.contains('qwen')) {
      resolvedProvider = 'Qwen';
    } else if (rawProvider.isNotEmpty && rawProvider != 'OpenRouter') {
      resolvedProvider = rawProvider;
    } else if (rawName.contains('/')) {
      final prefix = rawName.split('/').first;
      resolvedProvider = prefix.substring(0, 1).toUpperCase() + prefix.substring(1);
    }

    String badge = '';
    if (lowerName.contains('ultra') || lowerName.contains('opus') || lowerName.contains('r1')) {
      badge = 'Ultra';
    } else if (lowerName.contains('pro') || lowerName.contains('sonnet') || lowerName.contains('gpt-4o')) {
      badge = 'Pro';
    } else if (lowerName.contains('flash') || lowerName.contains('haiku') || lowerName.contains('mini')) {
      badge = 'Fast';
    }

    return ModelInfo(
      name: rawName,
      displayName: rawDisplayName,
      provider: resolvedProvider,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 4096,
      supportsStreaming: json['supportsStreaming'] as bool? ?? true,
      supportsImageInput: json['supportsImageInput'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      badge: badge,
      description: json['description'] as String? ?? '',
    );
  }

  // Predefined default models for offline or fast startup
  static List<ModelInfo> get defaultChatModels => const [
    ModelInfo(
      name: 'ezbo/ezbo-1.0-pro',
      displayName: 'Ezbo Pro 1.0',
      provider: 'Ezbo AI',
      supportsImageInput: true,
      badge: 'Pro',
      description: 'Ezbo official flagship model optimized for complex intelligence and creative output.',
    ),
    ModelInfo(
      name: 'google/gemini-2.0-flash-exp:free',
      displayName: 'Ezbo Flash 2.0',
      provider: 'Google',
      supportsImageInput: true,
      badge: 'Fast',
      description: 'Super-fast, multimodal AI for quick tasks and coding.',
    ),
    ModelInfo(
      name: 'anthropic/claude-3.5-sonnet',
      displayName: 'Claude 3.5 Sonnet',
      provider: 'Anthropic',
      supportsImageInput: true,
      badge: 'Pro',
      description: 'Industry benchmark for nuanced reasoning and programming.',
    ),
    ModelInfo(
      name: 'openai/gpt-4o',
      displayName: 'OpenAI GPT-4o',
      provider: 'OpenAI',
      supportsImageInput: true,
      badge: 'Pro',
      description: 'Flagship omni-model for vision, reasoning, and analysis.',
    ),
    ModelInfo(
      name: 'deepseek/deepseek-r1',
      displayName: 'DeepSeek R1',
      provider: 'DeepSeek',
      supportsImageInput: false,
      badge: 'Ultra',
      description: 'Breakthrough reasoning model for complex math and logic.',
    ),
    ModelInfo(
      name: 'meta-llama/llama-3.3-70b-instruct',
      displayName: 'Meta Llama 3.3 70B',
      provider: 'Meta',
      supportsImageInput: false,
      badge: 'Ultra',
      description: 'Powerful open-weights model fine-tuned for high accuracy.',
    ),
  ];
}
