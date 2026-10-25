import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/supabase_service.dart';

class PostEventScreen extends StatefulWidget {
  const PostEventScreen({super.key});

  @override
  State<PostEventScreen> createState() => _PostEventScreenState();
}

class _PostEventScreenState extends State<PostEventScreen> {
  final SupabaseService _supabase = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _venuePreferenceController = TextEditingController();
  final _proposedDateController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'plays';
  String _selectedCity = 'Pune';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final List<Map<String, String>> _categories = [
    {'value': 'plays', 'label': 'नाटके (Plays)'},
    {'value': 'movies', 'label': 'चित्रपट (Movies)'},
    {'value': 'music', 'label': 'संगीत मैफल (Music)'},
    {'value': 'cultural', 'label': 'सांस्कृतिक महोत्सव (Cultural)'},
    {'value': 'comedy', 'label': 'हास्यजत्रा / Standup (Comedy)'},
  ];

  final List<String> _cities = ['Pune', 'Mumbai', 'Thane', 'Nashik', 'Nagpur', 'Kolhapur', 'Aurangabad'];

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final ok = await _supabase.submitPartnerLead({
      'organizer_name': _nameController.text.trim(),
      'company_name': _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : _nameController.text.trim(),
      'mobile': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'event_name': _eventNameController.text.trim(),
      'category': _selectedCategory,
      'city': _selectedCity,
      'venue_preference': _venuePreferenceController.text.trim(),
      'proposed_date': _proposedDateController.text.trim(),
      'expected_capacity': int.tryParse(_capacityController.text.trim()) ?? 500,
      'ticket_price_range': _priceRangeController.text.trim(),
      'website_or_social': _websiteController.text.trim(),
      'message': _messageController.text.trim(),
      'status': 'new',
    });

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (ok) _isSubmitted = true;
      });

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('माहिती पाठवताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('नोंदणी पूर्ण')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonGreen, width: 2),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.neonGreen, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'प्रस्ताव यशस्वीरीत्या नोंदवला गेला आहे!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'महाटिकिट आयोजक संबंध टीम पुढील २४ तासांत आपल्याशी संपर्क साधून नाट्यगृह नियोजन व तिकीट विक्री लाइव्ह करेल.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('मुख्य पानावर जा (Back to Home)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('आमच्याशी जोडा (Partner With Us)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('नाट्य संस्था व आयोजक नोंदणी पोर्टल', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withAlpha(40), AppColors.surface],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.theater_comedy, color: AppColors.primary, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'आपले नाटक किंवा कार्यक्रम महाटिकिटवर आणा',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '६% फ्लॅट कमिशन, रिअल-टाइम सीट मॅट्रिक्स, QR गेट पास आणि सुरक्षित पेमेंट्स.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('आयोजक तपशील (Organizer Details)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'आपले पूर्ण नाव (Contact Person Name) *',
                  hintText: 'उदा. सागर देशमुख',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'कृपया आपले नाव प्रविष्ट करा' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'नाट्य संस्था / प्रॉडक्शन हाऊस (Company / Troupe Name)',
                  hintText: 'उदा. श्री चिंतामणी थिएटर्स',
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'मोबाईल क्रमांक *',
                        hintText: '98XXXXXXXX',
                      ),
                      validator: (v) => (v == null || v.trim().length < 10) ? '१० अंकी मोबाईल नंबर टाका' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'ईमेल पत्ता *',
                        hintText: 'producer@domain.com',
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'वैध ईमेल टाका' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text('कार्यक्रमाचा तपशील (Show & Event Details)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: 'नाटकाचे / कार्यक्रमाचे नाव (Event Title) *',
                  hintText: 'उदा. सही रे सही / संगीत संशयकल्लोळ',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'कार्यक्रमाचे नाव प्रविष्ट करा' : null,
              ),
              const SizedBox(height: 12),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: AppColors.surfaceLight,
                decoration: const InputDecoration(labelText: 'प्रकार (Category)'),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c['value'], child: Text(c['label']!));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),

              // City dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                dropdownColor: AppColors.surfaceLight,
                decoration: const InputDecoration(labelText: 'शहर (City)'),
                items: _cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCity = v);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _venuePreferenceController,
                      decoration: const InputDecoration(
                        labelText: 'अपेक्षित नाट्यगृह (Venue)',
                        hintText: 'उदा. बालगंधर्व रंगमंदिर',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _proposedDateController,
                      decoration: const InputDecoration(
                        labelText: 'अपेक्षित तारीख (Dates)',
                        hintText: 'उदा. १५-२० नोव्हेंबर',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'अपेक्षित प्रेक्षक क्षमता',
                        hintText: '600',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceRangeController,
                      decoration: const InputDecoration(
                        labelText: 'तिकीट दर मर्यादा',
                        hintText: 'उदा. ₹300 - ₹600',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'वेबसाईट किंवा सोशल मीडिया लिंक',
                  hintText: 'https://instagram.com/yournatak',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'इतर विशेष सूचना किंवा मागणी (Additional Notes)',
                  hintText: 'ध्वनी व्यवस्था, व्हीआयपी पासेस, विशेष सीटिंग व्यवस्था...',
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : _submitProposal,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'प्रस्ताव सादर करा (Submit Proposal)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
