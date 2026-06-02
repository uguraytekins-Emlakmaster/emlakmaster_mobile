import 'package:flutter/material.dart';

enum ClientMessagesChannelKind { whatsApp, phone, email }

enum ClientMessagesChannelTier { primary, standard }

/// Dürüst iletişim kanalı tanımı — uydurma sohbet veya geçmiş yok.
class ClientMessagesChannelSpec {
  const ClientMessagesChannelSpec({
    required this.kind,
    required this.icon,
    required this.title,
    required this.purpose,
    required this.nextStep,
    required this.meta,
    this.accent,
    this.tier = ClientMessagesChannelTier.standard,
  });

  final ClientMessagesChannelKind kind;
  final IconData icon;
  final String title;
  final String purpose;
  final String nextStep;
  final List<String> meta;
  final Color? accent;
  final ClientMessagesChannelTier tier;
}

/// Sabit kanal kataloğu — yalnızca gerçek url_launcher yolları.
const clientMessagesChannelCatalog = <ClientMessagesChannelSpec>[
  ClientMessagesChannelSpec(
    kind: ClientMessagesChannelKind.whatsApp,
    icon: Icons.chat_rounded,
    title: 'WhatsApp ile yazın',
    purpose: 'Hızlı sorular ve kısa koordinasyon',
    nextStep: 'WhatsApp harici uygulamada açılır · danışmanınıza yönlendirilir',
    meta: ['En hızlı', 'Harici', 'Geçmiş saklanmaz'],
    accent: Color(0xFF25D366),
    tier: ClientMessagesChannelTier.primary,
  ),
  ClientMessagesChannelSpec(
    kind: ClientMessagesChannelKind.phone,
    icon: Icons.phone_in_talk_rounded,
    title: 'Telefon',
    purpose: 'Acil görüşme ve net onaylar',
    nextStep: 'Arama ekranı açılır · mesai saatlerinde yanıt beklenir',
    meta: ['Doğrudan', 'Harici', 'Geçmiş saklanmaz'],
  ),
  ClientMessagesChannelSpec(
    kind: ClientMessagesChannelKind.email,
    icon: Icons.mark_email_unread_rounded,
    title: 'E-posta',
    purpose: 'Resmi talepler ve belge paylaşımı',
    nextStep: 'E-posta uygulamanız açılır · yanıt süresi ofise bağlıdır',
    meta: ['Resmi', 'Harici', 'Geçmiş saklanmaz'],
  ),
];

/// Güven şeridi — yalnızca anlamlı, dürüst sabit değerler.
const clientMessagesTrustCells = <(String value, String label)>[
  ('3', 'Kanal'),
  ('Hazır', 'İletişim'),
  ('—', 'Geçmiş'),
  ('Harici', 'Açılış'),
];
