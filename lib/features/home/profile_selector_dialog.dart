import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/audio/audio_service.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/parental_gate_dialog.dart';

/// Child-friendly profile switcher & classroom selector with optional 2-emoji child lock.
class ProfileSelectorSheet extends ConsumerStatefulWidget {
  final BuildContext hostContext;

  const ProfileSelectorSheet({super.key, required this.hostContext});

  static const List<String> emojiPinChoices = [
    '🍎',
    '🚗',
    '🌞',
    '⚽',
    '🌈',
    '🚀',
    '🍦',
    '🎈',
  ];

  static Color parseProfileColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$clean', radix: 16) ?? 0xFF1E88E5;
    return Color(value);
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ProfileSelectorSheet(hostContext: context),
    );
  }

  @override
  ConsumerState<ProfileSelectorSheet> createState() =>
      _ProfileSelectorSheetState();
}

class _ProfileSelectorSheetState extends ConsumerState<ProfileSelectorSheet> {
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final loc = AppLocalizations.of(progress.settings.appLanguage);
    final groups = progress.availableGroups;
    final visibleProfiles = _selectedGroup == null
        ? progress.profiles
        : progress.profiles
            .where((p) => p.groupName.trim() == _selectedGroup)
            .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.tr('who_is_learning'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.tr('switch_or_add_profile'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Alle'),
                      selected: _selectedGroup == null,
                      onSelected: (_) => setState(() => _selectedGroup = null),
                    ),
                    for (final g in groups) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('🏫 $g'),
                        selected: _selectedGroup == g,
                        onSelected: (_) => setState(() => _selectedGroup = g),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: visibleProfiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final prof = visibleProfiles[idx];
                  final active = prof.id == progress.activeProfileId;
                  final accent =
                      ProfileSelectorSheet.parseProfileColor(prof.themeColorHex);
                  final bridge =
                      prof.profileBridgeLanguage ?? progress.settings.bridgeLanguage;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _onSelectProfile(context, prof, active, loc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? accent.withValues(alpha: 0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active ? accent : const Color(0xFFE5E7EB),
                          width: active ? 2.5 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              prof.avatarEmoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        prof.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (prof.hasEmojiPin) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        '🔑',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                    if (bridge.isEnabled) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        bridge.flagEmoji,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${prof.totalStars} ⭐ • ${prof.streakDays} 🔥 • 🎯 ${prof.dailyCompletedCount}/${prof.dailyGoalTarget}'
                                  '${prof.groupName.trim().isNotEmpty ? ' • ${prof.groupName}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.successGreen,
                              size: 28,
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: accent,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final allowed =
                    await ParentalGateDialog.show(widget.hostContext);
                if (allowed && widget.hostContext.mounted) {
                  widget.hostContext.push('/parents');
                }
              },
              icon: const Icon(Icons.lock_outline_rounded),
              label: Text(loc.tr('parent_area')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSelectProfile(
    BuildContext sheetContext,
    ChildProfile prof,
    bool isAlreadyActive,
    AppLocalizations loc,
  ) async {
    if (!isAlreadyActive && prof.hasEmojiPin) {
      final unlocked = await _showEmojiPinChallenge(sheetContext, prof, loc);
      if (!unlocked) return;
    }

    await ref.read(progressProvider.notifier).switchProfile(prof.id);
    await ref
        .read(audioServiceProvider)
        .speakWord(loc.profileSwitchedGreeting(prof.name));
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
  }

  Future<bool> _showEmojiPinChallenge(
    BuildContext context,
    ChildProfile profile,
    AppLocalizations loc,
  ) async {
    final chosen = <String>[];
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Text(
                    profile.avatarEmoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.tr('enter_emoji_pin'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      chosen.isEmpty ? '❓  ❓' : chosen.join('  '),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMsg!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.syllableRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: ProfileSelectorSheet.emojiPinChoices.map((emoji) {
                      return ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            errorMsg = null;
                            chosen.add(emoji);
                          });
                          final runes = chosen.join();
                          if (chosen.length >= 2) {
                            final ok = ref
                                .read(progressProvider.notifier)
                                .verifyEmojiPin(profile.id, runes);
                            if (ok) {
                              Navigator.of(ctx).pop(true);
                            } else {
                              setDialogState(() {
                                chosen.clear();
                                errorMsg = loc.tr('wrong_emoji_pin');
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(64, 58),
                          side: const BorderSide(
                            color: AppColors.syllableBlue,
                            width: 2,
                          ),
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 28)),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Abbrechen'),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }
}
