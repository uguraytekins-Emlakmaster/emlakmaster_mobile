import 'package:equatable/equatable.dart';

/// Kullanıcıya gösterilen yumuşak hata özeti (teknik döküm yok).
class PlatformErrorUi extends Equatable {
  const PlatformErrorUi({
    required this.shortMessage,
    this.hint,
  });

  final String shortMessage;
  final String? hint;

  @override
  List<Object?> get props => [shortMessage, hint];
}
