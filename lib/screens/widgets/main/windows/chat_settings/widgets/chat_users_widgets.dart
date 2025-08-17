import 'package:flutter/material.dart';
import 'chat_basic_widgets.dart';
import '../../../../../../app_colors.dart';

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
          color: AppColors.transparentWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.brandGreenTransparent03,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Завантаження інформації про власника...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.whiteTransparent07,
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
        Text(
          'Власник чату',
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
              color: AppColors.brandGreenTransparent03,
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
                        Icon(
                          Icons.star,
                          color: AppColors.brandGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ownerData?['name'] ?? 'Невідомий власник',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightGray,
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.transparentWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.whiteTransparent10,
            ),
          ),
          child: isLoadingUsers
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
                  ),
                )
              : usersData.isEmpty
                  ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.whiteTransparent50,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Немає учасників для відображення',
                              style: TextStyle(
                                color: AppColors.whiteTransparent07,
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
        color: AppColors.transparentWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwner 
              ? AppColors.brandGreenTransparent03
              : AppColors.whiteTransparent10,
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
                      Icon(
                        Icons.star,
                        color: AppColors.brandGreen,
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
                              ? AppColors.brandGreen
                              : AppColors.lightGray,
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
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.warningRed,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.warningRedTransparent10,
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
                color: AppColors.brandGreenTransparent10,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.brandGreenTransparent03,
                ),
              ),
              child: Text(
                'Власник',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}