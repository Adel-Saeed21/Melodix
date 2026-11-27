import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/l10n/l10n.dart';

/// A message to show after a user action (see `ActionFeedbackListener`).
class ActionFeedback extends Equatable {
  const ActionFeedback(this.message, this.sequence, {this.isError = false});

  /// Put into words when shown, in the language in use then.
  final LocalizedText message;
  final bool isError;

  /// Makes repeated identical messages distinct so each one is shown.
  final int sequence;

  @override
  List<Object?> get props => [message, isError, sequence];
}

/// Reporting [ActionFeedback] from a cubit: numbering the messages and
/// turning a use case's result into a success or failure message.
mixin ActionFeedbackReporter<S> on BlocBase<S> {
  int _feedbackSequence = 0;

  /// [state] with [feedback] as its latest message.
  S withFeedback(ActionFeedback feedback);

  /// Shows [message] (ignored once the cubit is closed).
  void report(LocalizedText message, {bool isError = false}) {
    if (isClosed) return;
    emit(
      withFeedback(
        ActionFeedback(message, ++_feedbackSequence, isError: isError),
      ),
    );
  }

  /// Reports the failure's message, or [onSuccess]'s message (none if it
  /// returns null). Returns whether the action succeeded.
  bool reportResult<T>(
    Either<Failure, T> result,
    LocalizedText? Function(T value) onSuccess,
  ) => result.fold(
    (failure) {
      report((l) => l.failure(failure.message), isError: true);
      return false;
    },
    (value) {
      final message = onSuccess(value);
      if (message != null) report(message);
      return true;
    },
  );
}
