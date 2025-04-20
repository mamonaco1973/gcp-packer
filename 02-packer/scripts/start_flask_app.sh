#!/usr/bin/bash
cd /flask
/usr/local/bin/gunicorn -b 0.0.0.0 app:candidates_app

