# Docker Image Downloader

A Windows desktop Flutter application that downloads Docker container images directly from
Docker Hub **without requiring Docker to be installed**. Replicates Moby's
`download-frozen-image-v2.sh` as a native Dart implementation with a polished Material 3 GUI.

## Features

- Pull public images from Docker Hub by name (e.g. `alpine:latest`)
- Supports multi-arch manifest lists — auto-selects `amd64`/`linux`
- Produces a `docker save`-compatible folder structure (`manifest.json`, `repositories`,
  per-layer folders with `VERSION`, `json`, `layer.tar`)
- Optional `.tar` packaging with `docker load` compatibility
- SHA-256 digest verification on every downloaded blob
- Resume partially-downloaded layers
- Dark/light theme support

## Prerequisites

- **Flutter SDK** ≥ 3.10 (stable channel)
- **Windows toolchain**: Visual Studio 2022 with "Desktop development with C++" workload
  (required for `flutter build windows`)

## How to run

```bash
flutter pub get
flutter run -d windows
```

## How to build a release executable

```bash
flutter build windows --release
```

The output exe will be at `build/windows/x64/runner/Release/dockerless_image_downloader.exe`.

## Usage

1. Enter an image reference (e.g. `alpine:latest`, `library/nginx:1.25`, `yourname/app:v1`)
2. Select an output folder using the Browse button
3. Click **Download** — the app will authenticate, fetch the manifest, and stream each layer
4. Once complete, click **Package as .tar** to bundle into a single file loadable via
   `docker load -i <file>.tar`

## Known limitations (v1)

- **Docker Hub only** — no support for GHCR, Quay, or private registries
- **amd64 only** — ARM images are not downloaded (structure supports easy extension)
- **Public images only** — no private registry authentication
- **Windows host only** — the app targets Windows desktop; no Android/iOS/web support
- **Schema v1 manifests** — not supported; displays a clear error if encountered

## Architecture

```
lib/
  main.dart                     # App entry point + theming
  models/
    manifest.dart               # Manifest data classes (single, list, legacy)
    download_progress.dart      # Progress/state models
  services/
    registry_service.dart       # Auth token, manifest fetch, blob download
    image_builder.dart           # Docker-save folder structure writer
    tar_packager.dart            # .tar packaging via archive package
  state/
    download_controller.dart     # ChangeNotifier driving the UI
  ui/
    home_page.dart              # Main screen assembly
    widgets/
      image_input_card.dart     # Input form (image ref, folder picker, download button)
      layer_progress_tile.dart  # Per-layer progress card
      log_console.dart          # Collapsible monospace log
      result_banner.dart        # Success result + actions
  utils/
    layer_id.dart               # Synthetic legacy layer ID chaining
    byte_format.dart            # Human-readable byte formatting
```

## Testing / correctness

Compare output against Moby's `download-frozen-image-v2.sh`:

```bash
# Download via bash script (requires Docker or direct curl)
./download-frozen-image-v2.sh /tmp/bash-output alpine:latest

# Download via this app → --- select output as /tmp/app-output

# Compare
diff -r /tmp/bash-output /tmp/app-output
```

Recommended test images:
- `hello-world:latest` — minimal layers, fast
- `alpine:latest` — small, multi-arch manifest list
- `debian:latest` — larger layers, tests progress + resume

## Reference

Moby's original bash script:
https://github.com/moby/moby/blob/master/contrib/download-frozen-image-v2.sh
