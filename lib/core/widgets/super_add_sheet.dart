import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/widgets/super_add_sheet_models.dart';
import 'package:beltech/core/widgets/super_add_sheet_sections.dart';
import 'package:flutter/material.dart';

export 'package:beltech/core/widgets/super_add_sheet_models.dart';

Future<SuperEntryInput?> showSuperAddSheet(
  BuildContext context, {
  SuperEntryKind defaultKind = SuperEntryKind.task,
  DateTime? contextDate,
  SuperEntryInput? initialInput,
  String actionLabel = 'Create',
  bool lockKind = false,
}) {
  final titleController = TextEditingController(
    text: initialInput?.title ?? '',
  );
  final descriptionController = TextEditingController(
    text: initialInput?.description ?? '',
  );
  final selectedBaseDate = contextDate ?? DateTime.now();
  var kind = initialInput?.kind ?? defaultKind;
  var priority = initialInput?.priority ?? SuperEntryPriority.medium;
  var eventType = initialInput?.eventType ?? SuperEntryEventType.general;
  var reminderEnabled = initialInput?.reminderEnabled ?? true;
  var reminderMinutesBefore =
      initialInput?.reminderMinutesBefore ??
      (kind == SuperEntryKind.event ? 15 : 30);
  DateTime? dueAt = initialInput?.dueAt ??
      DateTime(
        selectedBaseDate.year,
        selectedBaseDate.month,
        selectedBaseDate.day,
        17,
        0,
      );
  var startAt =
      initialInput?.startAt ??
      DateTime(
        selectedBaseDate.year,
        selectedBaseDate.month,
        selectedBaseDate.day,
        14,
        0,
      );
  DateTime? endAt =
      initialInput?.endAt ?? startAt.add(const Duration(hours: 1));
  var titleError = false;
  String? timeError;
  var showDetails = initialInput != null;
  return showModalBottomSheet<SuperEntryInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final brightness = Theme.of(context).brightness;
        final textPrimary = AppColors.textPrimaryFor(brightness);
        final textSecondary = AppColors.textSecondaryFor(brightness);
        final choiceDuration = AppMotion.content(context);
        final isEvent = kind == SuperEntryKind.event;
        final canSave =
            titleController.text.trim().isNotEmpty &&
            (!isEvent || (endAt == null || !endAt!.isBefore(startAt)));

        return AppFormSheet(
          title: actionLabel == 'Create'
              ? (isEvent ? 'New Planner Event' : 'New Planner Task')
              : (isEvent ? 'Edit Planner Event' : 'Edit Planner Task'),
          subtitle:
              'One super section for capturing both tasks and calendar events.',
          onClose: () => Navigator.of(context).pop(),
          footer: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: actionLabel,
                  onPressed: !canSave
                      ? null
                      : () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            setState(() => titleError = true);
                            return;
                          }
                          if (isEvent &&
                              endAt != null &&
                              endAt!.isBefore(startAt)) {
                            setState(() {
                              timeError =
                                  'End time must be after the event start.';
                            });
                            return;
                          }
                          Navigator.of(context).pop(
                            SuperEntryInput(
                              kind: kind,
                              title: title,
                              description:
                                  descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              priority: priority,
                              dueAt: isEvent ? null : dueAt,
                              startAt: isEvent ? startAt : null,
                              endAt: isEvent ? endAt : null,
                              eventType: isEvent ? eventType : null,
                              reminderEnabled: reminderEnabled,
                              reminderMinutesBefore: reminderMinutesBefore,
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: SuperEntryKind.values.map((item) {
                  final selected = item == kind;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: item == SuperEntryKind.task ? 6 : 0,
                        left: item == SuperEntryKind.event ? 6 : 0,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: lockKind
                            ? null
                            : () => setState(() {
                                kind = item;
                                timeError = null;
                              }),
                        child: AnimatedContainer(
                          duration: choiceDuration,
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent
                                : AppColors.surfaceMutedFor(brightness),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.borderFor(brightness),
                            ),
                          ),
                          child: Text(
                            item == SuperEntryKind.task ? 'Task' : 'Event',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                onChanged: (_) => setState(() => titleError = false),
                decoration: InputDecoration(
                  hintText: 'Title',
                  errorText: titleError ? 'Title is required' : null,
                ),
              ),
              const SizedBox(height: 12),
              SuperAddWhenPickerRow(
                label: isEvent ? 'Starts' : 'Deadline',
                value: isEvent ? startAt : dueAt,
                allowClear: !isEvent,
                onPick: (picked) => setState(() {
                  if (isEvent) {
                    startAt = picked;
                    if (endAt != null && endAt!.isBefore(startAt)) {
                      endAt = startAt.add(const Duration(hours: 1));
                    }
                  } else {
                    dueAt = picked;
                  }
                  timeError = null;
                }),
                onClear: () => setState(() => dueAt = null),
              ),
              if (isEvent) ...[
                const SizedBox(height: 10),
                SuperAddWhenPickerRow(
                  label: 'Ends (optional)',
                  value: endAt,
                  allowClear: true,
                  onPick: (picked) => setState(() {
                    endAt = picked;
                    timeError = null;
                  }),
                  onClear: () => setState(() => endAt = null),
                ),
              ],
              if (timeError != null) ...[
                const SizedBox(height: 8),
                Text(
                  timeError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => showDetails = !showDetails),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedFor(brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          showDetails ? 'Hide details' : 'More details',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        showDetails
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (showDetails) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                SuperAddPrioritySelector(
                  selected: priority,
                  textPrimary: textPrimary,
                  duration: choiceDuration,
                  onChanged: (value) => setState(() => priority = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reminder',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: reminderEnabled,
                      onChanged: (value) =>
                          setState(() => reminderEnabled = value),
                    ),
                  ],
                ),
                if (reminderEnabled) ...[
                  const SizedBox(height: 8),
                  SuperAddReminderMinutesSelector(
                    selectedMinutes: reminderMinutesBefore,
                    duration: choiceDuration,
                    onChanged: (value) =>
                        setState(() => reminderMinutesBefore = value),
                  ),
                ],
                if (isEvent) ...[
                  const SizedBox(height: 12),
                  SuperAddEventTypeSelector(
                    selected: eventType,
                    duration: choiceDuration,
                    onChanged: (value) => setState(() => eventType = value),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    ),
  );
}
