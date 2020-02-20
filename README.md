# M4A Conversion Shell Scripts

MacOS shell scripts for converting to M4A or getting info on M4As and/or WAV files.

Conversion defaults to 128kbps with the same channel configuration as the inputs, to a folder named `M4A` in the location the script was executed. These settings can be overriden with the `-b` or `--bitrate` and `-c` or `--channels` flags, or altered in the code.

Information gathering parses the output of `afinfo` and outputs the bitrate and channel configuration of each file.

## Dependencies

Built-in MacOS utilities `afconvert` and `afinfo`.

## Scripts

### m4aconvert.sh
Converts individual files or whole folders.

#### Examples:
```bash
m4aconvert.sh .                               # to convert whole current folder with default values
m4aconvert.sh 0.wav 1.wav                     # to convert individual files with default values
m4aconvert.sh --bitrate 256 --channels 1 WAV  # to convert all files inside WAV/ folder at 256kbps mono
m4aconvert.sh -b 96 -c 2 Docs                 # to convert all files inside Docs/ folder at 96kbps stereo
m4aconvert.sh -o converted .                  # to convert all files inside the current folder and put the new files into a folder named "converted/" 
```

### m4ainfo.sh
Outputs **bitrate** and **channel configuration** of individual files or whole folders.

#### Examples:
```bash
m4ainfo.sh .            # to show bit rate and channel config of all files in current folder
m4ainfo.sh 8.m4a 9.wav  # to show bit rate and channel config of specific files
m4ainfo.sh help         # to show this info
```

### m4amanage.sh
Incorporates `m4ainfo.sh` and `m4aconvert.sh` into a single script, which can be accessed by subcommands `convert` or `info`.

#### Examples:
```bash
m4amanage.sh convert .               # to convert whole folder with default values
m4amanage.sh convert 0.wav 1.wav     # to convert individual files with default values
m4amanage.sh convert -b 96 -c 2 WAV  # convert all files inside WAV/ folder at 96kbps stereo
m4amanage.sh convert -o converted .  # to convert all files inside the current folder and put the new files into a folder named "converted/"
m4amanage.sh info 8.m4a 9.wav        # to show bit rate and channel config, no conversion

m4amanage.sh help                    # to show MANUAL
```
