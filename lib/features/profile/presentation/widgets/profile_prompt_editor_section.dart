import 'package:flutter/material.dart';

import 'package:christian_dating_app/onboarding/onboarding_prompt_catalog.dart';
import 'package:christian_dating_app/widgets/onboarding_prompt_answer_screen.dart';

/// One editable profile prompt (question + answer).
class ProfilePromptSlot {
  ProfilePromptSlot({this.question, this.answer = ''});

  String? question;
  String answer;

  bool get isFilled => question != null && answer.trim().isNotEmpty;
}

/// Firestore-ready prompts from [slots] (skips empty slots).
List<Map<String, String>> profilePromptsForFirestore(
  List<ProfilePromptSlot> slots, {
  bool placeholderIfEmpty = false,
}) {
  final out = <Map<String, String>>[];
  for (final slot in slots) {
    if (slot.question == null || slot.answer.trim().isEmpty) continue;
    out.add({
      'question': slot.question!,
      'answer': slot.answer.trim(),
    });
  }
  if (out.isEmpty && placeholderIfEmpty) {
    out.add({
      'question': kDefaultOnboardingPrompt,
      'answer': '',
    });
  }
  return out;
}

/// Load up to [slotCount] prompts from Firestore into [slots] (list is cleared first).
void loadProfilePromptSlots(
  List<ProfilePromptSlot> slots, {
  required dynamic promptsRaw,
  int slotCount = ProfilePromptEditorSection.slotCount,
}) {
  slots
    ..clear()
    ..addAll(List.generate(slotCount, (_) => ProfilePromptSlot()));

  if (promptsRaw is! List) return;

  for (var i = 0; i < slotCount && i < promptsRaw.length; i++) {
    final p = promptsRaw[i];
    if (p is! Map) continue;
    final q = p['question']?.toString().trim() ?? '';
    final a = p['answer']?.toString() ?? '';
    slots[i].question = q.isEmpty ? null : q;
    slots[i].answer = a;
  }
}

/// Prompt cards + picker sheet + answer screen (onboarding / edit profile).
class ProfilePromptEditorSection extends StatelessWidget {
  const ProfilePromptEditorSection({
    super.key,
    required this.slots,
    required this.onChanged,
    this.showTip = false,
  });

  final List<ProfilePromptSlot> slots;
  final VoidCallback onChanged;
  final bool showTip;

  static const int slotCount = 2;

  /// Picker only when the slot has no question yet; filled slots edit in place.
  static bool showsPromptPickerForSlot(ProfilePromptSlot slot) =>
      !slot.isFilled && slot.question == null;

  static Future<String?> pickPromptQuestion(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Choose a prompt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...kOnboardingPromptQuestions.map(
                  (q) => ListTile(
                    title: Text(q),
                    onTap: () => Navigator.pop(ctx, q),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> openPromptSlot(
    BuildContext context, {
    required List<ProfilePromptSlot> slots,
    required int index,
    required VoidCallback onChanged,
  }) async {
    final slot = slots[index];
    late final String question;

    if (showsPromptPickerForSlot(slot)) {
      final picked = await pickPromptQuestion(context);
      if (picked == null || !context.mounted) return;
      question = picked;
    } else {
      question = slot.question!;
    }

    final result = await OnboardingPromptAnswerScreen.push(
      context,
      question: question,
      initialAnswer: slot.answer,
      showRemove: true,
    );
    if (!context.mounted) return;

    if (result.wasRemoved) {
      slot.question = null;
      slot.answer = '';
      onChanged();
      return;
    }

    if (result.answer == null) return;

    slot.question = question;
    slot.answer = result.answer!;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slots.length; i++) _PromptCard(
          index: i,
          slot: slots[i],
          onTap: () => openPromptSlot(
            context,
            slots: slots,
            index: i,
            onChanged: onChanged,
          ),
        ),
        if (showTip) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A second prompt can help people know what to message you about.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.index,
    required this.slot,
    required this.onTap,
  });

  final int index;
  final ProfilePromptSlot slot;
  final VoidCallback onTap;

  static const _labels = ['First prompt', 'Second prompt'];

  @override
  Widget build(BuildContext context) {
    if (slot.isFilled) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.question!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slot.answer,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _labels[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
