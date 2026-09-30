# ⚡ Windows 11 26H2 Debloater & Tactical Latency Optimizer

> **High-Performance Windows 11 26H2 System Optimizer & Debloater**  
> Engineered for gamers, low-latency audio producers, and power users.  
> **Zero-Regret Guarantee:** Every single modification creates an atomic snapshot with 1-click individual rollback, standalone Safe Mode recovery scripts, and 5-tier fallback reinstallation.

---

## 🎯 Architecture & Innovations

1. **Hardware-Level Gaming Engine (Low Jitter & Unparked Cores)**:
   - **CPU Core Unparking:** Unparks 100% of logical cores to eliminate context-switch latency and frame-time spikes.
   - **High-Resolution Kernel Timer:** Configures 0.500ms multimedia timer resolution.
   - **Ultimate Performance Plan:** Enables the unthrottled hardware power scheme.
   - **Network & MMCSS Tuning:** Disables network packet throttling (`0xFFFFFFFF`) and raises MMCSS GPU priority to 8.
   - **GPU Hardware Scheduling:** Configures Game Mode and HAGS (Hardware-Accelerated GPU Scheduling).

2. **Zero-Damage Gaming Safeguards**:
   - **Xbox & Store Preserved:** Protects Xbox Live authentication, Game Pass cloud saves, and Game Bar overlays.
   - **Bluetooth HID Preserved:** Never disables Bluetooth services required for wireless Xbox/DualSense controllers or audio headsets.
   - **DirectX & Media Subsystems:** Preserved untouched.

3. **5-Tier Application Fallback Reinstaller**:
   - If an uninstalled package needs to be restored, the engine cascades through up to 5 recovery mechanisms:
     1. Staged AppX Manifest
     2. Winget Package Manager CLI
     3. Microsoft Store Web Protocol
     4. Staged DISM Image Repository
     5. Direct Signed Microsoft CAB Payload

4. **21st.dev / shadcn-Inspired Modern Interface**:
   - **Double-Bezel Architecture:** Precision nested hardware containers with concentric corner radii and dynamic hover lighting.
   - **Micro-Animations:** Fluid entrance transitions, spring-physics button scaling, and pulsing status LEDs.
   - **Live Telemetry HUD:** Real-time kernel diagnostics, core unpark status, and RAM splitting counters.
   - **Search & Filters:** Real-time filtering by keyword and risk/category badges.

5. **Safe Dry-Run Simulation Mode**:
   - Built-in simulation flag allows full dry-run execution without modifying a single registry key, service, or package on the host.

---

## 🚀 Quick Start

### Option 1: 1-Click Launcher (Recommended)
Double-click **`start.bat`**. It will self-elevate to Administrator privileges and launch the interface.

### Option 2: PowerShell Console
Open PowerShell as Administrator:
```powershell
.\Win26H2-Debloat.ps1
```

To run in safe simulation mode (zero system changes):
```powershell
.\Win26H2-Debloat.ps1 -DryRun
```

---

## 📁 Repository Structure

```text
├── start.bat                     # 1-Click Administrator launcher
├── Win26H2-Debloat.ps1           # Main PowerShell entry point
├── README.md                     # Documentation
├── CHANGELOG.md                  # Release history
├── LICENSE                       # MIT License
├── .gitignore                    # Git ignore rules
├── config/
│   ├── apps.json                 # Removable packages catalog with risk levels
│   ├── tweaks.json               # Registry tweaks catalog with original defaults
│   ├── services.json             # Service catalog with gaming protections
│   └── gaming.json               # Gaming latency optimizations
├── gui/
│   ├── MainWindow.xaml           # Modern double-bezel WPF interface
│   └── GuiController.ps1         # Dynamic search, filter, and theme engine
├── modules/
│   ├── Core.psm1                 # Logging, restore points, and session state
│   ├── AppManager.psm1           # AppX removal and 5-tier fallback installer
│   ├── TweakEngine.psm1          # Atomic registry modification and .reg snapshots
│   ├── ServiceManager.psm1       # Service controller with gaming locks
│   ├── GamingMode.psm1           # CPU unparking, MMCSS, and timer latency
│   └── SystemInfo.psm1           # Kernel, CPU, and hardware telemetry
├── tests/
│   ├── Test-SafeDebloatMock.Tests.ps1 # Zero-mutation mock unit tests
│   └── Test-GuiElements.Tests.ps1     # XAML control and architecture tests
└── .github/
    ├── workflows/ci.yml          # GitHub Actions automated test pipeline
    ├── ISSUE_TEMPLATE/           # Bug report and feature request templates
    └── PULL_REQUEST_TEMPLATE.md  # PR verification checklist
```

---

## 🛡 Safety & Rollback Details

- **Individual Rollback:** Every card provides an immediate `[Revert]` or `[Reinstall]` button.
- **Session Rollback:** The `Rollback & Rescue` tab can revert all changes performed in the session in reverse chronological order.
- **Safe Mode Undo Script:** An executable `undo/undo_<session_id>.ps1` file is generated on launch, capable of running in Windows Safe Mode.
- **Raw Registry Backups:** Pre-change `.reg` snapshots are saved to `backups/registry/`.

---

## ⚖ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
