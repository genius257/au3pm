---
excerpt: The AutoIt3 Package Registry
---
# Registry
The AutoIt3 Package Registry

### Description
To resolve packages by name and version, au3pm talks to a registry website that implements the au3pm Package Registry specification for reading package info.

au3pm is configured to use au3pm public registry at https://github.com/au3pm/registry/ by default. Use of the au3pm public registry is subject to terms of use available at https://github.com/au3pm/registry/blob/master/terms.md.

You can configure au3pm to use any compatible registry you like, and even run your own registry. Use of someone else's registry may be governed by their terms of use.

au3pm's package registry implementation supports several write APIs as well, to allow for publishing packages and managing user account information.

The au3pm public registry is powered by GitHub and GitHub Actions, of which the script for the latter is publicly available at https://github.com/au3pm/action-test/butler.js.

The registry URL used is determined by the scope of the package (see [`scope`](scope.md). If no scope is specified, the default registry is used, which is supplied by the registry config parameter. See [`au3pm config`](..\cli-commands\config.md) and [`config`](config.md) for more on managing au3pm's configuration.

### Does au3pm send any information about me back to the registry?
No.

The au3pm registry is simply a repository for looking up information.
The only information sent is the bare minimum for getting the wanted response:
- The requested package name
- Information sent when making a HTTP GET request
This information is not stored or handled by the package registry, but GitHub might collect the information it revices, mentioned above.

### Can I run my own private registry?
Yes!

The easiest way is to use your own GitHub repository and use the same folder/file structure.

### I don't want my package published in the official registry. It's private.
The current implementation of the package registry makes private packages via the official au3pm package registry impossible.

### Do I have to use a GitHub repository to build a registry that au3pm can talk to?
No.

Any standard HTTP server will do.

### Is there a website or something to see package docs and such?
Yes, head over to https://au3pm.github.io/
