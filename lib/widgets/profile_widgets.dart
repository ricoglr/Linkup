import 'package:flutter/material.dart';

class ProfilePhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;
  final double radius;
  final bool showEditIcon;

  const ProfilePhotoWidget({
    Key? key,
    this.photoUrl,
    required this.onTap,
    this.radius = 60,
    this.showEditIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Icon(Icons.person, size: radius)
              : null,
        ),
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                iconSize: 20,
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const ProfileInfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios) : null),
        onTap: onTap,
      ),
    );
  }
}

class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const ProfileSectionHeader({
    Key? key,
    required this.title,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final String verifiedText;
  final String unverifiedText;
  final VoidCallback? onVerify;

  const VerificationBadge({
    Key? key,
    required this.isVerified,
    this.verifiedText = 'Doğrulandı',
    this.unverifiedText = 'Doğrula',
    this.onVerify,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(
              verifiedText,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return TextButton.icon(
        onPressed: onVerify,
        icon: const Icon(Icons.verified_user, size: 16),
        label: Text(unverifiedText),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isVerified;
  final VoidCallback? onVerify;

  const ProfileField({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.isVerified = false,
    this.onVerify,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        subtitle: Text(value.isEmpty ? 'Belirtilmemiş' : value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onVerify != null)
              VerificationBadge(
                isVerified: isVerified,
                onVerify: onVerify,
              ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 18),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class DangerZoneCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final IconData icon;

  const DangerZoneCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    this.icon = Icons.warning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.loadingText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (loadingText != null) ...[
                        const SizedBox(height: 16),
                        Text(loadingText!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}