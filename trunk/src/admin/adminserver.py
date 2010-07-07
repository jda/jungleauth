#!/usr/bin/env python
# Admin interface for JungleAuth

# Copyright 2010 Jonathan Auer
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys, os

import yaml

from flask import Flask
from flask import render_template, redirect, url_for, escape, request

import sqlalchemy

import wtforms

app = Flask(__name__)
app.secret_key = os.urandom(24)

@app.route('/')
def pageMain():
  return render_template('main.tmpl')

@app.route('/ap')
def pageAP():
  return render_template('main-ap.tmpl')

@app.route('/rate')
def pageRate():
  return render_template('main-rate.tmpl')

@app.route('/client')
def pageClients():
  return render_template('main-client.tmpl')

# if we are run as a program, start up
if __name__ == "__main__":
  app.debug = True
  app.run(host='0.0.0.0')

