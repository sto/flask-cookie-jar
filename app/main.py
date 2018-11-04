# Aplicación de preba de gestión de cookies
#
# Copyright 2018 Sergio Talens-Oliag <sto@uv.es>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions: The above copyright
# notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import uuid
from datetime import datetime

from flask import Flask, make_response, render_template, request


class Config:
    DOMAIN = os.environ.get('COOKIE_DOMAIN') or 'docker.local'
    MAX_AGE = os.environ.get('COOKIE_MAX_AGE') or 900  # 15 minutes
    MIN_AGE = os.environ.get('COOKIE_MIN_AGE') or 30  # 30 seconds
    PATH = os.environ.get('COOKIE_PATH') or '/cookie_path'

    @staticmethod
    def init_app(app):
        _max_age = app.config.get('MAX_AGE')
        _min_age = app.config.get('MIN_AGE')
        _domain = app.config.get('DOMAIN')
        _path = app.config.get('PATH')
        app.cookie_flags = {
            'session_cookie': {},
            'persistent_cookie': {
                'max_age': _max_age
            },
            'persistent_short_cookie': {
                'max_age': _min_age
            },
            'secure_cookie': {
                'secure': True
            },
            'httponly_cookie': {
                'httponly': True
            },
            'domain_cookie': {
                'domain': _domain
            },
            'domain_and_path_cookie': {
                'domain': _domain,
                'path': _path
            },
            'path_cookie': {
                'path': _path
            },
            'samesite_cookie': {
                'samesite': 'Strict',
            },
        }
        app.cookie_names = set(app.cookie_flags.keys())
        app.cookie_count = {}
        for cookie in app.cookie_names:
            app.cookie_count[cookie] = {}


def create_app(cfg):
    app = Flask(__name__)
    app.config.from_object(cfg)
    cfg.init_app(app)
    return app


def gen_cookie_value():
    ts = datetime.now().strftime('%Y%m%d-%H%M%S.%f')
    uid = uuid.uuid4()
    return "[{}]: {}".format(ts, uid)


app = create_app(Config())


@app.route('/')
def index():
    # Set of names for the cookies present on the current request
    request_cookies = set(request.cookies.keys())
    # Set of names of received cookies that are not handled by this app
    xtra_cookies = request_cookies - app.cookie_names
    # Set of names of received cookies that are handled by this app
    old_cookies = request_cookies - xtra_cookies
    # Set of names of cookies handled by this app that where not received
    new_cookies = app.cookie_names - old_cookies
    # Cookie information
    old_cookies_info = {}
    new_cookies_info = {}
    # Increment the count of times seen for the given cookie value
    for cookie_name in old_cookies:
        cookie_value = request.cookies[cookie_name]
        if cookie_value not in app.cookie_count[cookie_name]:
            app.cookie_count[cookie_name][cookie_value] = 1
        else:
            app.cookie_count[cookie_name][cookie_value] += 1
        old_cookies_info[cookie_name] = {
            'value': cookie_value,
            'views': app.cookie_count[cookie_name][cookie_value],
        }
    # Dictionary of cookies to set
    new_cookies_data = []
    # Create values for unset cookies
    for cookie_name in new_cookies:
        cookie_value = gen_cookie_value()
        cookie_data = {'key': cookie_name, 'value': cookie_value}
        cookie_data.update(app.cookie_flags[cookie_name])
        new_cookies_data.append(cookie_data)
        cookie_flags = []
        for (fname, fvalue) in app.cookie_flags[cookie_name].items():
            if fvalue is True:
                cookie_flags.append(fname)
            elif isinstance(fvalue, str):
                cookie_flags.append("{}={}".format(fname, fvalue))
        new_cookies_info[cookie_name] = {
            'value': cookie_value,
            'flags': ";".join(cookie_flags),
        }
    # Prepare response
    resp = make_response(
        render_template(
            'index.html',
            old_cookies_info=old_cookies_info,
            new_cookies_info=new_cookies_info,
            xtra_cookies=xtra_cookies))
    for cookie_data in new_cookies_data:
        resp.set_cookie(**cookie_data)
    return resp


@app.route('/cookie_path')
def cookie_path():
    return index()
