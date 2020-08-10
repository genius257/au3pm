---
excerpt: Install a package
---
# Install
Install a package

### Synopsis

```
au3pm install (with no args, in package dir)
au3pm install <name>
{% comment %}
au3pm install [<@scope>/]<name>@<tag>
au3pm install [<@scope>/]<name>@<version>
au3pm install [<@scope>/]<name>@<version range>
au3pm install <alias>@au3pm:<name>
au3pm install <git-host>:<git-user>/<repo-name>
{% endcomment %}
au3pm install <git repo url>
{% comment %}
au3pm install <tarball file>
au3pm install <tarball url>
au3pm install <folder>
{% endcomment %}
```

### Description

This command installs a package, and any packages that it depends on. If the package has a package-lock file, the installation of dependencies will be driven by that.

A package is:

1. a folder containing a program described by a package.json file
2. a gzipped tarball containing (1)
3. a url that resolves to (2)
4. a <name>@<version> that is published on the registry (see registry) with (3)
5. a <git remote url> that resolves to (1)

Even if you never publish your package, you can still get a lot of benefits of using au3pm if you just want to write a AutoIt program (1), and perhaps if you also want to be able to easily install it elsewhere after packing it up into a tarball (2).
