import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/country_service.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService    = AuthService();
  final _countryService = CountryService();

  bool _obscurePassword = false;
  bool _isSubmitting    = false;

  // Country picker state
  List<Country> _countries    = [];
  List<Country> _filtered     = [];
  Country?      _selectedCountry;
  bool          _loadingCountries = true;
  String?       _countryError;
  String        _searchQuery    = '';

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    try {
      final list = await _countryService.fetchCountries();
      if (mounted) {
        setState(() {
          _countries         = list;
          _filtered          = list;
          _loadingCountries  = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCountries = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not load countries. Check your connection.')),
        );
      }
    }
  }

  // ── Country search bottom sheet ────────────────────────────────────

  Future<void> _openCountryPicker() async {
    // Reset filter each time the sheet opens.
    setState(() { _filtered = _countries; _searchQuery = ''; });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _CountryPickerSheet(
        countries : _countries,
        onSelect  : (country) {
          setState(() {
            _selectedCountry = country;
            _countryError    = null;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────

  Future<void> _handleSignUp() async {
    // Validate text fields
    final formValid = _formKey.currentState!.validate();

    // Validate country separately (not inside a TextFormField)
    if (_selectedCountry == null) {
      setState(() => _countryError = 'Please select your country');
    } else {
      setState(() => _countryError = null);
    }

    if (!formValid || _selectedCountry == null) return;

    setState(() => _isSubmitting = true);

    final result = await _authService.register(
      username : _usernameController.text.trim(),
      email    : _emailController.text.trim(),
      password : _passwordController.text,
      country  : _selectedCountry!.name,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green.shade600));
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  // ── Validators ──────────────────────────────────────────────────────

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? 'Please enter your $field' : null;

  String? _emailValidator(String? value) {
    final err = _required(value, 'email');
    if (err != null) return err;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
        ? null
        : 'Please enter a valid email address';
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.person_add_alt_1,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Sign up to get started',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),

                    // ── Username ───────────────────────────────────────
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'username'),
                    ),
                    const SizedBox(height: 16),

                    // ── Email ──────────────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 16),

                    // ── Password ───────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'password'),
                    ),
                    const SizedBox(height: 16),

                    // ── Country picker ─────────────────────────────────
                    GestureDetector(
                      onTap: _loadingCountries ? null : _openCountryPicker,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Country',
                          prefixIcon: const Icon(Icons.flag_outlined),
                          errorText: _countryError,
                          suffixIcon: _loadingCountries
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _selectedCountry == null
                              ? _loadingCountries
                                  ? 'Loading countries…'
                                  : 'Select your country'
                              : '${_selectedCountry!.name}',
                          style: TextStyle(
                            color: _selectedCountry == null
                                ? Colors.grey.shade600
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Submit ─────────────────────────────────────────
                    FilledButton(
                      onPressed: _isSubmitting ? null : _handleSignUp,
                      style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign Up'),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())),
                      child:
                          const Text('Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Country picker bottom sheet ───────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final List<Country> countries;
  final ValueChanged<Country> onSelect;

  const _CountryPickerSheet(
      {required this.countries, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
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

  void _onSearch(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? widget.countries
          : widget.countries
              .where((c) =>
                  c.name.toLowerCase().contains(query.toLowerCase()))
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
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          const Text('Select Country',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Search bar
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Country list
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
                        onTap: () => widget.onSelect(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
