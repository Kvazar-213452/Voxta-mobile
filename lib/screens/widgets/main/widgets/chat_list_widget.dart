import 'package:flutter/material.dart';
import '../../../../models/interface/chat_models.dart';
import 'chat_item_widget.dart';
import '../../../../app_colors.dart';

class ChatListWidget extends StatelessWidget {
  final List<ChatItem> chats;
  final TextEditingController searchController;
  final Function(ChatItem) onChatTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileSettingsTap;
  final VoidCallback onAddChatTap;

  const ChatListWidget({
    super.key,
    required this.chats,
    required this.searchController,
    required this.onChatTap,
    required this.onSettingsTap,
    required this.onAddChatTap,
    required this.onProfileSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Voxta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandGreen,
                          ),
                        ),
                        Row(
                          children: [
                            _buildHeaderButton(Icons.manage_accounts, onProfileSettingsTap),
                            const SizedBox(width: 8),
                            _buildHeaderButton(Icons.add, onAddChatTap),
                            const SizedBox(width: 8),
                            _buildHeaderButton(Icons.settings, onSettingsTap),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Search
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.whiteText.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(color: AppColors.whiteText),
                        decoration: InputDecoration(
                          hintText: 'Пошук чатів...',
                          hintStyle: TextStyle(color: AppColors.whiteText.withOpacity(0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.whiteText.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
            // Chats List
            Expanded(
              child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 700),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            curve: Curves.easeOutBack,
                            child: ChatItemWidget(
                              chat: chats[index],
                              index: index,
                              onTap: () => onChatTap(chats[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: 1.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.whiteText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.whiteText.withOpacity(0.1)),
            ),
            child: Icon(
              icon,
              color: AppColors.whiteText,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}