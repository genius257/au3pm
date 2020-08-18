---
excerpt: A manifestation of the manifest
---
# au3pm-lock.json
A manifestation of the manifest

### Description

__au3pm-lock.json__ is automatically generated for any operations where au3pm modified either the au3pm tree, or __au3pm.json__.
It describes the exact tree that was generated, such that subsequent installs are able to generate identical trees, regardless of intermediate dependency updates.

The file is intended to be committed into source repositories, and serves various purposes:

* Describe a single representation of a dependency tree such that teammates, deployments and continuous integration are guaranteed to install exactly the same dependencies.
* Provide a facility forusers to "time-travel" to previous states of the au3pm directory, without having to commit the directory itself.
* To facilitate greater visibility of tree changes through readable source control diffs.
* And optimize the installation process by allowing au3pm to skip repeated metadata resolutions for previous-installed packages.
