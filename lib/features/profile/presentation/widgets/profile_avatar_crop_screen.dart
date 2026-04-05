import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Tam ekran 1:1 kırpma — sabit kare alan, görüntü yakınlaştırma ve kaydırma (interactive).
/// Dönüş: [Uint8List] kırpılmış piksel veya iptal ([null]).
class ProfileAvatarCropScreen extends StatefulWidget {
  const ProfileAvatarCropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ProfileAvatarCropScreen> createState() => _ProfileAvatarCropScreenState();
}

class _ProfileAvatarCropScreenState extends State<ProfileAvatarCropScreen> {
  final _controller = CropController();
  late final Uint8List _originalBytes;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    _originalBytes = Uint8List.fromList(widget.imageBytes);
  }

  void _cancel() {
    if (_cropping) return;
    Navigator.of(context).pop();
  }

  void _reset() {
    if (_cropping) return;
    _controller.image = Uint8List.fromList(_originalBytes);
  }

  void _apply() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        backgroundColor: ext.background,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Vazgeç',
          onPressed: _cancel,
        ),
        title: Text(
          'Fotoğrafı düzenle',
          style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space6,
                0,
                DesignTokens.space6,
                DesignTokens.space3,
              ),
              child: Text(
                'Kare alan sabit. Görüntüyü yakınlaştırıp kaydırın — profil dairesinde net görünür.',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: Crop(
                    image: _originalBytes,
                    controller: _controller,
                    aspectRatio: 1,
                    interactive: true,
                    fixCropRect: true,
                    initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                      size: 0.88,
                    ),
                    baseColor: ext.surfaceElevated,
                    maskColor: Colors.black.withValues(alpha: 0.52),
                    radius: 6,
                    cornerDotBuilder: (size, edge) => DotControl(
                      color: ext.accent.withValues(alpha: 0.95),
                      padding: 6,
                    ),
                    onCropped: (result) {
                      if (!mounted) return;
                      setState(() => _cropping = false);
                      if (result is CropSuccess) {
                        Navigator.of(context).pop<Uint8List?>(result.croppedImage);
                      } else if (result is CropFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              userFacingErrorMessage(result.cause, context: 'avatar_crop'),
                            ),
                          ),
                        );
                      }
                    },
                    progressIndicator: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ext.accent,
                        ),
                      ),
                    ),
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space6,
                DesignTokens.space4,
                DesignTokens.space6,
                DesignTokens.space6,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _cropping ? null : _cancel,
                    child: Text(
                      'Vazgeç',
                      style: TextStyle(color: ext.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _cropping ? null : _reset,
                    child: Text(
                      'Sıfırla',
                      style: TextStyle(color: ext.accent.withValues(alpha: 0.95), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  FilledButton(
                    onPressed: _cropping ? null : _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: ext.accent,
                      foregroundColor: ext.background,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    child: _cropping
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ext.background,
                            ),
                          )
                        : const Text('Uygula'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
