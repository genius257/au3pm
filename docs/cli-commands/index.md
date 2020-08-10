### CLI commands

{% for page in site.html_pages %}
  {% if page.title != nil and page.dir contains "/cli-commands/" and page.name != "index.html" %}
* [{{ page.title | downcase }}]({{ page.url | relative_url }}) {{ page.excerpt }}
  {% endif %}
{% endfor %}
