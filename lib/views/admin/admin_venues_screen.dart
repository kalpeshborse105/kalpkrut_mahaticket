import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/venue_model.dart';
import '../../data/services/supabase_service.dart';

class AdminVenuesScreen extends StatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  State<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<VenueModel> _venues = [];
  bool _isLoading = true;
  String _selectedCity = 'All';
  String _searchQuery = '';

  final List<String> _cities = ['All', 'Pune', 'Mumbai', 'Thane', 'Nashik', 'Nagpur', 'Kolhapur', 'Aurangabad'];

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    final list = await _supabase.getVenues();
    if (mounted) {
      setState(() {
        _venues = list;
        _isLoading = false;
      });
    }
  }

  List<VenueModel> get _filteredVenues {
    return _venues.where((v) {
      final matchesCity = _selectedCity == 'All' || v.city.toLowerCase() == _selectedCity.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.nameMr.contains(_searchQuery) ||
          v.address.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCity && matchesSearch;
    }).toList();
  }

  void _openAddVenueDialog() {
    final nameController = TextEditingController();
    final nameMrController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController(text: 'Pune');
    final pincodeController = TextEditingController(text: '411004');
    final capacityController = TextEditingController(text: '650');
    String ownershipType = 'public_theatre';
    bool hasAc = true;
    bool hasParking = true;
    bool hasCafeteria = true;
    bool hasWheelchair = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.theater_comedy, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'नवीन नाट्यगृह जोडा (Add Venue)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Venue Name (English)',
                        hintText: 'e.g. Bal Gandharva Ranga Mandir',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameMrController,
                      decoration: const InputDecoration(
                        labelText: 'नाट्यगृहाचे नाव (Marathi)',
                        hintText: 'उदा. बालगंधर्व रंगमंदिर',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address / पत्ता',
                        hintText: 'J.M. Road, Shivajinagar, Pune',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: const InputDecoration(labelText: 'City / शहर'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Pincode / पिनकोड'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: capacityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Capacity / क्षमता',
                              hintText: '650',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: ownershipType,
                            dropdownColor: AppColors.surfaceLight,
                            decoration: const InputDecoration(labelText: 'Ownership Type'),
                            items: const [
                              DropdownMenuItem(value: 'public_theatre', child: Text('महानगरपालिका (Public)')),
                              DropdownMenuItem(value: 'private_auditorium', child: Text('खाजगी (Private)')),
                              DropdownMenuItem(value: 'multiplex', child: Text('मल्टिप्लेक्स (Multiplex)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => ownershipType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('सुविधा (Facilities & Amenities)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Air Conditioning'),
                          selected: hasAc,
                          onSelected: (val) => setModalState(() => hasAc = val),
                          selectedColor: AppColors.primary.withAlpha(50),
                        ),
                        FilterChip(
                          label: const Text('Parking Area'),
                          selected: hasParking,
                          onSelected: (val) => setModalState(() => hasParking = val),
                          selectedColor: AppColors.primary.withAlpha(50),
                        ),
                        FilterChip(
                          label: const Text('Canteen / Cafeteria'),
                          selected: hasCafeteria,
                          onSelected: (val) => setModalState(() => hasCafeteria = val),
                          selectedColor: AppColors.primary.withAlpha(50),
                        ),
                        FilterChip(
                          label: const Text('Wheelchair Access'),
                          selected: hasWheelchair,
                          onSelected: (val) => setModalState(() => hasWheelchair = val),
                          selectedColor: AppColors.primary.withAlpha(50),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          final facilitiesList = <String>[];
                          if (hasAc) facilitiesList.add('Air Conditioning');
                          if (hasParking) facilitiesList.add('Valet Parking');
                          if (hasCafeteria) facilitiesList.add('Cafeteria');
                          if (hasWheelchair) facilitiesList.add('Wheelchair Accessible');

                          final messenger = ScaffoldMessenger.of(context);
                          final success = await _supabase.createVenue({
                            'name': nameController.text.trim(),
                            'name_mr': nameMrController.text.trim().isNotEmpty
                                ? nameMrController.text.trim()
                                : nameController.text.trim(),
                            'address': addressController.text.trim(),
                            'city': cityController.text.trim(),
                            'state': 'Maharashtra',
                            'pincode': pincodeController.text.trim(),
                            'total_capacity': int.tryParse(capacityController.text.trim()) ?? 600,
                            'ownership_type': ownershipType,
                            'has_seat_layout': 1,
                            'facilities': facilitiesList.join(', '),
                          });

                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          if (success != null) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('नाट्यगृह यशस्वीरीत्या जोडले! (Venue added successfully)')),
                            );
                            _loadVenues();
                          }
                        },
                        child: const Text('नाट्यगृह सेव्ह करा (Save Venue)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVenueDetails(VenueModel venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(venue.nameMr, style: const TextStyle(fontSize: 14, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withAlpha(100)),
                    ),
                    child: Text(
                      '${venue.totalCapacity} जागा',
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${venue.address}, ${venue.city} ${venue.pincode ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.grid_view_rounded, color: AppColors.neonGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    venue.hasSeatLayout ? 'Curved Stage Interactive Seat Topology Enabled' : 'General Admission Matrix',
                    style: const TextStyle(color: AppColors.neonGreen, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (venue.facilities != null && venue.facilities!.isNotEmpty) ...[
                const Text('सुविधा (Amenities):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(venue.facilities!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.theater_comedy, color: AppColors.primary),
                      label: const Text('Layout Preview', style: TextStyle(color: AppColors.primary)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Layout matrix for ${venue.name} active with standard Balcony & Stall.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredVenues;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('नाट्यगृह व थिएटर्स (Venues)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Maharashtra Theatre & Auditorium Directory', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVenues,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('नाट्यगृह जोडा (Add Venue)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openAddVenueDialog,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search venue by name, address...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _cities.map((city) {
                      final isSelected = _selectedCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCity = city);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Venues list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.theater_comedy, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('No venues found', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _openAddVenueDialog,
                              child: const Text('Add First Venue'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final v = list[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.white10),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showVenueDetails(v),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(30),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primary.withAlpha(80)),
                                      ),
                                      child: const Icon(Icons.theater_comedy, color: AppColors.primary, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            v.nameMr,
                                            style: const TextStyle(fontSize: 13, color: AppColors.primary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${v.address}, ${v.city}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.gold.withAlpha(30),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${v.totalCapacity} जागा',
                                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
