# au3pm
A package manager for AutoIt3

[![latest stable au3pm version](https://img.shields.io/github/v/release/genius257/au3pm?include_prereleases)](https://github.com/genius257/au3pm/releases)
![open issues](https://img.shields.io/github/issues-raw/genius257/au3pm)
![GitHub All Releases](https://img.shields.io/github/downloads/genius257/au3pm/total)
![AppVeyor tests](https://img.shields.io/appveyor/tests/genius257/au3pm)

The syntax is inspired from package managers like `npm`, `yarn` and `composer`.

# Installation

au3pm can be used portable or be installed.

## portable

Simply download the executable from releases, or build it yourself (building it, requires AutoIt to be installed)

## installation

1. Download the executable from releases.
2. Run the executable with the following parameters: `[au3pm] install au3pm -g`
3. Wait for the command to finish
4. the command `au3pm` should now be available in the `cmd.exe`


# Usage

syntax

```
au3pm [command] [args]
```

## install

syntax

```
au3pm install [package][@version]
```

example
```
au3pm install json
```
