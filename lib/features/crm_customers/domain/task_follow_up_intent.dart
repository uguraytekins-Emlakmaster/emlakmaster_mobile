/// Görev kayıtlarından takip niyetini sınıflandırma — kural tabanlı, açıklanabilir.
/// v1: yalnızca dokümantasyon ve ileride alan eşlemesi için; CRM geri bildirimi `lastInteractionAt` ile yapılır.
library task_follow_up_intent;

/// Akıllı görev / hatırlatıcı / manuel başlık için yüksek seviye niyet.
enum TaskFollowUpIntent {
  followUpCall,
  appointmentConfirmation,
  pricingFollowUp,
  generalReminder,
}

/// Firestore görev map’inden (ör. `tasks_page` satırı) niyet çıkarır.
/// Öncelik: `smartSuggestionCode` → `executionReminderCode` → başlık anahtar kelimeleri.
TaskFollowUpIntent classifyTaskFollowUpIntent(Map<String, dynamic> taskData) {
  final smart = taskData['smartSuggestionCode'] as String?;
  if (smart != null && smart.isNotEmpty) {
    switch (smart) {
      case 'urgent_follow_up_call':
      case 'immediate_call':
        return TaskFollowUpIntent.followUpCall;
      case 'appointment_confirmation':
        return TaskFollowUpIntent.appointmentConfirmation;
      case 'pricing_follow_up':
        return TaskFollowUpIntent.pricingFollowUp;
      case 'high_value_touchpoint':
        return TaskFollowUpIntent.generalReminder;
    }
  }

  final exec = taskData['executionReminderCode'] as String?;
  if (exec != null && exec.isNotEmpty) {
    switch (exec) {
      case 'overdue_urgent_follow_up':
      case 'due_today_follow_up':
        return TaskFollowUpIntent.followUpCall;
      case 'appointment_confirmation_reminder':
        return TaskFollowUpIntent.appointmentConfirmation;
      case 'price_negotiation_reminder':
        return TaskFollowUpIntent.pricingFollowUp;
      case 'manager_escalation_reminder':
        return TaskFollowUpIntent.generalReminder;
    }
  }

  final title = (taskData['title'] as String? ?? '').toLowerCase();
  if (title.contains('randevu') || title.contains('teyit')) {
    return TaskFollowUpIntent.appointmentConfirmation;
  }
  if (title.contains('fiyat') ||
      title.contains('bütçe') ||
      title.contains('pazarlık')) {
    return TaskFollowUpIntent.pricingFollowUp;
  }
  if (title.contains('takip') ||
      title.contains('ara') ||
      title.contains('arama') ||
      title.contains('acil')) {
    return TaskFollowUpIntent.followUpCall;
  }

  return TaskFollowUpIntent.generalReminder;
}
