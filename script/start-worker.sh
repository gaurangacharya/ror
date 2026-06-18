#!/bin/bash

set -e

bundle install
exec bundle exec rake ts:start && bundle exec sidekiq -q default -q paperclip -q mailers -q transactions