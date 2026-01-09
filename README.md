# Klipper Duplicate Config Finder

A shell script to identify duplicate configuration keys across Klipper `.cfg` files, helping prevent configuration conflicts and unexpected behavior.

## What It Does

This script scans your Klipper configuration directory and identifies any configuration sections (e.g., `[stepper_x]`, `[extruder]`) that appear in multiple files. When the same key is defined in multiple places, Klipper's behavior can be unpredictable, so this tool helps you catch these issues early.

## Features

- 🔍 Recursively searches all `.cfg` files in your config directory
- 🚫 Automatically excludes:
  - Backup files (containing "backup" in the filename)
  - Dated backup files (YYYY-MM-DD, YYYYMMDD, YYYY_MM_DD formats)
  - Hidden files (starting with `.`)
- 📊 Clean output showing only relative filenames
- 🔧 Works on any Klipper installation without modification
- ⚡ Can be run from command line or integrated with `gcode_shell_command`

## Installation

### Option 1: Manual Installation

1. Download `find_duplicates.sh` to your Klipper config directory (or somewhere convenient, I use an EXTRAS directory under the config directory, but the instructions below assume it's in your config directory):
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
timeout: 10.
verbose: True
```

3. Restart Klipper

4. Run from your console:
```
RUN_SHELL_COMMAND CMD=find_duplicates
```

## Example Output

```
Duplicate configuration keys found:
====================================

[stepper_x]
  printer.cfg
  overrides.cfg

[extruder]
  printer.cfg
  hotend_config.cfg

[bed_mesh]
  printer.cfg
  calibration/mesh_settings.cfg
```

## Understanding the Results

When a configuration key appears in multiple files:
- **Last definition wins**: Klipper will use the last file loaded (based on include order)
- **Unexpected behavior**: If you're not aware of duplicates, changes to one file might not have the expected effect
- **Recommended action**: Review each duplicate and decide whether to:
  - Remove the duplicate from one file
  - Rename one section (if using named variants, e.g., `[extruder1]`)
  - Consolidate settings into a single file

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
