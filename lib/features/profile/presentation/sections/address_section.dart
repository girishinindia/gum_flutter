// Address section.
//
// Current + permanent address. Each block has:
//   • line1 / line2 (text)
//   • country / state / city (FK IDs via MastersApi, cascade)
//   • postal code (Indian PIN validator when country is India)
//
// Cascade behaviour: picking a country clears state + city and
// re-loads states. Picking a state clears city and re-loads cities.
// All three lists live in local state; the masters API is hit lazily
// the first time each dropdown opens.
//
// "Same as current" copies every current_* field into permanent_*
// in one tap.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../data/masters_api.dart';
import '../../domain/master_models.dart';
import '../../domain/user_profile.dart';
import '../widgets/searchable_select.dart';

class AddressSection extends StatefulWidget {
  const AddressSection({super.key});

  @override
  State<AddressSection> createState() => _AddressSectionState();
}

class _AddressSectionState extends State<AddressSection> {
  final _formKey = GlobalKey<FormState>();
  final _masters = MastersApi();
  bool _hydrated   = false;
  bool _submitting = false;
  String? _formError;

  // Master lookups — fetched lazily.
  List<Country>  _countries = const [];
  bool _countriesLoading = false;
  /// In-flight `_loadCountries` future. Stored so `_hydrate` can chain
  /// off the same load when it lands AFTER initState has kicked one off
  /// — otherwise the second `_loadCountries()` early-returns and the
  /// stub-replacement `.then(...)` runs against an empty list.
  Future<void>? _countriesFuture;

  final Map<int, List<StateRow>> _statesByCountry = {};
  final Set<int> _statesLoadingFor = {};

  final Map<int, List<CityRow>> _citiesByState = {};
  final Set<int> _citiesLoadingFor = {};

  // Form state — two blocks.
  final _curLine1 = TextEditingController();
  final _curLine2 = TextEditingController();
  final _curPin   = TextEditingController();
  Country?  _curCountry;
  StateRow? _curState;
  CityRow?  _curCity;

  final _permLine1 = TextEditingController();
  final _permLine2 = TextEditingController();
  final _permPin   = TextEditingController();
  Country?  _permCountry;
  StateRow? _permState;
  CityRow?  _permCity;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _curLine1.dispose();
    _curLine2.dispose();
    _curPin.dispose();
    _permLine1.dispose();
    _permLine2.dispose();
    _permPin.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() {
    if (_countries.isNotEmpty) return Future.value();
    final existing = _countriesFuture;
    if (existing != null) return existing;
    setState(() => _countriesLoading = true);
    final future = () async {
      try {
        final rows = await _masters.listCountries();
        if (mounted) setState(() => _countries = rows);
      } catch (_) {
        // Swallow — the dropdown will simply show "No options available."
      } finally {
        if (mounted) setState(() => _countriesLoading = false);
      }
    }();
    _countriesFuture = future;
    return future;
  }

  Future<void> _ensureStates(int countryId) async {
    if (_statesByCountry[countryId] != null || _statesLoadingFor.contains(countryId)) return;
    setState(() => _statesLoadingFor.add(countryId));
    try {
      final rows = await _masters.listStates(countryId);
      if (mounted) setState(() => _statesByCountry[countryId] = rows);
    } catch (_) {
      if (mounted) setState(() => _statesByCountry[countryId] = const []);
    } finally {
      if (mounted) setState(() => _statesLoadingFor.remove(countryId));
    }
  }

  Future<void> _ensureCities(int stateId) async {
    if (_citiesByState[stateId] != null || _citiesLoadingFor.contains(stateId)) return;
    setState(() => _citiesLoadingFor.add(stateId));
    try {
      final rows = await _masters.listCities(stateId);
      if (mounted) setState(() => _citiesByState[stateId] = rows);
    } catch (_) {
      if (mounted) setState(() => _citiesByState[stateId] = const []);
    } finally {
      if (mounted) setState(() => _citiesLoadingFor.remove(stateId));
    }
  }

