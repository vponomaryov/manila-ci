#!/bin/bash

TEMPEST_BASE="/opt/stack/tempest"

cd $TEMPEST_BASE

testr init

TEMPEST_DIR="/home/ubuntu/tempest"
EXCLUDED_TESTS="$TEMPEST_DIR/excluded_tests.txt"
RUN_TESTS_LIST="$TEMPEST_DIR/test_list.txt"
mkdir -p "$TEMPEST_DIR"

# Checkout stable commit for tempest to avoid possible
# incompatibilities for plugin stored in Manila repo.
TEMPEST_COMMIT="3b1bb9be3265f"  # 28 Aug, 2015
git checkout $TEMPEST_COMMIT

testr list-tests | grep "manila_tempest_tests.tests.api" > "$RUN_TESTS_LIST"

if [[ $? -eq 0 ]]; then
  testr run --subunit --load-list=$RUN_TESTS_LIST | subunit-2to1 > /home/ubuntu/tempest/subunit-output.log 2>&1
  cat /home/ubuntu/tempest/subunit-output.log | /opt/stack/tempest/tools/colorizer.py > /home/ubuntu/tempest/tempest-output.log 2>&1
  RET=$?
  cd /home/ubuntu/tempest/
  python /home/ubuntu/bin/subunit2html.py /home/ubuntu/tempest/subunit-output.log
  exit $RET
else
  echo "failed to generate list of tests"
  exit 1
fi
