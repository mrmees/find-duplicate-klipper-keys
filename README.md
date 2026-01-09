# Klipper Duplicate Config Finder

A shell script to identify duplicate configuration keys across Klipper `.cfg` files, helping prevent configuration conflicts and unexpected behavior.

## What It Does

This script scans your Klipper configuration directory and identifies any configuration sections (e.g., `[stepper_x]`, `[extruder]`) that appear in multiple files. When the same key is defined in multiple places, Klipper's behavior can be unpredictable, so this tool helps you catch these issues early.

## Features

- 🔍 Recursively searches all `.cfg` files in your config directory
- 🎯 **Shows which duplicate is ACTIVE** based on Klipper's actual load order
- 📋 Parses `printer.cfg` and follows `[include]` directives exactly as Klipper does
- 🔄 Handles nested includes and wildcard patterns correctly
- 🚫 Automatically excludes:
  - Backup files (containing "backup" in the filename)
  - Dated backup files (YYYY-MM-DD, YYYYMMDD, YYYY_MM_DD formats)
  - Hidden files (starting with `.`)
- 📊 Clean output showing only relative filenames
- 🔧 Works on any Klipper installation without modification
- ⚡ Can be run from command line or integrated with `gcode_shell_command`

## Installation

### Option 1: Manual Installation

1. Download `find_duplicates.sh` to your Klipper config directory:
```bash
cd ~/printer_data/config
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/find_duplicates.sh
chmod +x find_duplicates.sh
```

### Option 2: Direct Creation

```bash
cd ~/printer_data/config
nano find_duplicates.sh
# Paste the script content
chmod +x find_duplicates.sh
```

## Usage

### Command Line

Run directly from your SSH session:
```bash
cd ~/printer_data/config
./find_duplicates.sh
```

### Integration with Klipper (gcode_shell_command)

1. Install the [gcode_shell_command](https://github.com/dw-0/kiauh/blob/master/docs/gcode_shell_command.md) extension if you haven't already

2. Add this to your `printer.cfg`:
```ini
[gcode_shell_command find_duplicates]
command: ../printer_data/config/find_duplicates.sh
timeout: 30.
verbose: True

[gcode_macro FIND_DUPLICATES]
description: Check for duplicate configuration keys
gcode:
    RUN_SHELL_COMMAND CMD=find_duplicates
```

3. Restart Klipper

4. Run from your console or macro:
```
FIND_DUPLICATES
```

Or use the original shell command directly:
```
RUN_SHELL_COMMAND CMD=find_duplicates
```

### Adding a Button to Your Interface

After adding the macro above, you can add a button to your interface:

**Mainsail:**
1. Go to Settings → Interface → Dashboard
2. Add a macro tile
3. Select the `FIND_DUPLICATES` macro
4. The button will appear on your dashboard

**Fluidd:**
1. The macro will automatically appear in your macros list
2. You can pin it to the dashboard for quick access

**KlipperScreen:**
- The macro will appear in the Macros menu

## Example Output

```
Duplicate configuration keys found:
====================================

[stepper_x]
  printer.cfg
  overrides.cfg ← ACTIVE

[extruder]
  printer.cfg
  hotend_config.cfg ← ACTIVE

[bed_mesh]
  printer.cfg
  calibration/mesh_settings.cfg ← ACTIVE
```

The `← ACTIVE` indicator shows which file's definition Klipper will actually use, based on the exact load order determined by parsing your `[include]` directives.

## Understanding the Results

When a configuration key appears in multiple files:
- **Last definition wins**: Klipper will use the last file loaded (based on include order)
- **The script follows Klipper's logic**: It parses `printer.cfg` and recursively follows all `[include]` directives in the exact order Klipper processes them
- **Wildcard includes**: Files matching wildcards (e.g., `[include macros/*.cfg]`) are loaded alphabetically
- **The ACTIVE marker**: Shows which file contains the definition that Klipper is actually using
- **Unexpected behavior**: If you're not aware of duplicates, changes to an inactive file won't have any effect
- **Recommended action**: Review each duplicate and decide whether to:
  - Remove the duplicate from inactive files
  - Rename one section (if using named variants, e.g., `[extruder1]`)
  - Consolidate settings into a single file
  - Adjust your `[include]` order if the wrong file is active

## Files That Are Ignored

The script automatically skips:
- Hidden files: `.printer.cfg`, `.backup.cfg`
- Backup files: `printer_backup.cfg`, `config-backup.cfg`, `backup.cfg`
- Dated backups: `printer-2024-01-15.cfg`, `config_20240115.cfg`, `settings_2024_01_15.cfg`

## Requirements

- Klipper installation with standard directory structure
- Bash shell
- Standard Unix utilities: `find`, `grep`, `sed`, `awk`

## Compatibility

- ✅ Tested on Raspberry Pi OS
- ✅ Tested with MainsailOS
- ✅ Tested with FluiddOS
- ✅ Should work on any Linux-based Klipper installation

## Troubleshooting

### "Permission denied" error
Make sure the script is executable:
```bash
chmod +x ~/printer_data/config/find_duplicates.sh
```

### No output or "command not found"
Verify the script path in your `gcode_shell_command` configuration matches where you saved it.

### Script doesn't find expected duplicates
The script only detects section headers like `[stepper_x]`. It does not check for duplicate parameters within the same section.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use and modify as needed.

## Author

Created for the Klipper community to help maintain clean, conflict-free configurations.

## Related Resources

- [Klipper Documentation](https://www.klipper3d.org/)
- [Klipper Configuration Reference](https://www.klipper3d.org/Config_Reference.html)
- [gcode_shell_command Extension](https://github.com/dw-0/kiauh/blob/master/docs/gcode_shell_command.md)
