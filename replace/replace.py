#! python3

import sys
from pathlib import Path
import re

default_db_block = '''DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}'''

replacement_db_block = '''DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': os.environ.get('POSTGRES_DATABASE'),
        'USER': os.environ.get('POSTGRES_USER'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD'),
        'HOST': os.environ.get('POSTGRES_DOCKER_HOST'),
        'PORT': os.environ.get('POSTGRES_PORT'),
    }
}'''

subst_starts_with = [
    'SECRET_KEY',
    'DEBUG',
    'ALLOWED_HOSTS'
]


def substitute_text(text):
    text = text.replace(default_db_block, replacement_db_block)
    for key in subst_starts_with:
        temp = re.subn(r'{}.*\n'.format(key),
                       f"{key} = os.environ['{key}']", text)[0]
        if key == 'ALLOWED_HOSTS':
            temp = re.subn(
                r'{}.*\n'.format(key),
                f"{key} = os.environ['{key}'].split(',')", text)[0]
        text = temp
    text += "MEDIA_ROOT = os.path.join(BASE_DIR, 'media')\n"
    text += "MEDIA_URL = '/media/'\n"
    text += "STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')\n"
    return text


if __name__ == '__main__':
    path = Path(sys.argv[1])
    in_text = path.read_text()
    rep_text = substitute_text(in_text)
    path.write_text(rep_text)
    print(f'replacements saved in file {path}')
