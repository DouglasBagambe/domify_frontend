import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/property_model.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    await Future.delayed(Duration(milliseconds: 1500));
    setState(() {
      _isAdmin = true;
      _isLoading = false;
    });
    _animationController.forward();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildPropertiesTab() {
    return FutureBuilder<List<Property>>(
      future: ApiService().getProperties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        } else {
          return _buildPropertiesGrid(snapshot.data!);
        }
      },
    );
  }

  Widget _buildPropertiesGrid(List<Property> properties) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF533483).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _editProperty(property),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: property.isFeatured ? Color(0xFFe94560) : Color(0xFF533483),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                property.isFeatured ? 'FEATURED' : 'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton(
                              icon: Icon(Icons.more_vert, color: Colors.white70),
                              color: Color(0xFF1a1a2e),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Color(0xFF533483), size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  onTap: () => Future.delayed(Duration.zero, () => _editProperty(property)),
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Color(0xFFe94560), size: 18),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  onTap: () => Future.delayed(Duration.zero, () => _deleteProperty(property.id)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Color(0xFF533483), size: 14),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.location,
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${property.price} UGX',
                                      style: TextStyle(
                                        color: Color(0xFFe94560),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return FutureBuilder<List<Property>>(
      future: ApiService().getProperties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyAppointments();
        } else {
          return _buildAppointmentsList(snapshot.data!);
        }
      },
    );
  }

  Widget _buildAppointmentsList(List<Property> properties) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF533483).withOpacity(0.2),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.all(16),
              childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF533483), Color(0xFFe94560)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home, color: Colors.white),
              ),
              title: Text(
                property.title,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                property.location,
                style: TextStyle(color: Colors.white70),
              ),
              iconColor: Color(0xFF533483),
              collapsedIconColor: Color(0xFF533483),
              children: [
                FutureBuilder<List<dynamic>>(
                  future: ApiService.getAppointmentsForProperty(property.id),
                  builder: (context, apptSnapshot) {
                    if (apptSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 60,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF533483)),
                          ),
                        ),
                      );
                    } else if (apptSnapshot.hasError) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Error loading appointments',
                          style: TextStyle(color: Color(0xFFe94560)),
                        ),
                      );
                    } else if (!apptSnapshot.hasData || apptSnapshot.data!.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No appointments scheduled',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    } else {
                      return Column(
                        children: apptSnapshot.data!.map((appt) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF533483),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appt['name'],
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${appt['appointmentTime']} • ${appt['purpose']}',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF533483)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Color(0xFFe94560), size: 80),
          SizedBox(height: 16),
          Text('Something went wrong', style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(height: 8),
          Text(error, style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, color: Color(0xFF533483), size: 80),
          SizedBox(height: 16),
          Text('No Properties Yet', style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(height: 8),
          Text('Add your first property to get started', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, color: Color(0xFF533483), size: 80),
          SizedBox(height: 16),
          Text('No Appointments', style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(height: 8),
          Text('Appointments will appear here', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  void _addProperty() {
    showDialog(
      context: context,
      builder: (context) => AddPropertyDialog(
        onSave: (propertyData) async {
          try {
            await ApiService.addProperty(propertyData: propertyData);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Property added successfully'),
                backgroundColor: Color(0xFF533483),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding property: $e'),
                backgroundColor: Color(0xFFe94560),
              ),
            );
          }
        },
      ),
    );
  }

  void _editProperty(Property property) {
    showDialog(
      context: context,
      builder: (context) => EditPropertyDialog(
        property: property,
        onSave: (id, propertyData) async {
          try {
            await ApiService.updateProperty(id: id, propertyData: propertyData);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Property updated successfully'),
                backgroundColor: Color(0xFF533483),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating property: $e'),
                backgroundColor: Color(0xFFe94560),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteProperty(String id) async {
    try {
      await ApiService.deleteProperty(id);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property deleted successfully'),
          backgroundColor: Color(0xFF533483),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting property: $e'),
          backgroundColor: Color(0xFFe94560),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF0f0f23),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF533483), Color(0xFFe94560)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF533483)),
              ),
              SizedBox(height: 16),
              Text('Loading Admin Dashboard...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Color(0xFF0f0f23),
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Color(0xFFe94560), size: 80),
                SizedBox(height: 24),
                Text('Access Denied', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 12),
                Text('You do not have permission to access the admin dashboard.', 
                     style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF533483),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Go Back', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0f0f23),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1a2e),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF533483), Color(0xFFe94560)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text('WarlNest Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_selectedIndex == 0)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: FloatingActionButton.extended(
                onPressed: _addProperty,
                backgroundColor: Color(0xFFe94560),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('Add Property', style: TextStyle(color: Colors.white)),
                elevation: 8,
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildNavigationToggle(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildPropertiesTab(),
                  _buildAppointmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildNavigationToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05) 
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              icon: Icons.home_outlined,
              label: 'Properties',
              isSelected: _selectedIndex == 0,
              isDark: isDark,
              onPressed: () => _onItemTapped(0),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              icon: Icons.calendar_today_outlined,
              label: 'Appointments',
              isSelected: _selectedIndex == 1,
              isDark: isDark,
              onPressed: () => _onItemTapped(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                      : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact Add Property Dialog
class AddPropertyDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  const AddPropertyDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  _AddPropertyDialogState createState() => _AddPropertyDialogState();
}

class _AddPropertyDialogState extends State<AddPropertyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _isActive = true, _isFeatured = false;

  @override
  void initState() {
    super.initState();
    ['title', 'description', 'location', 'type', 'purpose', 'price', 'appointmentFee', 
     'bedrooms', 'bathrooms', 'dimensions', 'tags', 'amenities', 'images', 'videos', 'videoTour'].forEach((field) {
      _controllers[field] = TextEditingController();
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Widget _buildTextField(String key, String label, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF533483)),
          ),
        ),
        style: TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add New Property', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField('title', 'Title'),
                      _buildTextField('description', 'Description', maxLines: 3),
                      _buildTextField('location', 'Location'),
                      _buildTextField('type', 'Type (e.g., Apartment)'),
                      _buildTextField('purpose', 'Purpose (e.g., Rent)'),
                      _buildTextField('price', 'Price (UGX)', keyboardType: TextInputType.number),
                      _buildTextField('appointmentFee', 'Appointment Fee (UGX)', keyboardType: TextInputType.number),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('bedrooms', 'Bedrooms', keyboardType: TextInputType.number)),
                          SizedBox(width: 16),
                          Expanded(child: _buildTextField('bathrooms', 'Bathrooms', keyboardType: TextInputType.number)),
                        ],
                      ),
                      _buildTextField('dimensions', 'Dimensions (e.g., 100 sqm)'),
                      _buildTextField('tags', 'Tags (comma separated)'),
                      _buildTextField('amenities', 'Amenities (comma separated)'),
                      _buildTextField('images', 'Images (comma separated URLs)'),
                      _buildTextField('videos', 'Videos (comma separated URLs)'),
                      _buildTextField('videoTour', 'Video Tour URL'),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: Text('Active', style: TextStyle(color: Colors.white)),
                              value: _isActive,
                              onChanged: (value) => setState(() => _isActive = value),
                              activeColor: Color(0xFF533483),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: Text('Featured', style: TextStyle(color: Colors.white)),
                              value: _isFeatured,
                              onChanged: (value) => setState(() => _isFeatured = value),
                              activeColor: Color(0xFFe94560),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final propertyData = {
                          'title': _controllers['title']!.text,
                          'description': _controllers['description']!.text,
                          'location': _controllers['location']!.text,
                          'type': _controllers['type']!.text,
                          'purpose': _controllers['purpose']!.text,
                          'price': double.parse(_controllers['price']!.text),
                          'appointmentFee': double.parse(_controllers['appointmentFee']!.text),
                          'size': {
                            'bedrooms': int.parse(_controllers['bedrooms']!.text),
                            'bathrooms': int.parse(_controllers['bathrooms']!.text),
                            'dimensions': _controllers['dimensions']!.text,
                          },
                          'tags': _controllers['tags']!.text.split(',').map((tag) => tag.trim()).toList(),
                          'amenities': _controllers['amenities']!.text.split(',').map((amenity) => amenity.trim()).toList(),
                          'isActive': _isActive,
                          'isFeatured': _isFeatured,
                          'images': _controllers['images']!.text.split(',').map((url) => url.trim()).toList(),
                          'videos': _controllers['videos']!.text.split(',').map((url) => url.trim()).toList(),
                          'videoTour': _controllers['videoTour']!.text,
                          'agent': {
                            'name': 'Admin Agent',
                            'role': 'Administrator',
                            'photo': '',
                            'phone': '+256123456789',
                            'email': 'admin@rentapp.com',
                          },
                        };
                        widget.onSave(propertyData);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF533483),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Compact Edit Property Dialog
class EditPropertyDialog extends StatefulWidget {
  final Property property;
  final Function(String, Map<String, dynamic>) onSave;
  const EditPropertyDialog({Key? key, required this.property, required this.onSave}) : super(key: key);

  @override
  _EditPropertyDialogState createState() => _EditPropertyDialogState();
}

class _EditPropertyDialogState extends State<EditPropertyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late bool _isActive, _isFeatured;

  @override
  void initState() {
    super.initState();
    _controllers['title'] = TextEditingController(text: widget.property.title);
    _controllers['description'] = TextEditingController(text: widget.property.description);
    _controllers['location'] = TextEditingController(text: widget.property.location);
    _controllers['type'] = TextEditingController(text: widget.property.type.toString().split('.').last);
    _controllers['purpose'] = TextEditingController(text: widget.property.purpose.toString().split('.').last);
    _controllers['price'] = TextEditingController(text: widget.property.price.toString());
    _controllers['appointmentFee'] = TextEditingController(text: widget.property.appointmentFee.toString());
    _controllers['bedrooms'] = TextEditingController(text: widget.property.size.bedrooms?.toString() ?? '0');
    _controllers['bathrooms'] = TextEditingController(text: widget.property.size.bathrooms?.toString() ?? '0');
    _controllers['dimensions'] = TextEditingController(text: widget.property.size.dimensions ?? '');
    _controllers['tags'] = TextEditingController(text: widget.property.tags.join(', '));
    _controllers['amenities'] = TextEditingController(text: widget.property.amenities.join(', '));
    _controllers['images'] = TextEditingController(text: widget.property.images.join(', '));
    _controllers['videos'] = TextEditingController(text: widget.property.videos.join(', '));
    _controllers['videoTour'] = TextEditingController(text: widget.property.videoTour ?? '');
    _isActive = widget.property.isActive;
    _isFeatured = widget.property.isFeatured;
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Widget _buildTextField(String key, String label, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF533483)),
          ),
        ),
        style: TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Property', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField('title', 'Title'),
                      _buildTextField('description', 'Description', maxLines: 3),
                      _buildTextField('location', 'Location'),
                      _buildTextField('type', 'Type (e.g., Apartment)'),
                      _buildTextField('purpose', 'Purpose (e.g., Rent)'),
                      _buildTextField('price', 'Price (UGX)', keyboardType: TextInputType.number),
                      _buildTextField('appointmentFee', 'Appointment Fee (UGX)', keyboardType: TextInputType.number),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('bedrooms', 'Bedrooms', keyboardType: TextInputType.number)),
                          SizedBox(width: 16),
                          Expanded(child: _buildTextField('bathrooms', 'Bathrooms', keyboardType: TextInputType.number)),
                        ],
                      ),
                      _buildTextField('dimensions', 'Dimensions (e.g., 100 sqm)'),
                      _buildTextField('tags', 'Tags (comma separated)'),
                      _buildTextField('amenities', 'Amenities (comma separated)'),
                      _buildTextField('images', 'Images (comma separated URLs)'),
                      _buildTextField('videos', 'Videos (comma separated URLs)'),
                      _buildTextField('videoTour', 'Video Tour URL'),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: Text('Active', style: TextStyle(color: Colors.white)),
                              value: _isActive,
                              onChanged: (value) => setState(() => _isActive = value),
                              activeColor: Color(0xFF533483),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: Text('Featured', style: TextStyle(color: Colors.white)),
                              value: _isFeatured,
                              onChanged: (value) => setState(() => _isFeatured = value),
                              activeColor: Color(0xFFe94560),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final propertyData = {
                          'title': _controllers['title']!.text,
                          'description': _controllers['description']!.text,
                          'location': _controllers['location']!.text,
                          'type': _controllers['type']!.text,
                          'purpose': _controllers['purpose']!.text,
                          'price': double.parse(_controllers['price']!.text),
                          'appointmentFee': double.parse(_controllers['appointmentFee']!.text),
                          'size': {
                            'bedrooms': int.parse(_controllers['bedrooms']!.text),
                            'bathrooms': int.parse(_controllers['bathrooms']!.text),
                            'dimensions': _controllers['dimensions']!.text,
                          },
                          'tags': _controllers['tags']!.text.split(',').map((tag) => tag.trim()).toList(),
                          'amenities': _controllers['amenities']!.text.split(',').map((amenity) => amenity.trim()).toList(),
                          'isActive': _isActive,
                          'isFeatured': _isFeatured,
                          'images': _controllers['images']!.text.split(',').map((url) => url.trim()).toList(),
                          'videos': _controllers['videos']!.text.split(',').map((url) => url.trim()).toList(),
                          'videoTour': _controllers['videoTour']!.text,
                        };
                        widget.onSave(widget.property.id, propertyData);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF533483),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
