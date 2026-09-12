import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

enum ModelModalitiesDensity { compact, regular }

/// Shared input/output modality display for Bot cards, details, and chats.
class ModelModalitiesView extends StatelessWidget {
  const ModelModalitiesView({
    super.key,
    required this.inputModalities,
    required this.outputModalities,
    required this.keyPrefix,
    this.density = ModelModalitiesDensity.regular,
    this.inputDescription,
    this.outputDescription,
  });

  final List<InputModality> inputModalities;
  final List<OutputModality> outputModalities;
  final String keyPrefix;
  final ModelModalitiesDensity density;
  final String? inputDescription;
  final String? outputDescription;

  @override
  Widget build(BuildContext context) {
    final orderedInputModalities = _orderedInputModalities(inputModalities);
    final orderedOutputModalities = _orderedOutputModalities(outputModalities);

    if (density == ModelModalitiesDensity.compact) {
      return Row(
        key: ValueKey<String>(keyPrefix),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _CompactModalityGroup(
              key: ValueKey<String>('$keyPrefix-input'),
              keyPrefix: '$keyPrefix-input',
              icon: Icons.input_rounded,
              label: S.of(context).modelInputModalities,
              valueLabels: [
                for (final modality in orderedInputModalities)
                  _inputModalityLabel(context, modality),
              ],
              valueIcons: ModelInputModalityIcons(
                modalities: orderedInputModalities,
                keyPrefix: '$keyPrefix-input-value',
                iconSize: 14,
                spacing: 6,
              ),
            ),
          ),
          Expanded(
            child: _CompactModalityGroup(
              key: ValueKey<String>('$keyPrefix-output'),
              keyPrefix: '$keyPrefix-output',
              icon: Icons.output_rounded,
              label: S.of(context).modelOutputModalities,
              valueLabels: [
                for (final modality in orderedOutputModalities)
                  _outputModalityLabel(context, modality),
              ],
              valueIcons: ModelOutputModalityIcons(
                modalities: orderedOutputModalities,
                keyPrefix: '$keyPrefix-output-value',
                iconSize: 14,
                spacing: 6,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: ValueKey<String>(keyPrefix),
      children: [
        StarsInspectorInfoRow(
          key: ValueKey<String>('$keyPrefix-input'),
          icon: Icons.input_rounded,
          label: S.of(context).modelInputModalities,
          description: inputDescription,
          crossAxisAlignment: CrossAxisAlignment.center,
          layout: StarsInspectorInfoRowLayout.settings,
          trailing: ModelInputModalityIcons(
            keyPrefix: '$keyPrefix-input',
            modalities: orderedInputModalities,
          ),
        ),
        const ShadSeparator.horizontal(
          margin: StarsDesktopThemeSpec.settingsRowSeparatorMargin,
        ),
        StarsInspectorInfoRow(
          key: ValueKey<String>('$keyPrefix-output'),
          icon: Icons.output_rounded,
          label: S.of(context).modelOutputModalities,
          description: outputDescription,
          crossAxisAlignment: CrossAxisAlignment.center,
          layout: StarsInspectorInfoRowLayout.settings,
          trailing: ModelOutputModalityIcons(
            keyPrefix: '$keyPrefix-output',
            modalities: orderedOutputModalities,
          ),
        ),
      ],
    );
  }
}

class _CompactModalityGroup extends StatelessWidget {
  const _CompactModalityGroup({
    super.key,
    required this.keyPrefix,
    required this.icon,
    required this.label,
    required this.valueLabels,
    required this.valueIcons,
  });

  final String keyPrefix;
  final IconData icon;
  final String label;
  final List<String> valueLabels;
  final Widget valueIcons;

  @override
  Widget build(BuildContext context) {
    final value =
        valueLabels.isEmpty
            ? S.of(context).statusUnknown
            : valueLabels.join(', ');
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: label,
            child: Icon(
              icon,
              size: 14,
              color: StarsDesktopThemeSpec.mutedText(context),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            key: ValueKey<String>('$keyPrefix-separator'),
            width: 1,
            height: 14,
            color: StarsDesktopThemeSpec.divider(context),
          ),
          const SizedBox(width: 6),
          Flexible(child: valueIcons),
        ],
      ),
    );
  }
}

class ModelInputModalityIcons extends StatelessWidget {
  const ModelInputModalityIcons({
    super.key,
    required this.modalities,
    required this.keyPrefix,
    this.alignment = WrapAlignment.end,
    this.iconSize = 16,
    this.spacing = 8,
  });

