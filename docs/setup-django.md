---
description: How to prepare your app to use Sockpuppet
---

# Setup

Sockpuppet is ultimately a port of rails' library StimulusReflex and thus also relies on [Stimulus](https://stimulusjs.org/), an excellent library from the creators of Rails. But nonetheless completely independent from Rails.

You can easily install Sockpuppet to new and existing Django projects.

```bash
pip install django-sockpuppet

# Add these into INSTALLED_APPS in settings.py
INSTALLED_APPS = [
    'channels',
    'sockpuppet'
]

# generates scaffolding for webpack.config.js and installs required js dependencies
# if you prefer to do that manually read on below.
python manage.py initial_sockpuppet

# scaffolds a new reflex with everything that's needed.
python manage.py generate_reflex app_name name_of_reflex
```

The terminal commands above will ensure that Sockpuppet is installed. It creates an example to get you started.

However you will need to make some further configurations in `settings.py` and you need some way to build the javascript. We will detail what `initial_sockpuppet` does behind the scenes below.

## Configuration

Sockpuppet depends on django-channels for the websockets functionality, and as such we need that configuration. We need to make some changes to `settings.py` where we need to add the following.

```python
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [('127.0.0.1', 6379)],
        },
    },
}
# in the same folder as wsgi.py
ASGI_APPLICATION = 'sockpuppet.routing.application'
INSTALLED_APPS = [
    ...
    'channels',
    'sockpuppet',
    ...
]
```
{% hint style="danger" %}
Instead of using redis as a channel layer you can use the in-memory channel layer. But that should **ONLY** be used for development purposes or tests.

```python
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer"
    }
}
```
{% endhint %}

If you already are using django-channels in your project you can take a look at the source code of the routing file in sockpuppet and amend your routing as needed.

### Javascript configuration

You may already have a working build system in javascript for your django project. If you don't we've got you covered.

There isn't an particularly strong convention on javascript should be handled in django, so below is a proposal on how you could organize your build setup.

So let's first install all the dependencies we need for the most minimal webpack configuration to work.

```bash
npm i -D fs path sockpuppet-js stimulus_reflex webpack webpack-cli
```

We also need to build and watch any changes that we make in our project. For this we add two script options into `package.json`

```json
"scripts": {
    "build": "webpack --mode production",
    "watch": "webpack --watch --info-verbosity verbose"
},
```

The last part is the configuration for webpack itself.

{% tabs %}
{% tab title="webpack.config.js" %}
```javascript
const webpack = require('webpack');
const glob = require('glob');


let globOptions = {
    ignore: ['node_modules/**', 'venv/**']
}

let entryFiles = glob.sync("**/javascript/*.js", globOptions)

let entryObj = {};
entryFiles.forEach(function(file){
    if (file.includes('.')) {
        let parts = file.split('/')
        let path = parts.pop()
        let fileName = path.split('.')[0];
        entryObj[fileName] = `./${file}`;
    }
});

const config = {
    mode: process.env.NODE_ENV,
    entry: entryObj,
    output: {
        path: __dirname + '/dist/js',
        filename: '[name].js'
    },
    optimization: {
        minimize: false
    }
}

module.exports = config
```
{% endtab %}
{% endtabs %}

The configuration above will look for javascript files in the folder `your_app/javascript`, compile them and place the output in the folder `dist/js/`.

If you add that folder to `STATICFILES_DIRS` in settings it will pick that compiled javascript and you can use it in templates.

```
STATICFILES_DIRS = [
    ("js", "/dist/js"),
]
```

And that's it! **You can start using Sockpuppet in your application.**

{% page-ref page="quickstart.md" %}


## Session storage

By default django is using the database as a backend for sessions. Examples in the quickstart will be using sessions as a way to persist data between page loads.

This may cause more strain on your database in high-traffic scenarios than would you like. Since you are already using redis for `django-channels` you could use redis as a session storage. The library [`django-redis`](https://github.com/jazzband/django-redis) has instructions to set that up.


## Logging

To get debug logging for Sockpupet you need to make some modifications to `LOGGING` in `settings.py`. Below you can see an example logging configuration that enables debug level logging Sockpuppet.

```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'root': {
        'handlers': ['console'],
        'level': 'DEBUG'
    },
    'handlers': {
        'sockpuppet': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        }
    },
    'formatters': {
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
    'loggers': {
        'sockpuppet': {
            'level': 'DEBUG',
            'handlers': ['sockpuppet']
        }
    }
}
```
