import 'package:flutter/material.dart';

class HomeUserProfileBadge extends StatelessWidget {
  final IconData avatarIcon;
  final String username;
  final VoidCallback onTap;

  const HomeUserProfileBadge({
    super.key,
    required this.avatarIcon,
    required this.username,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(avatarIcon, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
