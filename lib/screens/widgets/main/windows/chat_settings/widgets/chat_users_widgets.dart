import 'package:flutter/material.dart';
import 'chat_basic_widgets.dart';

class ChatOwnerSection extends StatelessWidget {
  final String owner;
  final Map<String, dynamic> usersData;
  final bool isLoadingUsers;

  const ChatOwnerSection({
    super.key,
    required this.owner,
    required this.usersData,
    required this.isLoadingUsers,
  });

  @override
  Widget build(BuildContext context) {
    final ownerData = usersData[owner];
    
    if (isLoadingUsers) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF58FF7F).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58FF7F)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Завантаження інформації про власника...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Власник чату',
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
              color: const Color(0xFF58FF7F).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              UserAvatar(
                avatar: ownerData?['avatar'],
                size: 40,
                isOwner: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFF58FF7F),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ownerData?['name'] ?? 'Невідомий власник',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEEEEEE),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatUsersSection extends StatelessWidget {
  final Map<String, dynamic> usersData;
  final bool isLoadingUsers;
  final String owner;
  final Function(String) onRemoveUser;

  const ChatUsersSection({
    super.key,
    required this.usersData,
    required this.isLoadingUsers,
    required this.owner,
    required this.onRemoveUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Учасники чату (${usersData.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: isLoadingUsers
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58FF7F)),
                  ),
                )
              : usersData.isEmpty
                  ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Немає учасників для відображення',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: usersData.length,
                      itemBuilder: (context, index) {
                        final entry = usersData.entries.elementAt(index);
                        final userId = entry.key;
                        final userData = entry.value;
                        
                        return UserItem(
                          userId: userId,
                          name: userData['name'] ?? 'Невідомо',
                          avatar: userData['avatar'],
                          isOwner: userId == owner,
                          onRemove: () => onRemoveUser(userId),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class UserItem extends StatelessWidget {
  final String userId;
  final String name;
  final String? avatar;
  final bool isOwner;
  final VoidCallback onRemove;

  const UserItem({
    super.key,
    required this.userId,
    required this.name,
    this.avatar,
    required this.isOwner,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwner 
              ? const Color(0xFF58FF7F).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            avatar: avatar,
            size: 40,
            isOwner: isOwner,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isOwner) ...[
                      const Icon(
                        Icons.star,
                        color: Color(0xFF58FF7F),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isOwner ? FontWeight.w700 : FontWeight.w600,
                          color: isOwner 
                              ? const Color(0xFF58FF7F)
                              : const Color(0xFFEEEEEE),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isOwner)
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Color(0xFFFF5555),
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5555).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF58FF7F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF58FF7F).withOpacity(0.3),
                ),
              ),
              child: const Text(
                'Власник',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF58FF7F),
                ),
              ),
            ),
        ],
      ),
    );
  }
}