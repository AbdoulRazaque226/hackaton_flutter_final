import 'package:flutter/material.dart';

import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/services/firebase_service.dart';
import 'login_screen.dart';

/// Écran réservé au rôle UserRole.admin : liste de tous les comptes avec
/// blocage/déblocage, et quelques statistiques globales simples.
class AdminDashboardScreen extends StatefulWidget {
  final FirebaseService firebaseService;
  final void Function()? onLogout;

  AdminDashboardScreen({
    super.key,
    FirebaseService? firebaseService,
    this.onLogout,
  }) : firebaseService = firebaseService ?? FirebaseService();

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<void> _logout() async {
    await widget.firebaseService.signOut();
    if (!mounted) return;
    final onLogout = widget.onLogout;
    if (onLogout != null) {
      onLogout();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _toggleBlocage(AppUser user) async {
    final action = user.bloque ? 'débloquer' : 'bloquer';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmer'),
        content: Text(
          'Voulez-vous vraiment $action le compte de ${user.displayName.isEmpty ? user.email : user.displayName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(user.bloque ? 'Débloquer' : 'Bloquer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.firebaseService.setUserBlocked(user.uid, !user.bloque);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'Client';
      case UserRole.professionnel:
        return 'Professionnel';
      case UserRole.admin:
        return 'Admin';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.client:
        return Colors.blue;
      case UserRole.professionnel:
        return Colors.teal;
      case UserRole.admin:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: widget.firebaseService.watchAllUsers(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usersSnapshot.hasError) {
            return Center(child: Text('Erreur : ${usersSnapshot.error}'));
          }
          final users = usersSnapshot.data ?? [];
          final totalClients = users
              .where((u) => u.role == UserRole.client)
              .length;
          final totalPros = users
              .where((u) => u.role == UserRole.professionnel)
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Clients',
                        value: '$totalClients',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Professionnels',
                        value: '$totalPros',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder(
                        stream: widget.firebaseService.watchAllRequests(),
                        builder: (context, reqSnapshot) {
                          final total = reqSnapshot.data?.length;
                          return _StatCard(
                            label: 'Demandes',
                            value: total == null ? '…' : '$total',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: users.isEmpty
                    ? const Center(
                        child: Text('Aucun utilisateur pour le moment.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: users.length,
                        itemBuilder: (context, i) {
                          final user = users[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _roleColor(
                                  user.role,
                                ).withValues(alpha: 0.15),
                                child: Icon(
                                  user.bloque ? Icons.block : Icons.person,
                                  color: _roleColor(user.role),
                                ),
                              ),
                              title: Text(
                                user.displayName.isEmpty
                                    ? user.email
                                    : user.displayName,
                              ),
                              subtitle: Text('${user.email}\n${user.phone}'),
                              isThreeLine: true,
                              trailing: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text(
                                      _roleLabel(user.role),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: _roleColor(user.role),
                                  ),
                                  if (user.role != UserRole.admin)
                                    IconButton(
                                      icon: Icon(
                                        user.bloque
                                            ? Icons.lock_open
                                            : Icons.lock_outline,
                                        color: user.bloque
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      tooltip: user.bloque
                                          ? 'Débloquer'
                                          : 'Bloquer',
                                      onPressed: () => _toggleBlocage(user),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
