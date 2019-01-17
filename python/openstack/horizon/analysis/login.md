# CODE ANALYSIS FOR LOGIN

> Recently I find read commit messages are helpful for understanding many background

On the backend, Horizon uses **Django** framework to implement a server; on the frontend, it uses **angularjs** with server-side template rendered by jinja2 template engine.

Till now, I am not familiar with *django* at all, but to quickly locate the particular code I am interested in, I find a quick read of [this guide](https://docs.djangoproject.com/en/2.1/intro/tutorial01/) is usefual. I am no expert, but I guess a **url** is used to handle request routing; while **view** is responsible for response object rendering. With this simple preknowledge in mind, it is enough at least to navigate login code. Another thing to know is that django, like many other python projects, uses **jinja2** as a template engine. I find [this doc](http://jinja.pocoo.org/docs/2.10/templates/#template-designer-documentation) particularly useful for understanding some trivial details (for example, `BoundField` is created by `django.forms.fields.Field#get_bound_field` when `django.forms.forms.BaseForm#__getitem__` is invoked).
