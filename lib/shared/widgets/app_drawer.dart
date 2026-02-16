
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/auth/presentation/providers/auth_provider.dart';
import 'package:escape_room_admin/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authProvider);
    final user = authStateAsync.value?.user;
    final currentRoute = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: Colors.transparent, // Allow for custom background styling
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack.withOpacity(0.95),
          border: const Border(
            right: BorderSide(color: AppTheme.grayBorder, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Custom Sleek Header
            _buildCustomHeader(user),
            
            const Gap(20),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                   _MenuSectionHeader(title: 'NAVIGATION'),
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard,
                    label: 'Tableau de bord',
                    isSelected: currentRoute == '/dashboard-home',
                    onTap: () => context.go('/dashboard-home'),
                  ),
                  _DrawerItem(
                    icon: Icons.extension_outlined,
                    selectedIcon: Icons.extension,
                    label: 'Scénarios',
                    isSelected: currentRoute == '/scenarios',
                    onTap: () => context.go('/scenarios'),
                  ),
                  
                  const Gap(20),
                  _MenuSectionHeader(title: 'CONFIGURATION'),
                  _DrawerItem(
                    icon: Icons.settings_applications_outlined,
                    selectedIcon: Icons.settings_applications,
                    label: 'Gestion des Scénarios',
                    isSelected: currentRoute.contains('/settings/scenarios'),
                    onTap: () => context.go('/settings/scenarios'),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Paramètres Généraux',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Footer / Logout
            _buildFooter(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryBlack,
            AppTheme.primaryBlack,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryRed, AppTheme.secondaryRed],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.secondaryBlack,
              backgroundImage: user?.profilePicture != null 
                  ? NetworkImage(user!.profilePicture!) 
                  : null,
              child: user?.profilePicture == null
                  ? const Icon(Icons.person, color: AppTheme.white, size: 30)
                  : null,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.username?.toUpperCase() ?? 'ADMINISTRATEUR',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    user?.role == 'super_admin' ? 'SYSTEM ADMIN' : 'GAME MASTER',
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.grayBorder, width: 0.5)),
      ),
      child: _DrawerItem(
        icon: Icons.logout_rounded,
        label: 'Déconnexion',
        iconColor: AppTheme.grayText,
        textColor: AppTheme.grayText,
        onTap: () => ref.read(authProvider.notifier).logout(),
        isLogout: true,
      ),
    );
  }
}

class _MenuSectionHeader extends StatelessWidget {
  final String title;
  const _MenuSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.grayText.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? iconColor;
  final Color? textColor;
  final bool isLogout;

  const _DrawerItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.iconColor,
    this.textColor,
    this.isLogout = false,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected || _isHovered;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: widget.isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.15),
                    AppTheme.primaryRed.withOpacity(0.05),
                  ],
                )
              : null,
          color: _isHovered && !widget.isSelected 
              ? AppTheme.white.withOpacity(0.05) 
              : Colors.transparent,
        ),
        child: ListTile(
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            active ? (widget.selectedIcon ?? widget.icon) : widget.icon,
            color: active 
                ? (widget.isLogout ? AppTheme.primaryRed : AppTheme.white) 
                : (widget.iconColor ?? AppTheme.grayText),
            size: 22,
          ),
          title: Text(
            widget.label,
            style: TextStyle(
              color: active 
                  ? (widget.isLogout ? AppTheme.primaryRed : AppTheme.white) 
                  : (widget.textColor ?? AppTheme.grayText),
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          trailing: widget.isSelected
              ? Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRed.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
