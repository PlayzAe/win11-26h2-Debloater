# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-30

### Added
- **21st.dev / shadcn-Inspired Modern GUI**: Double-bezel hardware nested card architecture, fluid wake-up entrance animations, live HUD telemetry bento grid, and pulsing radar LEDs.
- **Hardware-Level Gaming Engine**:
  - Full CPU core unparking (0% parked floor across all logical cores).
  - High-precision multimedia timer configuration (0.500ms).
  - MMCSS GPU priority 8 and network packet throttling elimination (`0xFFFFFFFF`).
  - SvcHost splitting threshold optimization (`0x380000`).
- **Zero-Damage Gaming Guard**: Explicit locks preserving Xbox Game Pass authentication, cloud saves, Bluetooth wireless controllers, and audio engines.
- **5-Tier Package Reinstall Pipeline**: Multi-layer fallback engine (Staged AppX -> Winget CLI -> MS Store Protocol -> DISM Staged -> Direct CAB download).
- **Atomic Rollback Engine**: Every registry modification, service adjustment, and package removal generates a timestamped `.reg` or `.ps1` undo script.
- **Live Search & Filter Engine**: Instant filtering across Apps and Tweaks by keyword and risk/category pills.
- **Zero-Mutation Mock Test Suite**: Automated verification scripts ensuring every module can be tested safely without changing host machine state.
- **CI/CD Quality Gates**: Automated GitHub Actions workflow running syntax verification, rule audits, and unit tests on Windows Server runners.
