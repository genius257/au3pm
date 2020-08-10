---
excerpt: Manage the au3pm configuration files
---
# Config
Manage the au3pm configuration files

### Synopsis

```
au3pm config set <key> <value> [-g|--global]
au3pm config get <key>
au3pm config delete <key>
au3pm config list [-l] [--json]
au3pm config edit
au3pm get <key>
au3pm set <key> <value> [-g|--global]

aliases: c
```

### Description

au3pm gets its config settings from the command line, environment variables, au3pmrc files, and in some cases, the au3pm.json file.

See [au3pmrc]() for more information about the au3pmrc files.

See [config]() for a more thorough discussion of the mechanisms involved.

The __au3pm config__ command can be used to update and edit the contents of the user and global au3pmrc files.

### Sub-commands

Config supports the following sub-commands:

#### set

```
au3pm config set key value
```

Sets the config key to the value.

If value is omitted, then it sets it to “true”.

#### get

```
au3pm config get key
```

Echo the config value to stdout.

#### list

```
au3pm config list
```

Show all the config settings. Use -l to also show defaults. Use --json to show the settings in json format.

#### delete

```
au3pm config delete key
```

Deletes the key from all configuration files.

#### edit

```
au3pm config edit
```

Opens the config file in an editor. Use the --global flag to edit the global config.
