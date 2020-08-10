---
excerpt: List installed packages
---
# List
List installed packages

### Synopsis

```
au3pm list
```

### Description

This command will print to stdout all the versions of packages that are installed, as well as their dependencies, in a tree-structure.

It will print out extraneous, missing, and invalid packages.

The tree shown is the logical dependency tree, based on package dependencies, not the physical layout of your node_modules folder.
