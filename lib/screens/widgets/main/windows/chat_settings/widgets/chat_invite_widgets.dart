import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        const Text(
          'Коди запрошення',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1A58FF7F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF58FF7F).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.vpn_key,
                color: Color(0xFF58FF7F),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentInviteCode!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF58FF7F),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context),
                icon: const Icon(
                  Icons.copy,
                  color: Color(0xFF58FF7F),
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF58FF7F).withOpacity(0.1),
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
            color: Colors.white.withOpacity(0.3),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Код запрошення не створено',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Створіть код запрошення для додавання\nнових учасників до чату',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
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
        color: Colors.white.withOpacity(0.5),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: currentInviteCode!));
  }

  ButtonStyle _getGenerateButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF58FF7F).withOpacity(0.2),
      foregroundColor: const Color(0xFF58FF7F),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: const Color(0xFF58FF7F).withOpacity(0.3),
        ),
      ),
    );
  }

  ButtonStyle _getDeleteButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF5555).withOpacity(0.2),
      foregroundColor: const Color(0xFFFF5555),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: const Color(0xFFFF5555).withOpacity(0.3),
        ),
      ),
    );
  }

  ButtonStyle _getCreateButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF58FF7F).withOpacity(0.2),
      foregroundColor: const Color(0xFF58FF7F),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: const Color(0xFF58FF7F).withOpacity(0.3),
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
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58FF7F)),
            ),
          )
        : const Icon(Icons.refresh, size: 18);
  }

  Widget _getCreateButtonIcon() {
    return isGenerating
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58FF7F)),
            ),
          )
        : const Icon(Icons.add, size: 18);
  }
}