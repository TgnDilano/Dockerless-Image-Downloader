class BlobDescriptor {
  final String digest;
  final int size;
  final String mediaType;
  final Map<String, dynamic>? annotations;

  BlobDescriptor({
    required this.digest,
    required this.size,
    required this.mediaType,
    this.annotations,
  });

  factory BlobDescriptor.fromJson(Map<String, dynamic> json) {
    return BlobDescriptor(
      digest: json['digest'] as String,
      size: json['size'] as int,
      mediaType: json['mediaType'] as String? ?? '',
      annotations: json['annotations'] as Map<String, dynamic>?,
    );
  }
}

class PlatformDescriptor {
  final String architecture;
  final String os;
  final String? variant;

  PlatformDescriptor({
    required this.architecture,
    required this.os,
    this.variant,
  });

  factory PlatformDescriptor.fromJson(Map<String, dynamic> json) {
    return PlatformDescriptor(
      architecture: json['architecture'] as String,
      os: json['os'] as String,
      variant: json['variant'] as String?,
    );
  }
}

class ManifestDescriptor {
  final String digest;
  final int size;
  final String mediaType;
  final PlatformDescriptor platform;

  ManifestDescriptor({
    required this.digest,
    required this.size,
    required this.mediaType,
    required this.platform,
  });

  factory ManifestDescriptor.fromJson(Map<String, dynamic> json) {
    return ManifestDescriptor(
      digest: json['digest'] as String,
      size: json['size'] as int,
      mediaType: json['mediaType'] as String,
      platform: PlatformDescriptor.fromJson(json['platform'] as Map<String, dynamic>),
    );
  }
}

class SingleManifest {
  final int schemaVersion;
  final String mediaType;
  final BlobDescriptor config;
  final List<BlobDescriptor> layers;
  final Map<String, dynamic>? raw;

  SingleManifest({
    required this.schemaVersion,
    required this.mediaType,
    required this.config,
    required this.layers,
    this.raw,
  });

  factory SingleManifest.fromJson(Map<String, dynamic> json) {
    final layersList = (json['layers'] as List<dynamic>)
        .map((e) => BlobDescriptor.fromJson(e as Map<String, dynamic>))
        .toList();
    return SingleManifest(
      schemaVersion: json['schemaVersion'] as int,
      mediaType: json['mediaType'] as String? ?? '',
      config: BlobDescriptor.fromJson(json['config'] as Map<String, dynamic>),
      layers: layersList,
      raw: json,
    );
  }
}

class ManifestList {
  final int schemaVersion;
  final String mediaType;
  final List<ManifestDescriptor> manifests;
  final Map<String, dynamic>? raw;

  ManifestList({
    required this.schemaVersion,
    required this.mediaType,
    required this.manifests,
    this.raw,
  });

  factory ManifestList.fromJson(Map<String, dynamic> json) {
    final manifestsList = (json['manifests'] as List<dynamic>)
        .map((e) => ManifestDescriptor.fromJson(e as Map<String, dynamic>))
        .toList();
    return ManifestList(
      schemaVersion: json['schemaVersion'] as int,
      mediaType: json['mediaType'] as String? ?? '',
      manifests: manifestsList,
      raw: json,
    );
  }

  ManifestDescriptor? findAmd64() {
    for (final m in manifests) {
      if (m.platform.architecture == 'amd64' &&
          m.platform.os == 'linux' &&
          (m.platform.variant == null || m.platform.variant!.isEmpty)) {
        return m;
      }
    }
    for (final m in manifests) {
      if (m.platform.architecture == 'amd64' && m.platform.os == 'linux') {
        return m;
      }
    }
    return null;
  }
}

class LegacyV1Manifest {
  final Map<String, dynamic> raw;

  LegacyV1Manifest({required this.raw});

  factory LegacyV1Manifest.fromJson(Map<String, dynamic> json) {
    return LegacyV1Manifest(raw: json);
  }
}

sealed class RegistryManifest {}

class SingleRegistryManifest extends RegistryManifest {
  final SingleManifest manifest;
  SingleRegistryManifest(this.manifest);
}

class ListRegistryManifest extends RegistryManifest {
  final ManifestList manifest;
  ListRegistryManifest(this.manifest);
}

class LegacyRegistryManifest extends RegistryManifest {
  final LegacyV1Manifest manifest;
  LegacyRegistryManifest(this.manifest);
}

class ManifestEntry {
  final String config;
  final List<String> repoTags;
  final List<String> layers;

  ManifestEntry({
    required this.config,
    required this.repoTags,
    required this.layers,
  });

  Map<String, dynamic> toJson() => {
        'Config': config,
        'RepoTags': repoTags,
        'Layers': layers,
      };
}
