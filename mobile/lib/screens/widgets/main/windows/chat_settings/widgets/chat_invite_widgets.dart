import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../app_colors.dart';

class ChatInviteCodesSection extends StatelessWidget {
  final String? currentInviteCode;
  final bool isGenerating;
  final VoidCallback onGenerateCode;
  final VoidCallback onDeleteCode;

  const ChatInviteCodesSection({
    super.key,
    this.currentInviteCode,
    required this.isGenerating,
    required this.onGenerateCode,
    required this.onDeleteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Коди запрошення',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.transparentWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.whiteText.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentInviteCode != null && currentInviteCode!.isNotEmpty) ...[
                _buildExistingCodeSection(context),
              ] else ...[
                _buildNoCodeSection(),
              ],
              const SizedBox(height: 8),
              _buildInfoText(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingCodeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Поточний код запрошення:',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.whiteText.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandGreenTransparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.brandGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.vpn_key,
                color: AppColors.brandGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentInviteCode!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandGreen,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context),
                icon: Icon(
                  Icons.copy,
                  color: AppColors.brandGreen,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandGreen.withOpacity(0.1),
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isGenerating ? null : onGenerateCode,
                style: _getGenerateButtonStyle(),
                icon: _getGenerateButtonIcon(),
                label: Text(
                  isGenerating ? 'Генерування...' : 'Згенерувати новий',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isGenerating ? null : onDeleteCode,
              style: _getDeleteButtonStyle(),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text(
                'Видалити',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoCodeSection() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.vpn_key_off,
            color: AppColors.whiteTransparent30,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Код запрошення не створено',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.whiteText.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Створіть код запрошення для додавання\nнових учасників до чату',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.whiteText.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isGenerating ? null : onGenerateCode,
            style: _getCreateButtonStyle(),
            icon: _getCreateButtonIcon(),
            label: Text(
              isGenerating ? 'Генерування...' : 'Створити код запрошення',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText() {
    return Text(
      'Код запрошення дозволяє іншим користувачам приєднатися до чату. Будьте обережні при поширенні коду.',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.whiteText.withOpacity(0.5),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: currentInviteCode!));
  }

  ButtonStyle _getGenerateButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.brandGreen.withOpacity(0.2),
      foregroundColor: AppColors.brandGreen,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.brandGreen.withOpacity(0.3),
        ),
      ),
    );
  }

  ButtonStyle _getDeleteButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.warningRed.withOpacity(0.2),
      foregroundColor: AppColors.warningRed,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.warningRed.withOpacity(0.3),
        ),
      ),
    );
  }

  ButtonStyle _getCreateButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.brandGreen.withOpacity(0.2),
      foregroundColor: AppColors.brandGreen,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.brandGreen.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
    );
  }

  Widget _getGenerateButtonIcon() {
    return isGenerating
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
            ),
          )
        : const Icon(Icons.refresh, size: 18);
  }

  Widget _getCreateButtonIcon() {
    return isGenerating
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
            ),
          )
        : const Icon(Icons.add, size: 18);
  }
}