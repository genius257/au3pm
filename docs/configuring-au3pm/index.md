### Configuring au3pm
{% for page in site.html_pages %}{% if page.title != nil and page.dir contains "/configuring-au3pm/" and page.name != "index.md" %}
* [{{ page.title | downcase }}]({{ page.url | relative_url }}) {{ page.excerpt }}{% endif %}{% endfor %}