  void _hydrate(UserProfile p) {
    if (_hydrated) return;
    _curLine1.text = p.currentAddressLine1 ?? '';
    _curLine2.text = p.currentAddressLine2 ?? '';
    _curPin.text   = p.currentPostalCode ?? '';

    _permLine1.text = p.permanentAddressLine1 ?? '';
    _permLine2.text = p.permanentAddressLine2 ?? '';
    _permPin.text   = p.permanentPostalCode ?? '';

    // Phase 43.2 — the API now embeds joined country/state/city names
    // (`current_country: {id, name}` etc. via PROFILE_SELECT), so on
    // re-entry we seed each selectedItem with the REAL display label
    // instead of a `#<id>` stub. The cascade below still loads the
    // full lists in the background — first so the dropdown is usable,
    // second so the stored row gets swapped for the canonical Equatable
    // instance from the loaded list (preserves selection highlight in
    // the picker sheet).
    if (p.currentCountryId != null) {
      _curCountry = Country(
        id:   p.currentCountryId!,
        name: p.currentCountryName ?? '#${p.currentCountryId}',
      );
    }
    if (p.currentStateId != null) {
      _curState = StateRow(
        id:        p.currentStateId!,
        countryId: p.currentCountryId ?? 0,
        name:      p.currentStateName ?? '#${p.currentStateId}',
      );
    }
    if (p.currentCityId != null) {
      _curCity = CityRow(
        id:      p.currentCityId!,
        stateId: p.currentStateId ?? 0,
        name:    p.currentCityName ?? '#${p.currentCityId}',
      );
    }
    if (p.permanentCountryId != null) {
      _permCountry = Country(
        id:   p.permanentCountryId!,
        name: p.permanentCountryName ?? '#${p.permanentCountryId}',
      );
    }
    if (p.permanentStateId != null) {
      _permState = StateRow(
        id:        p.permanentStateId!,
        countryId: p.permanentCountryId ?? 0,
        name:      p.permanentStateName ?? '#${p.permanentStateId}',
      );
    }
    if (p.permanentCityId != null) {
      _permCity = CityRow(
        id:      p.permanentCityId!,
        stateId: p.permanentStateId ?? 0,
        name:    p.permanentCityName ?? '#${p.permanentCityId}',
      );
    }

    // Kick off cascade loads to resolve the stub labels.
    if (p.currentCountryId != null) {
      _ensureStates(p.currentCountryId!).then((_) {
        if (!mounted || _curState == null) return;
        final list = _statesByCountry[p.currentCountryId!] ?? const [];
        final real = list.where((s) => s.id == _curState!.id).cast<StateRow?>().firstWhere(
          (s) => s != null, orElse: () => null);
        if (real != null) setState(() => _curState = real);
      });
    }
    if (p.currentStateId != null) {
      _ensureCities(p.currentStateId!).then((_) {
        if (!mounted || _curCity == null) return;
        final list = _citiesByState[p.currentStateId!] ?? const [];
        final real = list.where((c) => c.id == _curCity!.id).cast<CityRow?>().firstWhere(
          (c) => c != null, orElse: () => null);
        if (real != null) setState(() => _curCity = real);
      });
    }
    if (p.permanentCountryId != null) {
      _ensureStates(p.permanentCountryId!).then((_) {
        if (!mounted || _permState == null) return;
        final list = _statesByCountry[p.permanentCountryId!] ?? const [];
        final real = list.where((s) => s.id == _permState!.id).cast<StateRow?>().firstWhere(
          (s) => s != null, orElse: () => null);
        if (real != null) setState(() => _permState = real);
      });
    }
    if (p.permanentStateId != null) {
      _ensureCities(p.permanentStateId!).then((_) {
        if (!mounted || _permCity == null) return;
        final list = _citiesByState[p.permanentStateId!] ?? const [];
        final real = list.where((c) => c.id == _permCity!.id).cast<CityRow?>().firstWhere(
          (c) => c != null, orElse: () => null);
        if (real != null) setState(() => _permCity = real);
      });
    }

    // Country labels too.
    if (_countries.isEmpty) {
      _loadCountries().then((_) {
        if (!mounted) return;
        setState(() {
          if (_curCountry != null) {
            final real = _countries.where((c) => c.id == _curCountry!.id).cast<Country?>().firstWhere(
              (c) => c != null, orElse: () => null);
            if (real != null) _curCountry = real;
          }
          if (_permCountry != null) {
            final real = _countries.where((c) => c.id == _permCountry!.id).cast<Country?>().firstWhere(
              (c) => c != null, orElse: () => null);
            if (real != null) _permCountry = real;
          }
        });
      });
    }

    _hydrated = true;
  }

