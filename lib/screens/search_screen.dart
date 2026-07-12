import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/property_model.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _historyKey = 'property_search_history';
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Property> _properties = <Property>[];
  List<String> _history = <String>[];
  String _query = '';
  bool _isLoading = true;

  final List<String> _popularLocations = <String>[
    'Kampala',
    'Muyenga',
    'Kololo',
    'Ntinda',
    'Kira',
    'Entebbe',
  ];

  final List<String> _suggestedSearches = <String>[
    'Apartments under 500k',
    'Houses in Kampala',
    'Land in Wakiso',
    'Short stays with parking',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Property> properties = await ApiService.getAllProperties();
    if (!mounted) return;
    setState(() {
      _properties = properties;
      _history = prefs.getStringList(_historyKey) ?? <String>[];
      _isLoading = false;
    });
  }

  List<Property> get _results {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return <Property>[];
    return _properties.where((Property property) {
      final String searchable = <String>[
        property.title,
        property.location,
        property.agent.name,
        property.agent.company ?? '',
        property.region,
        property.district ?? '',
        property.area ?? '',
        property.type.toString().split('.').last,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Future<void> _runSearch(String value) async {
    final String search = value.trim();
    if (search.isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> updated = <String>[search, ..._history.where((String item) => item != search)].take(8).toList();
    await prefs.setStringList(_historyKey, updated);
    setState(() {
      _query = search;
      _controller.text = search;
      _history = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B111E) : const Color(0xFFF6F8F7),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _buildSearchHeader(theme)),
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_query.trim().isEmpty)
              SliverToBoxAdapter(child: _buildDiscoveryContent(theme))
            else
              _buildResults(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.14)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                onChanged: (String value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search_rounded),
                  hintText: 'Search properties, locations or agents...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSearchModes(),
          const SizedBox(height: 28),
          _buildPromptGroup('Recent searches', _history, Icons.history_rounded),
          _buildPromptGroup('Popular locations', _popularLocations, Icons.location_on_outlined),
          _buildPromptGroup('Suggested searches', _suggestedSearches, Icons.auto_awesome_rounded),
        ],
      ),
    );
  }

  Widget _buildSearchModes() {
    final List<({IconData icon, String title, String subtitle})> modes = [
      (
        icon: Icons.location_on_outlined,
        title: 'Search by location',
        subtitle: 'Find homes in Kampala, Kira, Muyenga and more',
      ),
      (
        icon: Icons.home_work_outlined,
        title: 'Search by property name',
        subtitle: 'Jump straight to a known listing',
      ),
      (
        icon: Icons.support_agent_rounded,
        title: 'Search by agent or agency',
        subtitle: 'Discover listings by trusted brokers',
      ),
    ];

    return Column(
      children: modes.map((mode) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              Icon(mode.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      mode.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.58),
                          ),
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

  Widget _buildPromptGroup(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((String item) {
              return ActionChip(
                avatar: Icon(icon, size: 16),
                label: Text(item),
                onPressed: () => _runSearch(item),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final List<Property> results = _results;
    if (results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No matching properties found.',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.62)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) => PropertyCard(
            propertyId: results[index].id,
            initialProperty: results[index],
          ),
          childCount: results.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 620 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
      ),
    );
  }
}
