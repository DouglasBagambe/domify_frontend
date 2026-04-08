import 'package:flutter/material.dart';
import '../models/property_model.dart';

class PropertyTags extends StatelessWidget {
  final List<PropertyTag> tags;

  const PropertyTags({
    Key? key,
    required this.tags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => _buildTag(context, tag)).toList(),
    );
  }

  Widget _buildTag(BuildContext context, PropertyTag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTagColor(context, tag).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getTagLabel(tag),
        style: TextStyle(
          color: _getTagColor(context, tag),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getTagLabel(PropertyTag tag) {
    switch (tag) {
      case PropertyTag.new_:
        return 'New';
      case PropertyTag.popular:
        return 'Popular';
      case PropertyTag.luxury:
        return 'Luxury';
      case PropertyTag.pool:
        return 'Pool';
      case PropertyTag.garden:
        return 'Garden';
      case PropertyTag.security:
        return 'Security';
      case PropertyTag.modern:
        return 'Modern';
      case PropertyTag.central:
        return 'Central';
      case PropertyTag.furnished:
        return 'Furnished';
      case PropertyTag.commercial:
        return 'Commercial';
      case PropertyTag.office:
        return 'Office';
      case PropertyTag.retail:
        return 'Retail';
      case PropertyTag.family:
        return 'Family';
      case PropertyTag.beachAccess:
        return 'Beach Access';
      case PropertyTag.studio:
        return 'Studio';
    }
  }

  Color _getTagColor(BuildContext context, PropertyTag tag) {
    switch (tag) {
      case PropertyTag.new_:
        return Colors.blue;
      case PropertyTag.popular:
        return Colors.orange;
      case PropertyTag.luxury:
        return Colors.purple;
      case PropertyTag.pool:
        return Colors.cyan;
      case PropertyTag.garden:
        return Colors.green;
      case PropertyTag.security:
        return Colors.red;
      case PropertyTag.modern:
        return Colors.indigo;
      case PropertyTag.central:
        return Colors.amber;
      case PropertyTag.furnished:
        return Colors.teal;
      case PropertyTag.commercial:
        return Colors.brown;
      case PropertyTag.office:
        return Colors.blueGrey;
      case PropertyTag.retail:
        return Colors.deepOrange;
      case PropertyTag.family:
        return Colors.pink;
      case PropertyTag.beachAccess:
        return Colors.lightBlue;
      case PropertyTag.studio:
        return Colors.deepPurple;
    }
  }
} 