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
TEMPEST_COMMIT="489f5e62"  # 15 June, 2015
git checkout $TEMPEST_COMMIT

# Install Manila Tempest integration
cp -r /home/ubuntu/manila/contrib/tempest/tempest/* $TEMPEST_BASE/tempest

cd /opt/stack/tempest
testr list-tests | grep share | grep -Ev "tempest.api.image|tempest.scenario" > "$RUN_TESTS_LIST" || echo "failed to generate list of tests"

testr run --subunit --load-list=$RUN_TESTS_LIST | subunit-2to1 > /home/ubuntu/tempest/subunit-output.log 2>&1
cat /home/ubuntu/tempest/subunit-output.log | /opt/stack/tempest/tools/colorizer.py > /home/ubuntu/tempest/tempest-output.log 2>&1
# testr exits with status 0. colorizer.py actually sets correct exit status
RET=$?
cd /home/ubuntu/tempest/
python /home/ubuntu/bin/subunit2html.py /home/ubuntu/tempest/subunit-output.log

exit $RET
