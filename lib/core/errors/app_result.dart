import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
sealed class AppResult<T> {
  const AppResult();
}

class AppSuccess<T> extends AppResult<T> {
  final T data;
  final String? message;
  const AppSuccess(this.data, {this.message});
}

class AppFailure<T> extends AppResult<T> {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  const AppFailure(this.message, {this.cause, this.stackTrace});

  factory AppFailure.fromException(Object e, [StackTrace? st]) {
    return AppFailure(e.toString(), cause: e, stackTrace: st);
  }
}

class AppLoading<T> extends AppResult<T> {
  final String? stage;
  const AppLoading({this.stage});
}

extension AppResultX<T> on AppResult<T> {
  AsyncValue<T> toAsyncValue() {
    return switch (this) {
      AppSuccess(:final data) => AsyncValue.data(data),
      AppFailure(:final message, :final cause, :final stackTrace) =>
        AsyncValue.error(AppException(message, cause), stackTrace ?? StackTrace.current),
      AppLoading() => AsyncValue.loading(),
    };
  }

  bool get isSuccess => this is AppSuccess<T>;
  bool get isFailure => this is AppFailure<T>;
  bool get isLoading => this is AppLoading<T>;
  T? get dataOrNull => (this is AppSuccess<T>) ? (this as AppSuccess<T>).data : null;
  String? get errorOrNull => (this is AppFailure<T>) ? (this as AppFailure<T>).message : null;
}

class AppException implements Exception {
  final String message;
  final Object? cause;
  const AppException(this.message, [this.cause]);

  @override
  String toString() => 'AppException: $message${cause != null ? ' (cause: $cause)' : ''}';
}
