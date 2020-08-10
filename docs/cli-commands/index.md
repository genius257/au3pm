### CLI commands
{% assign page_url = page.url %}
{% for page in site.html_pages %}{% if page.title != nil and page.dir contains "/cli-commands/" and page.url != page_url %}
* [{{ page.title | downcase }}]({{ page.url | relative_url }}) {{ page.excerpt }}{% endif %}{% endfor %}
