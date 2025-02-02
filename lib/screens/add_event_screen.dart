import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../animated/animated_dropdown.dart';
import '../animated/animated_text_field.dart';
import '../constant/form_constant.dart';
import '../widgets/data_selector.dart';
import '../constant/entities.dart';
import '../services/event_service.dart';
import '../widgets/time_selector.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({Key? key}) : super(key: key);

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PageController _pageController;
  int _currentStep = 0;

  String? _eventName;
  String? _eventType;
  String? _description;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _location;
  String? _contactPhone;
  String? _organizationInfo;
  TimeOfDay? _startTime;
  String? _selectedImagePath;

  static const formSections = [
    {
      'title': 'Etkinlik Bilgileri',
      'description': 'Etkinlik hakkında temel bilgileri girin.',
      'icon': Icons.title,
    },
    {
      'title': 'Tarih Bilgileri',
      'description': 'Etkinlik tarihlerini girin.',
      'icon': Icons.date_range,
    },
    {
      'title': 'Konum Bilgileri',
      'description': 'Etkinlik konumunu girin.',
      'icon': Icons.location_on,
    },
    {
      'title': 'İletişim Bilgileri',
      'description': 'Organizasyon ve iletişim detaylarını girin.',
      'icon': Icons.contact_phone,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose(); // Sayfa denetleyicisini temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: barColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  formSections[_currentStep]['title'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    formSections[_currentStep]['icon'] as IconData?,
                    size: 80,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Column(
                  children: [
                    _buildProgressBar(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        formSections[_currentStep]['description'] as String,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          _formKey.currentState?.save();
                          setState(() => _currentStep = index);
                        },
                        children: [
                          _buildBasicInfoSection(),
                          _buildDateTimeSection(),
                          _buildLocationSection(),
                          _buildAdditionalSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(
        formSections.length,
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: _currentStep >= index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final barColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);

    return BottomAppBar(
      color: barColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              ElevatedButton.icon(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary),
                label: Text('Geri',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            if (_currentStep < formSections.length - 1)
              ElevatedButton.icon(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: Icon(Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.onPrimary),
                label: Text('İleri',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            if (_currentStep == formSections.length - 1)
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary),
                label: Text('Tamamla',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildImageSelector(),
          const SizedBox(height: 16),
          AnimatedTextField(
            label: "Etkinlik Adı",
            icon: Icons.title,
            initialValue: _eventName,
            onSaved: (value) => _eventName = value,
            onChanged: (value) => _eventName = value,
            validator: (value) => value == null || value.isEmpty
                ? "Etkinlik adı gereklidir"
                : null,
          ),
          const SizedBox(height: 16),
          AnimatedDropdown(
            label: "Etkinlik Türü",
            icon: Icons.category,
            items: FormConstants.eventTypes,
            onChanged: (value) => setState(() => _eventType = value),
            validator: (value) =>
                value == null ? "Etkinlik türü seçiniz" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DateSelector(
            label: "Etkinlik Tarihi",
            initialDate: _startDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateSelected: (date) => setState(() => _startDate = date),
          ),
          const SizedBox(height: 16),
          TimeSelector(
            label: "Etkinlik Saati",
            initialTime: _startTime,
            onTimeSelected: (time) => setState(() => _startTime = time),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AnimatedTextField(
            label: "Konum",
            icon: Icons.location_on,
            onSaved: (value) => _location = value,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AnimatedTextField(
            label: "Ek Bilgiler",
            icon: Icons.note,
            maxLines: 4,
            initialValue: _description,
            onSaved: (value) => _description = value,
            onChanged: (value) => _description = value,
          ),
          const SizedBox(height: 16),
          AnimatedTextField(
            label: "İletişim Telefonu",
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            initialValue: _contactPhone,
            onSaved: (value) => _contactPhone = value,
            onChanged: (value) => _contactPhone = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Telefon numarası gereklidir";
              }
              if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                return "Geçerli bir telefon numarası giriniz";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AnimatedTextField(
            label: "Organizasyon Bilgileri",
            icon: Icons.business,
            maxLines: 3,
            onSaved: (value) => _organizationInfo = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Organizasyon bilgileri gereklidir";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _selectedImagePath == null
            ? Center(
                child: Text(
                  'Resim Seçin',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : Image.file(
                File(_selectedImagePath!),
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final now = DateTime.now();
      final selectedDateTime = _combineDateTime(_startDate!, _startTime!);

      if (selectedDateTime.isBefore(now)) {
        _showErrorSnackBar('Geçmiş tarihli etkinlik oluşturulamaz');
        return;
      }

      if (_eventName == null || _eventName!.isEmpty) {
        _showErrorSnackBar('Lütfen etkinlik adını girin');
        return;
      }

      if (_eventType == null) {
        _showErrorSnackBar('Lütfen etkinlik türünü seçin');
        return;
      }

      if (_startDate == null) {
        _showErrorSnackBar('Lütfen etkinlik tarihini seçin');
        return;
      }

      if (_startTime == null) {
        _showErrorSnackBar('Lütfen etkinlik saatini seçin');
        return;
      }

      if (_location == null || _location!.isEmpty) {
        _showErrorSnackBar('Lütfen konum bilgisini girin');
        return;
      }

      final event = Event(
        id: DateTime.now().toString(),
        title: _eventName!,
        description: _description ?? '',
        date: _startDate!,
        time:
            '${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}',
        location: _location!,
        category: _eventType!,
        imageUrl: _selectedImagePath ?? '',
        organizerId: "current_user_id",
        createdAt: DateTime.now(),
        contactPhone: _contactPhone ?? '',
        organizationInfo: _organizationInfo ?? '',
      );

      EventService().addEvent(event);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Etkinlik başarıyla oluşturuldu!',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
