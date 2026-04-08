import 'package:flutter/material.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final List<String> videos;
  final String? videoTour;
  final String location;
  final PropertyType type;
  final PropertyPurpose purpose;
  final double price;
  final double appointmentFee;
  final PropertySize size;
  final List<PropertyTag> tags;
  final List<String> amenities;
  final PropertyAgent agent;
  final bool isActive;
  final bool isFeatured;
  final DateTime datePosted;
  final int views;
  final int favorites;
  final double? rating;
  final int? reviewCount;
  final Map<String, dynamic>? additionalDetails;
  final String region;
  final String district;
  final String area;

  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    this.videos = const [],
    this.videoTour,
    required this.location,
    required this.type,
    required this.purpose,
    required this.price,
    required this.appointmentFee,
    required this.size,
    required this.tags,
    required this.amenities,
    required this.agent,
    required this.isActive,
    required this.isFeatured,
    required this.datePosted,
    this.views = 0,
    this.favorites = 0,
    this.rating,
    this.reviewCount,
    this.additionalDetails,
    required this.region,
    this.district = '',
    this.area = '',
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      videoTour: json['videoTour'],
      location: json['location'] ?? '',
      type: PropertyType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['type'] ?? '').toString().toLowerCase(),
        orElse: () => PropertyType.apartment,
      ),
      purpose: PropertyPurpose.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['purpose'] ?? '').toString().toLowerCase(),
        orElse: () => PropertyPurpose.rent,
      ),
      price: (json['price'] ?? 0).toDouble(),
      appointmentFee: (json['appointmentFee'] ?? 0).toDouble(),
      size: PropertySize.fromJson(json['size'] ?? {}),
      tags: (json['tags'] as List?)?.map((tag) => PropertyTag.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == tag.toString().toLowerCase(),
            orElse: () => PropertyTag.new_,
          )).toList() ?? [],
      amenities: List<String>.from(json['amenities'] ?? []),
      agent: PropertyAgent.fromJson(json['agent'] ?? {}),
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      datePosted: json['datePosted'] != null 
          ? DateTime.parse(json['datePosted'])
          : DateTime.now(),
      views: json['views'] ?? 0,
      favorites: json['favorites'] ?? 0,
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      additionalDetails: json['additionalDetails'],
      region: json['region'] ?? 'Central',
      district: json['district'] ?? '',
      area: json['area'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'images': images,
      'videos': videos,
      'videoTour': videoTour,
      'location': location,
      'type': type.toString().split('.').last,
      'purpose': purpose.toString().split('.').last,
      'price': price,
      'appointmentFee': appointmentFee,
      'size': size.toJson(),
      'tags': tags.map((tag) => tag.toString().split('.').last).toList(),
      'amenities': amenities,
      'agent': agent.toJson(),
      'isActive': isActive,
      'isFeatured': isFeatured,
      'datePosted': datePosted.toIso8601String(),
      'views': views,
      'favorites': favorites,
      'rating': rating,
      'reviewCount': reviewCount,
      'additionalDetails': additionalDetails,
      'region': region,
      'district': district,
      'area': area,
    };
  }

  Property copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    List<String>? videos,
    String? videoTour,
    String? location,
    PropertyType? type,
    PropertyPurpose? purpose,
    double? price,
    double? appointmentFee,
    PropertySize? size,
    List<PropertyTag>? tags,
    List<String>? amenities,
    PropertyAgent? agent,
    bool? isActive,
    bool? isFeatured,
    DateTime? datePosted,
    int? views,
    int? favorites,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? additionalDetails,
    String? region,
    String? district,
    String? area,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      videoTour: videoTour ?? this.videoTour,
      location: location ?? this.location,
      type: type ?? this.type,
      purpose: purpose ?? this.purpose,
      price: price ?? this.price,
      appointmentFee: appointmentFee ?? this.appointmentFee,
      size: size ?? this.size,
      tags: tags ?? List<PropertyTag>.from(this.tags),
      amenities: amenities ?? this.amenities,
      agent: agent ?? this.agent,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      datePosted: datePosted ?? this.datePosted,
      views: views ?? this.views,
      favorites: favorites ?? this.favorites,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      region: region ?? this.region,
      district: district ?? this.district,
      area: area ?? this.area,
    );
  }
}

enum PropertyType {
  apartment,
  house,
  villa,
  commercial,
  land,
  studio,
}

enum PropertyPurpose {
  rent,
  sale,
  shortStay,
}

enum PropertyTag {
  new_,
  popular,
  luxury,
  pool,
  garden,
  security,
  modern,
  central,
  furnished,
  commercial,
  office,
  retail,
  family,
  beachAccess,
  studio
}

class PropertySize {
  final double totalArea;
  final int? bedrooms;
  final int? bathrooms;
  final int? parking;
  final String? dimensions;

  const PropertySize({
    required this.totalArea,
    this.bedrooms,
    this.bathrooms,
    this.parking,
    this.dimensions,
  });

  factory PropertySize.fromJson(Map<String, dynamic> json) {
    return PropertySize(
      totalArea: (json['totalArea'] ?? json['area'] ?? 0).toDouble(),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      parking: json['parking'],
      dimensions: json['dimensions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalArea': totalArea,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'parking': parking,
      'dimensions': dimensions,
    };
  }
}

class PropertyAgent {
  final String name;
  final String phone;
  final String email;
  final String photo;
  final String? company;
  final String? position;

  const PropertyAgent({
    required this.name,
    required this.phone,
    required this.email,
    required this.photo,
    this.company,
    this.position,
  });

  factory PropertyAgent.fromJson(Map<String, dynamic> json) {
    return PropertyAgent(
      name: json['name'] ?? 'Unknown Agent',
      phone: json['phone'] ?? '+256 000 000000',
      email: json['email'] ?? 'agent@realestate.ug',
      photo: json['photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      company: json['company'],
      position: json['position'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'photo': photo,
      'company': company,
      'position': position,
    };
  }
} 