  void _copyCurrentToPermanent() {
    setState(() {
      _permLine1.text = _curLine1.text;
      _permLine2.text = _curLine2.text;
      _permPin.text   = _curPin.text;
      _permCountry    = _curCountry;
      _permState      = _curState;
      _permCity       = _curCity;
    });
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final profileBloc = context.read<ProfileBloc>();
    final messenger   = ScaffoldMessenger.of(context);

    try {
      final patch = <String, dynamic>{
        'current_address_line1':     _curLine1.text.trim().isEmpty ? null : _curLine1.text.trim(),
        'current_address_line2':     _curLine2.text.trim().isEmpty ? null : _curLine2.text.trim(),
        'current_city_id':           _curCity?.id,
        'current_state_id':          _curState?.id,
        'current_country_id':        _curCountry?.id,
        'current_postal_code':       _curPin.text.trim().isEmpty ? null : _curPin.text.trim(),

        'permanent_address_line1':   _permLine1.text.trim().isEmpty ? null : _permLine1.text.trim(),
        'permanent_address_line2':   _permLine2.text.trim().isEmpty ? null : _permLine2.text.trim(),
        'permanent_city_id':         _permCity?.id,
        'permanent_state_id':        _permState?.id,
        'permanent_country_id':      _permCountry?.id,
        'permanent_postal_code':     _permPin.text.trim().isEmpty ? null : _permPin.text.trim(),
      };
      final updated = await profileBloc.repository.updateProfile(patch);
      if (!mounted) return;
      profileBloc.add(ProfileProfileUpdated(updated));
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.isSilent) return; // Phase 43.5 — silent 401 → AuthBloc redirects
      setState(() => _formError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Address')),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _hydrate(state.bundle!.profile);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Current address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _addressBlock(
                      line1Ctl: _curLine1,
                      line2Ctl: _curLine2,
                      pinCtl:   _curPin,
                      country:  _curCountry,
                      state:    _curState,
                      city:     _curCity,
                      onCountryChanged: (c) {
                        setState(() {
                          _curCountry = c;
                          _curState   = null;
                          _curCity    = null;
                        });
                        _ensureStates(c.id);
                      },
                      onStateChanged: (s) {
                        setState(() {
                          _curState = s;
                          _curCity  = null;
                        });
                        _ensureCities(s.id);
                      },
                      onCityChanged: (c) => setState(() => _curCity = c),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Permanent same as current'),
                      onPressed: _copyCurrentToPermanent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Permanent address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _addressBlock(
                      line1Ctl: _permLine1,
                      line2Ctl: _permLine2,
                      pinCtl:   _permPin,
                      country:  _permCountry,
                      state:    _permState,
                      city:     _permCity,
                      onCountryChanged: (c) {
                        setState(() {
                          _permCountry = c;
                          _permState   = null;
                          _permCity    = null;
                        });
                        _ensureStates(c.id);
                      },
                      onStateChanged: (s) {
                        setState(() {
                          _permState = s;
                          _permCity  = null;
                        });
                        _ensureCities(s.id);
                      },
                      onCityChanged: (c) => setState(() => _permCity = c),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: _formError!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _save,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _addressBlock({
    required TextEditingController line1Ctl,
    required TextEditingController line2Ctl,
    required TextEditingController pinCtl,
    required Country?  country,
    required StateRow? state,
    required CityRow?  city,
    required ValueChanged<Country>  onCountryChanged,
    required ValueChanged<StateRow> onStateChanged,
    required ValueChanged<CityRow>  onCityChanged,
  }) {
    final states = country == null ? const <StateRow>[] : (_statesByCountry[country.id] ?? const []);
    final cities = state   == null ? const <CityRow>[]  : (_citiesByState[state.id] ?? const []);
    // Phase 43.8 — only show the inline spinner when the field is EMPTY
    // and we're still resolving its list. With Phase 43.2 the saved name
    // hydrates instantly, so spinning next to a populated "Gujarat" /
    // "Surat" looks like the value is in trouble. The list still loads
    // in the background — the picker sheet will populate when the user
    // taps the field.
    final statesLoading = country != null && state == null && _statesLoadingFor.contains(country.id);
    final citiesLoading = state   != null && city  == null && _citiesLoadingFor.contains(state.id);

    return Column(
      children: [
        TextFormField(
          controller: line1Ctl,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
          decoration: const InputDecoration(labelText: 'Address line 1'),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: line2Ctl,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
          decoration: const InputDecoration(labelText: 'Address line 2'),
        ),
        const SizedBox(height: 10),
        SearchableSelect<Country>(
          label: 'Country',
          items: _countries,
          isLoading: _countriesLoading,
          selectedItem: country,
          labelOf: (c) => c.name.startsWith('#') ? 'Loading…' : c.name,
          onSelected: onCountryChanged,
        ),
        const SizedBox(height: 10),
        SearchableSelect<StateRow>(
          label: 'State',
          items: states,
          isLoading: statesLoading,
          selectedItem: state,
          enabled: country != null,
          labelOf: (s) => s.name.startsWith('#') ? 'Loading…' : s.name,
          onSelected: onStateChanged,
          placeholder: country == null ? 'Pick a country first' : 'Select state',
        ),
        const SizedBox(height: 10),
        SearchableSelect<CityRow>(
          label: 'City',
          items: cities,
          isLoading: citiesLoading,
          selectedItem: city,
          enabled: state != null,
          labelOf: (c) => c.name.startsWith('#') ? 'Loading…' : c.name,
          onSelected: onCityChanged,
          placeholder: state == null ? 'Pick a state first' : 'Select city',
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: pinCtl,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(20)],
          decoration: const InputDecoration(labelText: 'Postal code'),
          validator: (v) => FormValidators.postalCode(v, country: country?.name).msg,
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onErrorContainer,
              fontSize: 13.5,
            ),
          )),
        ],
      ),
    );
  }
}
