#!/bin/bash

set -e

bundle check || bundle install --retry 1
bundle exec rspec
STATUS=$?

popd

exit $STATUS
