import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/dialer_contact_directory.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/dialer_theme_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_action_feedback.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Üst alan: rehber araması + giden hat bilgisi (ofis adı).
class DialerContactSearchHeader extends StatefulWidget {
  const DialerContactSearchHeader({
    super.key,
    required this.tokens,
    required this.officeName,
    required this.dialNotifier,
    this.onContactSelected,
  });

  final DialerThemeTokens tokens;
  final String? officeName;
  final ValueNotifier<String> dialNotifier;
  final void Function(String? displayName)? onContactSelected;

  @override
  State<DialerContactSearchHeader> createState() =>
      _DialerContactSearchHeaderState();
}

class _DialerContactSearchHeaderState extends State<DialerContactSearchHeader> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<DialerContactEntry> _allContacts = [];
  List<DialerContactEntry> _suggestions = [];
  bool _loading = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _ensureContactsLoaded() async {
    if (_allContacts.isNotEmpty || _loading) return;
    setState(() => _loading = true);
    final result = await loadDialerContactDirectory();
    if (!mounted) return;
    if (result.perm != DialerContactsLoadResult.granted) {
      setState(() {
        _loading = false;
        _permissionDenied = true;
      });
      if (result.perm == DialerContactsLoadResult.permanentlyDenied) {
        await showPremiumActionFeedback(
          context,
          title: 'Rehber izni gerekli',
          message:
              'Kişi aramak için ayarlardan rehber erişimini açın; numarayı tuş takımından da girebilirsiniz.',
          type: PremiumActionFeedbackType.warning,
        );
      }
      return;
    }
    setState(() {
      _allContacts = result.contacts;
      _loading = false;
      _permissionDenied = false;
    });
    _onSearchChanged();
  }

  void _onSearchChanged() {
    final q = _searchController.text;
    setState(() {
      _suggestions = filterDialerContacts(_allContacts, q);
    });
  }

  void _selectContact(DialerContactEntry entry) {
    AppFeedback.selectionClick();
    widget.dialNotifier.value =
        OutboundPhoneDial.sanitizeDialEntry(entry.phoneDigits);
    widget.onContactSelected?.call(
      entry.displayName.isEmpty ? entry.phoneDisplay : entry.displayName,
    );
    _searchController.text =
        entry.displayName.isEmpty ? entry.phoneDisplay : entry.displayName;
    _focusNode.unfocus();
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final office = widget.officeName?.trim();
    final lineLabel = office != null && office.isNotEmpty
        ? office
        : 'Kurumsal çıkış hattı';
    final showSuggestions = _focusNode.hasFocus &&
        _searchController.text.trim().isNotEmpty &&
        _suggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onTap: _ensureContactsLoaded,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: t.labelPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Ara',
              hintStyle: TextStyle(
                color: t.labelSecondary,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF767680).withValues(alpha: 0.24)
                  : const Color(0xFF767680).withValues(alpha: 0.12),
              prefixIcon:
                  Icon(Icons.search_rounded, color: t.labelSecondary, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Temizle',
                      onPressed: () {
                        _searchController.clear();
                        widget.onContactSelected?.call(null);
                        setState(() => _suggestions = []);
                      },
                      icon: Icon(Icons.cancel_rounded,
                          color: t.labelSecondary, size: 20),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: t.labelSecondary.withValues(alpha: 0.35),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.call_made_rounded, size: 14, color: t.labelSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Giden hat · $lineLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: t.labelSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.labelSecondary,
                ),
              ),
          ],
        ),
        if (_permissionDenied && !_loading)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Rehber kapalı — numarayı aşağıdan girin.',
              style: TextStyle(fontSize: 11, color: t.labelSecondary),
            ),
          ),
        if (showSuggestions) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.capsuleFill,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: t.capsuleBorder),
              boxShadow: [
                BoxShadow(
                  color: t.capsuleShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: t.capsuleBorder,
              ),
              itemBuilder: (context, i) {
                final c = _suggestions[i];
                final title =
                    c.displayName.isEmpty ? 'İsimsiz' : c.displayName;
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: t.keyFill,
                    child: Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: t.labelPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.labelPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    c.phoneDisplay,
                    style: TextStyle(color: t.labelSecondary, fontSize: 13),
                  ),
                  onTap: () => _selectContact(c),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
