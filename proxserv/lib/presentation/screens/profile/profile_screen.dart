import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/app_providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/professional_profile.dart';
import '../dashboard/dashboard_menu.dart';

/// Onglet « Profil » du dashboard.
///
/// L'identité (nom, téléphone) est éditée pour tous les rôles et écrite dans
/// `users/{uid}`. Un professionnel peut en plus corriger son métier et sa zone
/// d'intervention, écrits dans `professionals/{uid}` — les deux écritures sont
/// autorisées par les règles pour le propriétaire du document.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final profile = ref.watch(professionalProfileProvider).value;
    final loc = AppLocalizations.of(context, ref);

    return Scaffold(
      appBar: AppBar(
        leading: dashboardMenuLeading(context),
        title: Text(loc.profileTab),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.settingsTab,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _ProfileForm(user: user, profile: profile),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final AppUser user;
  final ProfessionalProfile? profile;

  const _ProfileForm({required this.user, required this.profile});

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _zone;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _neighborhood;
  late Metier _metier;

  bool _saving = false;
  bool _dirty = false;
  bool _syncingProfile = false;

  bool get _isPro => widget.user.role == UserRole.professionnel;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: widget.user.displayName);
    _phone = TextEditingController(text: widget.user.phone);
    _zone = TextEditingController(text: profile?.zoneIntervention ?? '');
    _country = TextEditingController(
      text: _isPro ? profile?.country ?? '' : widget.user.country,
    );
    _city = TextEditingController(
      text: _isPro ? profile?.city ?? '' : widget.user.city,
    );
    _neighborhood = TextEditingController(
      text: _isPro ? profile?.neighborhood ?? '' : widget.user.neighborhood,
    );
    _metier = profile?.metier ?? Metier.autre;
    for (final controller in [
      _name,
      _phone,
      _zone,
      _country,
      _city,
      _neighborhood,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _zone,
      _country,
      _city,
      _neighborhood,
    ]) {
      controller
        ..removeListener(_markDirty)
        ..dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_syncingProfile && !_dirty) setState(() => _dirty = true);
  }

  @override
  void didUpdateWidget(covariant _ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Le profil professionnel arrive via un flux Firestore séparé, souvent
    // après le premier build (ProfileScreen est monté immédiatement par
    // l'IndexedStack du dashboard). S'il n'était pas encore là pendant
    // initState, on remplit les champs dès qu'il arrive, sans écraser une
    // saisie déjà en cours par l'utilisateur.
    if (!_dirty && oldWidget.profile == null && widget.profile != null) {
      _syncingProfile = true;
      _zone.text = widget.profile!.zoneIntervention;
      _country.text = widget.profile!.country;
      _city.text = widget.profile!.city;
      _neighborhood.text = widget.profile!.neighborhood;
      _metier = widget.profile!.metier;
      _syncingProfile = false;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final firestore = ref.read(firestoreProvider);

    try {
      await firestore.collection('users').doc(widget.user.uid).update({
        'displayName': _name.text.trim(),
        'phone': _phone.text.trim(),
        if (!_isPro) 'country': _country.text.trim(),
        if (!_isPro) 'city': _city.text.trim(),
        if (!_isPro) 'neighborhood': _neighborhood.text.trim(),
      });

      if (_isPro && widget.profile != null) {
        await firestore.collection('professionals').doc(widget.user.uid).update(
          {
            'metier': _metier.name,
            'zoneIntervention': _zone.text.trim(),
            'country': _country.text.trim(),
            'city': _city.text.trim(),
            'neighborhood': _neighborhood.text.trim(),
          },
        );
      }

      if (!mounted) return;
      final loc = AppLocalizations.fromContext(context);
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.text('Profil mis à jour.', 'Profile updated.')),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final loc = AppLocalizations.fromContext(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.text(
              'Enregistrement impossible : $error',
              'Unable to save profile: $error',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final completion = _completion(profile);
    final loc = AppLocalizations.fromContext(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _initials(_name.text),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _roleLabel(widget.user.role, loc),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Jauge de complétion : indique ce qui manque encore au profil.
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.text(
                          'Profil complété à $completion %',
                          'Profile $completion% complete',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: completion / 100),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          loc.text('Identité', 'Identity'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: loc.fullNameLabel,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: loc.phoneLabel,
            border: OutlineInputBorder(),
          ),
        ),

        if (!_isPro) ...[
          const SizedBox(height: 20),
          Text(
            loc.text('Lieu habituel', 'Usual location'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          _locationFields(loc),
        ],

        if (_isPro) ...[
          const SizedBox(height: 20),
          Text(
            loc.text('Activité', 'Professional details'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Metier>(
            initialValue: _metier,
            decoration: InputDecoration(
              labelText: loc.text('Métier', 'Trade'),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final metier in Metier.values)
                DropdownMenuItem(
                  value: metier,
                  child: Text(loc.metierLabel(metier)),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _metier = value;
                _dirty = true;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _zone,
            decoration: InputDecoration(
              labelText: loc.text('Zone d\'intervention', 'Service area'),
              hintText: loc.text('Ex. Cocody, Abidjan', 'e.g. Cocody, Abidjan'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _locationFields(loc),
        ],

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: (!_dirty || _saving) ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(loc.text('Enregistrer', 'Save')),
        ),
      ],
    );
  }

  Widget _locationFields(AppLocalizations loc) {
    return Column(
      children: [
        TextField(
          controller: _country,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: loc.text('Pays', 'Country'),
            hintText: loc.text('Ex. Côte d’Ivoire', 'e.g. Côte d’Ivoire'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: loc.text('Ville', 'City'),
            hintText: loc.text('Ex. Abidjan', 'e.g. Abidjan'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _neighborhood,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: loc.text('Quartier / zone (facultatif)', 'Neighborhood / area (optional)'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// Proportion de champs renseignés, sur 2 (identité) ou 4 (professionnel).
  int _completion(ProfessionalProfile? profile) {
    var filled = 0;
    final total = _isPro ? 6 : 4;

    if (_name.text.trim().isNotEmpty) filled++;
    if (_phone.text.trim().isNotEmpty) filled++;
    if (_isPro) {
      if (_zone.text.trim().isNotEmpty) filled++;
      if (_metier != Metier.autre) filled++;
    }
    if (_country.text.trim().isNotEmpty) filled++;
    if (_city.text.trim().isNotEmpty) filled++;

    return ((filled / total) * 100).round().clamp(0, 100);
  }
}

/// Initiales affichées dans l'avatar : la première lettre du premier et du
/// dernier mot du nom.
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

  final first = parts.first.substring(0, 1);
  final last = parts.last.substring(0, 1);
  return (first + last).toUpperCase();
}

String _roleLabel(UserRole role, AppLocalizations loc) => loc.roleLabel(role);
