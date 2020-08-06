## CLI documentation

### CLI commands

* [build](build.md) Build a package
* [config](config.md) Manage the au3pm configuration files
* [init](init.md) Create a au3pm.json file
* [install](install.md) Install a package
* [list](list.md) List installed packages
* [rebuild](rebuild.md) Rebuild a package
* [restart](restart.md) Restart a package
* [run](run.md) Runs a defined package script
* [start](start.md) Start a package
* [stop](stop.md) Stop a package
* [test](test.md) Test a package
* [uninstall](uninstall.md) Remove a package
* [update](update.md) Update a package
* [version](version.md) Show au3pm version

### Configuring au3pm

* [folders](folders.md) Folder Structures Used by au3pm
* [install](install.au3) Download and install au3pm
* [au3pmrc](au3pmrc.au3) The au3pm config files
* [au3pm.json](au3pm.json.md) Specifics of au3pm's au3pm.json handling
* [au3pm.lock](au3pm.lock.md) A manifestation of the manifest
* [au3pm-locks](au3pm-locks.md) An explanation of au3pm lockfiles

### Using au3pm

* [config](config.md) More than you probably want to know about au3pm configuration
* [developers](developers.md) Developer Guide
* [disputes](disputes.md) Handling Module Name Disputes
* [registry](registry.md) The AutoIt3 Package Registry
* [removal](removal.md) Cleaning the Slate
* [scripts](scripts.md) How au3pm handles the "scripts" field

### TEST

site url: {{site.url}}

{% for page in site.html_pages %}
  {% if page.title != nil and page.dir contains "/cli-commands/" %}
* [{{page.title}}]({{site.url}}{{page.url}}) {{page.excerpt}}
  {% endif %}
{% endfor %}
