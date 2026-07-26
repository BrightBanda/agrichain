import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// One line in the verification sequence.
class VerificationStep {
  final String label;

  /// How long this step appears to take.
  final Duration duration;

  /// False when nothing is actually contacted — a demonstration of the check a
  /// production system would run. Shown with a "simulated" tag so the screen
  /// never claims a lookup happened that did not.
  final bool isReal;

  const VerificationStep(this.label, {required this.duration, this.isReal = false});
}

/// A modal that walks through registration checks while the real request runs.
///
/// The dialog does not gate the request: [work] starts immediately and the steps
/// animate alongside it. The dialog closes when both finish, so a slow backend
/// simply means the last step lingers rather than the user seeing a frozen
/// screen. Returns the result of [work], or null if it failed.
class VerificationProgressSheet<T> extends StatefulWidget {
  final List<VerificationStep> steps;
  final Future<T> Function() work;
  final String title;

  const VerificationProgressSheet({
    super.key,
    required this.steps,
    required this.work,
    this.title = 'Verifying your details',
  });

  /// Shows the sheet and resolves once the work and the animation are both done.
  static Future<T?> show<T>({
    required BuildContext context,
    required List<VerificationStep> steps,
    required Future<T> Function() work,
    String title = 'Verifying your details',
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VerificationProgressSheet<T>(
        steps: steps,
        work: work,
        title: title,
      ),
    );
  }

  @override
  State<VerificationProgressSheet<T>> createState() =>
      _VerificationProgressSheetState<T>();
}

class _VerificationProgressSheetState<T>
    extends State<VerificationProgressSheet<T>> {
  int _current = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // Start the real request first so the animation overlaps it rather than
    // delaying it.
    final pending = widget.work();
    // Errors are captured here so an early failure cannot become an unhandled
    // exception while the steps are still animating.
    Object? failure;
    final guarded = pending.then<T?>((value) => value).catchError((Object e) {
      failure = e;
      return null;
    });

    for (var i = 0; i < widget.steps.length; i++) {
      if (!mounted) return;
      setState(() => _current = i);
      await Future<void>.delayed(widget.steps[i].duration);
      if (failure != null) break;
    }

    final result = await guarded;
    if (!mounted) return;

    if (failure != null) {
      setState(() => _error = failure);
      // Leave the failure visible briefly so it does not flash past.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    setState(() => _current = widget.steps.length);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final failed = _error != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  failed ? Icons.error_outline : Icons.verified_user_outlined,
                  size: 20,
                  color: failed ? AppColors.danger : AppColors.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    failed ? 'Could not complete' : widget.title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: failed ? AppColors.danger : AppColors.textHeading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            for (var i = 0; i < widget.steps.length; i++)
              _StepRow(
                step: widget.steps[i],
                state: failed && i == _current
                    ? _StepState.failed
                    : i < _current
                          ? _StepState.done
                          : i == _current
                                ? _StepState.active
                                : _StepState.waiting,
              ),

            if (failed) ...[
              const SizedBox(height: 10),
              Text(
                '$_error',
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _StepState { waiting, active, done, failed }

class _StepRow extends StatelessWidget {
  final VerificationStep step;
  final _StepState state;

  const _StepRow({required this.step, required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, colour) = switch (state) {
      _StepState.done => (Icons.check_circle, AppColors.primary),
      _StepState.failed => (Icons.cancel, AppColors.danger),
      _StepState.active => (null, AppColors.primary),
      _StepState.waiting => (Icons.circle_outlined, AppColors.cardBorder),
    };

    return Padding
      (padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: icon == null
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  )
                : Icon(icon, size: 17, color: colour),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: state == _StepState.active
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: state == _StepState.waiting
                        ? AppColors.textMuted
                        : Colors.black87,
                  ),
                ),
                if (!step.isReal) ...[
                  const SizedBox(height: 2),
                  Text(
                    'simulated check',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