  final List<InputModality> modalities;
  final String keyPrefix;
  final WrapAlignment alignment;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return _ModalityIcons(
      keyPrefix: keyPrefix,
      alignment: alignment,
      iconSize: iconSize,
      spacing: spacing,
      items: [
        for (final modality in _orderedInputModalities(modalities))
          _ModalityIconItem(
            id: modality.value,
            label: _inputModalityLabel(context, modality),
            icon: _inputModalityIcon(modality),
          ),
      ],
    );
  }
}

class ModelOutputModalityIcons extends StatelessWidget {
  const ModelOutputModalityIcons({
    super.key,
    required this.modalities,
    required this.keyPrefix,
    this.alignment = WrapAlignment.end,
    this.iconSize = 16,
    this.spacing = 8,
  });

  final List<OutputModality> modalities;
  final String keyPrefix;
  final WrapAlignment alignment;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return _ModalityIcons(
      keyPrefix: keyPrefix,
      alignment: alignment,
      iconSize: iconSize,
      spacing: spacing,
      items: [
        for (final modality in _orderedOutputModalities(modalities))
          _ModalityIconItem(
            id: modality.value,
            label: _outputModalityLabel(context, modality),
            icon: _outputModalityIcon(modality),
          ),
      ],
    );
  }
}

class _ModalityIcons extends StatelessWidget {
  const _ModalityIcons({
    required this.items,
    required this.keyPrefix,
    required this.alignment,
    required this.iconSize,
    required this.spacing,
  });

  final List<_ModalityIconItem> items;
  final String keyPrefix;
  final WrapAlignment alignment;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final effectiveItems =
        items.isEmpty
            ? [
              _ModalityIconItem(
                id: 'unknown',
                label: S.of(context).statusUnknown,
                icon: Icons.help_outline_rounded,
              ),
            ]
            : items;
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final item in effectiveItems)
          Tooltip(
            key: ValueKey<String>('$keyPrefix-${item.id}'),
            message: item.label,
            child: Semantics(
              label: item.label,
              child: Icon(
                item.icon,
                size: iconSize,
                color: StarsDesktopThemeSpec.mutedText(context),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModalityIconItem {
  const _ModalityIconItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

List<InputModality> _orderedInputModalities(List<InputModality> modalities) {
  final values = modalities.toSet();
  return [
    for (final modality in InputModality.values)
      if (values.contains(modality)) modality,
  ];
}

List<OutputModality> _orderedOutputModalities(List<OutputModality> modalities) {
  final values = modalities.toSet();
  return [
    for (final modality in OutputModality.values)
      if (values.contains(modality)) modality,
  ];
}

String _inputModalityLabel(BuildContext context, InputModality modality) =>
    switch (modality) {
      InputModality.text => S.of(context).modalityText,
      InputModality.image => S.of(context).modalityImage,
      InputModality.file => S.of(context).modalityFile,
      InputModality.audio => S.of(context).modalityAudio,
      InputModality.video => S.of(context).modalityVideo,
      InputModality.realtime => S.of(context).modalityRealtime,
    };

String _outputModalityLabel(BuildContext context, OutputModality modality) =>
    switch (modality) {
      OutputModality.text => S.of(context).modalityText,
      OutputModality.image => S.of(context).modalityImage,
      OutputModality.speech => S.of(context).modalitySpeech,
      OutputModality.audio => S.of(context).modalityAudio,
      OutputModality.realtime => S.of(context).modalityRealtime,
      OutputModality.music => S.of(context).modalityMusic,
      OutputModality.video => S.of(context).modalityVideo,
      OutputModality.multi => S.of(context).modalityMulti,
    };

IconData _inputModalityIcon(InputModality modality) => switch (modality) {
  InputModality.text => Icons.text_fields_rounded,
  InputModality.image => Icons.image_outlined,
  InputModality.file => Icons.attach_file_rounded,
  InputModality.audio => Icons.audio_file_outlined,
  InputModality.video => Icons.video_file_outlined,
  InputModality.realtime => Icons.bolt_rounded,
};

IconData _outputModalityIcon(OutputModality modality) => switch (modality) {
  OutputModality.text => Icons.text_fields_rounded,
  OutputModality.image => Icons.image_outlined,
  OutputModality.speech => Icons.record_voice_over_outlined,
  OutputModality.audio => Icons.audio_file_outlined,
  OutputModality.realtime => Icons.bolt_rounded,
  OutputModality.music => Icons.music_note_rounded,
  OutputModality.video => Icons.video_file_outlined,
  OutputModality.multi => Icons.grid_view_rounded,
};
