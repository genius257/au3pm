---
excerpt: Create a au3pm.json file
---
# Init
Create a au3pm.json file

### Synopsis

```
{% comment %}
au3pm init [--force|-f|--yes|-y|--scope]
au3pm init <@scope> (same as `au3px <@scope>/create`)
{% endcomment %}
au3pm init <name>
```

### Examples

{% comment %}
Create a new server-based project using create-au3server-app:

```
au3pm init au3server-app ./my-au3server-app
```

Create a new ''au3p''-compatible package using ''create-au3p'':

```
mkdir my-au3p-lib && cd my-au3p-lib
au3pm init au3p --yes
```
{% endcomment %}
Generate a plain au3pm.json using init:

```
mkdir my-au3pm-pkg && cd my-au3pm-pkg
git init
au3pm init
```
{% comment %}
Generate it without having it ask any questions:

```
au3pm init -y
```
{% endcomment %}

### Description

It will ask you a bunch of questions, and then write a package.json for you. It will attempt to make reasonable guesses based on existing fields, dependencies, and options selected. It is strictly additive, so it will keep any fields and values that were already set. You can also use -y/--yes to skip the questionnaire altogether.
