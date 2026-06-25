import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/country_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String currentEmail;
  final ValueChanged<AppUser> onUpdated;

  const PersonalInfoScreen({
    super.key,
    required this.currentEmail,
    required this.onUpdated,
  });

  @override
  State<PersonalInfoScreen> createState()=>_PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const _blue = Color(0xFF1976D2);
  final _formKey        = GlobalKey<FormState>();
  final _authService    = AuthService();
  final _countryService = CountryService();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  List<Country> _countries       = [];
  Country?      _selectedCountry;
  String        _originalEmail   = '';
  bool          _loadingUser     = true;
  bool          _loadingCountries= true;
  bool          _obscurePassword = true;
  bool          _saving          = false;
  String?       _countryError;

  @override
  void initState() {
    super.initState();
    _originalEmail = widget.currentEmail;
    _loadAll();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _authService.getUserByEmail(_originalEmail),
      _countryService.fetchCountries(),
    ]);

    if (!mounted) return;

    final user      = results[0] as AppUser?;
    final countries = results[1] as List<Country>;

    Country? matched;
    if (user != null && user.country.isNotEmpty) {
      matched = countries.cast<Country?>().firstWhere(
            (c)=>c!.name == user.country,
            orElse: ()=>null,
          );
    }

    setState(() {
      _countries        = countries;
      _loadingCountries = false;
      if (user != null) {
        _usernameCtrl.text = user.username;
        _emailCtrl.text    = user.email;
        _passwordCtrl.text = user.password;
        _selectedCountry   = matched;
      }
      _loadingUser = false;
    });
  }

  Future<void> _openCountryPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx)=>_CountryPickerSheet(
        countries: _countries,
        onSelect: (c) {
          setState(() {
            _selectedCountry = c;
            _countryError    = null;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    if (_selectedCountry == null) {
      setState(()=>_countryError = 'Please select your country');
    }
    if (!formValid || _selectedCountry == null) return;

    setState(()=>_saving = true);

    final error = await _authService.updateUser(
      currentEmail: _originalEmail,
      username:     _usernameCtrl.text.trim(),
      email:        _emailCtrl.text.trim(),
      password:     _passwordCtrl.text,
      country:      _selectedCountry!.name,
    );

    if (!mounted) return;
    setState(()=>_saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error),
              backgroundColor: Colors.red.shade600));
      return;
    }

    _originalEmail = _emailCtrl.text.trim();

    final updatedUser = AppUser(
      username: _usernameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      country:  _selectedCountry!.name,
    );
    widget.onUpdated(updatedUser);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile saved successfully.'),
        backgroundColor: Colors.green.shade600));
  }

  String? _required(String? v, String field) =>
      (v == null || v.trim().isEmpty) ? 'Please enter your $field' : null;

  String? _emailValidator(String? v) {
    final err = _required(v, 'email');
    if (err != null) return err;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim())
        ? null
        : 'Please enter a valid email address';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F7),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Personal Info',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: _blue,
                        child: Text(
                          _usernameCtrl.text.isNotEmpty
                              ? _usernameCtrl.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 32, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    
                    _card(
                      child: Column(
                        children: [
                          // Username
                          TextFormField(
                            controller: _usernameCtrl,
                            onChanged: (_)=>setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                              border: InputBorder.none,
                            ),
                            validator: (v)=>_required(v, 'username'),
                          ),
                          const Divider(height: 1),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: InputBorder.none,
                            ),
                            validator: _emailValidator,
                          ),
                          const Divider(height: 1),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: ()=>setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v)=>_required(v, 'password'),
                          ),
                          const Divider(height: 1),

                          // Country
                          GestureDetector(
                            onTap: _loadingCountries
                                ? null
                                : _openCountryPicker,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Country',
                                prefixIcon:
                                    const Icon(Icons.flag_outlined),
                                border: InputBorder.none,
                                errorText: _countryError,
                                suffixIcon: _loadingCountries
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2),
                                        ),
                                      )
                                    : const Icon(Icons.arrow_drop_down),
                              ),
                              child: Text(
                                _selectedCountry == null
                                    ? 'Select your country'
                                    : '${_selectedCountry!.name}',
                                style: TextStyle(
                                  color: _selectedCountry == null
                                      ? Colors.grey.shade600
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Save Changes',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card({required Widget child})=>Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      );
}

class _CountryPickerSheet extends StatefulWidget {
  final List<Country> countries;
  final ValueChanged<Country> onSelect;

  const _CountryPickerSheet(
      {required this.countries, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState()=>_CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late List<Country> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? widget.countries
          : widget.countries
              .where((c)=>c.name.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl)=>Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          const Text('Select Country',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search country…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No countries found.'))
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final c = _filtered[i];
                      return ListTile(
                        
                        title: Text(c.name),
                        onTap: ()=>widget.onSelect(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
