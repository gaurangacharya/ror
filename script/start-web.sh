#!/bin/bash

set -e

bundle install
exec bundle exec rails s webrick -b 0.0.0.0
