import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/model_info.dart';
import '../../../shared/widgets/gradient_badge.dart';

class ModelSelectorSheet extends StatefulWidget {
  final List<ModelInfo> models;
  final ModelInfo selectedModel;
  final void Function(ModelInfo) onSelect;

  const ModelSelectorSheet({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onSelect,
  });

  @override
  State<ModelSelectorSheet> createState() => _ModelSelectorSheetState();
}

class _ModelSelectorSheetState extends State<ModelSelectorSheet> {
  final _searchController = TextEditingController();
  late String _selectedProvider;

  @override
  void initState() {
    super.initState();
    // Default to currently selected model's provider, or 'All'
    _selectedProvider = widget.selectedModel.provider.isNotEmpty
        ? widget.selectedModel.provider
        : 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _providersList {
    final set = <String>{};
    for (final m in widget.models) {
      if (m.provider.isNotEmpty) {
        set.add(m.provider);
      }
    }

    final priorityOrder = [
      'Ezbo AI',
      'OpenAI',
      'Anthropic',
      'Google',
      'DeepSeek',
      'Meta',
      'Mistral',
      'xAI',
      'Qwen'
    ];

    final sorted = set.toList()
      ..sort((a, b) {
        final idxA = priorityOrder.indexOf(a);
        final idxB = priorityOrder.indexOf(b);
        if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
        if (idxA != -1) return -1;
        if (idxB != -1) return 1;
        return a.compareTo(b);
      });

    return ['All', ...sorted];
  }

  List<ModelInfo> get _filteredModels {
    final query = _searchController.text.trim().toLowerCase();

    return widget.models.where((m) {
      // 1. Filter by Provider
      if (_selectedProvider != 'All' && m.provider != _selectedProvider) {
        return false;
      }

      // 2. Filter by search query
      if (query.isNotEmpty) {
        final matchesQuery = m.displayName.toLowerCase().contains(query) ||
            m.name.toLowerCase().contains(query) ||
            m.provider.toLowerCase().contains(query) ||
            m.description.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      return true;
    }).toList();
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'ezbo ai':
        return Icons.auto_awesome_rounded;
      case 'openai':
        return Icons.psychology_rounded;
      case 'anthropic':
        return Icons.lightbulb_outline_rounded;
      case 'google':
        return Icons.stream_rounded;
      case 'deepseek':
        return Icons.radar_rounded;
      case 'meta':
        return Icons.language_rounded;
      case 'mistral':
        return Icons.air_rounded;
      default:
        return Icons.hub_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final providers = _providersList;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select AI Model',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose an AI provider to view its models',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search models (Claude, GPT-4o, DeepSeek, Flux...)',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),

          // AI Provider Tabs / Selector
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Text(
              'AI PROVIDERS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: theme.hintColor,
                letterSpacing: 0.8,
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: providers.map((provider) {
                final isSelected = _selectedProvider == provider;
                final count = provider == 'All'
                    ? widget.models.length
                    : widget.models.where((m) => m.provider == provider).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedProvider = provider;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.card : AppColors.cardSecondaryLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : theme.dividerColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (provider != 'All') ...[
                            Icon(
                              _getProviderIcon(provider),
                              size: 15,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            provider,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : theme.dividerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : theme.hintColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // Models List for Selected Provider
          Expanded(
            child: _filteredModels.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: theme.hintColor),
                          const SizedBox(height: 8),
                          Text(
                            'No models found for "$_selectedProvider"',
                            style: TextStyle(fontWeight: FontWeight.w600, color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredModels.length,
                    separatorBuilder: (_, __) => Divider(
                      indent: 20,
                      endIndent: 20,
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final model = _filteredModels[index];
                      final isSelected = model.name == widget.selectedModel.name;

                      return InkWell(
                        onTap: () {
                          widget.onSelect(model);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Provider Logo / Icon
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : (isDark ? AppColors.card : AppColors.cardSecondaryLight),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : theme.dividerColor,
                                  ),
                                ),
                                child: Icon(
                                  _getProviderIcon(model.provider),
                                  size: 20,
                                  color: isSelected ? AppColors.primary : theme.hintColor,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            model.displayName,
                                            style: TextStyle(
                                              color: isSelected ? AppColors.primary : null,
                                              fontSize: 14.5,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (model.badge.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          GradientBadge(text: model.badge),
                                        ],
                                        if (model.supportsImageInput) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.surfaceElevated : AppColors.cardSecondaryLight,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Icon(Icons.remove_red_eye_outlined, size: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      model.description.isNotEmpty
                                          ? model.description
                                          : 'Provider: ${model.provider} · Context: ${model.maxTokens ~/ 1000}k',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Checkmark
                              if (isSelected) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
