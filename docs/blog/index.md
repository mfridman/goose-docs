{% extends "base.html" %}

{% block extrahead %}
  {% set title = config.site_name %}
  {% if page and page.meta and page.meta.title %}
    {% set title = title ~ " - " ~ page.meta.title %}
  {% elif page and page.title and not page.is_homepage %}
    {% set title = title ~ " - " ~ page.title %}
  {% endif %}
  <meta name="twitter:card" content="summary" />
  <meta name="twitter:title" content="{{ title }}" />
  <meta name="twitter:description" content="{{ config.site_description }}" />
  <meta name="twitter:image" content="/assets/goose_logo.png" />
{% endblock %}

# Blog
