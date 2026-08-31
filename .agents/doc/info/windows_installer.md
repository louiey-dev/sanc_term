# Windows Installer

## Installer Tool

This project uses [Inno Setup 6](https://jrsoftware.org/isinfo.php) to create the
Windows installer. It does not use Flexera InstallShield.

The installer compiler is `ISCC.exe`. The repository wraps it with a PowerShell
build script so that the Flutter application, version information, Visual C++
runtime, and optional code signing are handled consistently.

## Prerequisites

Install the following on the Windows build computer:

- Flutter with Windows desktop support
- Visual Studio with the **Desktop development with C++** workload
- Inno Setup 6
- Windows SDK `signtool.exe` only when signing a release

The patched `../xterm.dart` dependency must also exist next to this repository.

## Important Locations

| Purpose | Location |
| --- | --- |
| Installer definition | `installer/sanc_term.iss` |
| Installer build script | `scripts/build_windows_installer.ps1` |
| Flutter release files | `build/windows/x64/runner/Release/` |
| Downloaded VC++ redistributable cache | `installer/cache/vc_redist.x64.exe` |
| Generated installer | `dist/sanc_term_setup_<version>.exe` |

Inno Setup itself is commonly installed in one of these locations:

```text
C:\Users\<user>\AppData\Local\Programs\Inno Setup 6\ISCC.exe
C:\Program Files (x86)\Inno Setup 6\ISCC.exe
C:\Program Files\Inno Setup 6\ISCC.exe
```

The build script automatically searches `PATH` and the two `Program Files`
locations. For a per-user installation under `AppData`, pass the path with
`-InnoCompilerPath`.

## Build the Installer

From the repository root, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  .\scripts\build_windows_installer.ps1
```

This command:

1. Reads the version and build number from `pubspec.yaml`.
2. runs `flutter build windows --release`;
3. downloads the Microsoft Visual C++ 2015-2022 x64 Redistributable when it is
   not already cached;
4. compiles `installer/sanc_term.iss`; and
5. writes `dist/sanc_term_setup_<version>.exe`.

If Inno Setup is installed for only the current user, specify `ISCC.exe`:

```powershell
.\scripts\build_windows_installer.ps1 `
  -InnoCompilerPath "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
```

To package an existing Flutter release without rebuilding it:

```powershell
.\scripts\build_windows_installer.ps1 -SkipFlutterBuild `
  -InnoCompilerPath "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
```

Use `-SkipFlutterBuild` only when
`build/windows/x64/runner/Release/sanc_term.exe` and its `data` directory are
already current.

## Configuration

### Application Version

Set the release version in `pubspec.yaml`:

```yaml
version: 0.1.0+1
```

The script converts this to:

- installer name: `sanc_term_setup_0.1.0.exe`;
- display version: `0.1.0`; and
- Windows four-part file version: `0.1.0.1`.

The version name must contain exactly three numeric parts, such as `1.2.3`.

### Inno Setup Definition

Edit `installer/sanc_term.iss` to change installer behavior. Its current
settings include:

- application name: `sanc_term`;
- default install directory: `{autopf}\sanc_term`;
- minimum Windows version: Windows 10, build 17763;
- supported architecture: x64-compatible Windows;
- Start menu shortcut and optional desktop shortcut;
- modern installer wizard with LZMA2 compression;
- optional Visual C++ runtime installation; and
- an option to launch the application after installation.

Keep the existing `AppId` unchanged for future releases. Windows uses it to
recognize upgrades and the existing installed application.

### Output Directory

The default output directory is `dist`. Override it with an absolute or
repository-relative path:

```powershell
.\scripts\build_windows_installer.ps1 `
  -OutputDirectory .\artifacts\windows
```

### Visual C++ Runtime

By default, the script downloads and bundles Microsoft's x64 Visual C++
2015-2022 Redistributable. During installation it runs only when the x64
runtime is not registered as installed.

To build a smaller installer without bundling the runtime:

```powershell
.\scripts\build_windows_installer.ps1 -SkipVCRedist
```

Use this only if deployment guarantees that the required runtime is already
installed.

### Code Signing

For a release certificate installed in the Windows certificate store, pass its
SHA-1 thumbprint:

```powershell
.\scripts\build_windows_installer.ps1 `
  -CertificateThumbprint "CERTIFICATE_SHA1_THUMBPRINT"
```

The script signs both `sanc_term.exe` and the final installer with SHA-256 and a
DigiCert timestamp. It searches `PATH` for `signtool.exe`; otherwise provide an
explicit path:

```powershell
.\scripts\build_windows_installer.ps1 `
  -CertificateThumbprint "CERTIFICATE_SHA1_THUMBPRINT" `
  -SignToolPath "C:\Program Files (x86)\Windows Kits\10\bin\<sdk-version>\x64\signtool.exe"
```

Do not store certificate passwords, private keys, or secrets in the repository.

## Where to Find the Installer

After a successful build, the script prints the full output path. With the
default configuration, find it here:

```text
<repository>\dist\sanc_term_setup_<version>.exe
```

For example, version `0.1.0+1` produces:

```text
dist\sanc_term_setup_0.1.0.exe
```

Installed application files normally go to:

```text
C:\Program Files\sanc_term\
```

The user can choose another directory in the installer. Because privilege
override is enabled, the installer can also offer a non-administrator install
mode when appropriate.

## Troubleshooting

- **`ISCC.exe was not found`**: install Inno Setup 6 or pass
  `-InnoCompilerPath` with the full compiler path.
- **`Release executable not found`**: remove `-SkipFlutterBuild`, or run
  `flutter build windows --release` first.
- **VC++ download fails**: verify network access, place the official
  `vc_redist.x64.exe` in `installer/cache/`, or use `-SkipVCRedist` only when
  the target computers already have the runtime.
- **Signing fails**: verify the certificate thumbprint, private-key access,
  certificate validity, timestamp network access, and `signtool.exe` path.
- **Windows SmartScreen warning**: sign release builds with a trusted code
  signing certificate. Reputation may still take time to develop.

Before distributing an installer, test installation, launch, upgrade, and
uninstallation on a clean supported Windows computer. Hardware communication
should also be verified with the relevant serial, USB, or network device.
