/// Rehbere ve/veya uygulamaya kaydetmek için tek istek (sesli veya manuel).
class ContactSaveRequest {
  const ContactSaveRequest({
    required this.fullName,
    required this.primaryPhone,
    this.email,
    this.note,
  });

  final String fullName;
  final String primaryPhone;
  final String? email;
  final String? note;

  bool get isValid =>
      fullName.trim().isNotEmpty && primaryPhone.trim().isNotEmpty;
}
