#!/bin/bash -e

UMBREL_ROOT=$(dirname $(readlink -f ../../$0))
# UMBREL_ROOT=/home/umbrel
RELEASE="v$(cat $UMBREL_ROOT/signals/update)"
UMBREL_USER=umbrel

if [ $(whoami) != 'root' ]; then
    UMBREL_USER=$(whoami)
fi

echo "======================================="
echo "============= OTA UPDATE =============="
echo "======================================="
echo "========== Stage: Download ============"
echo "======================================="
echo

if [ -z $(grep '[^[:space:]]' $UMBREL_ROOT/signals/update) ]; then
    echo "Empty update signal file. No release version not found."
    exit 1
fi

# Make sure an update is not in progres
if [ -f "$UMBREL_ROOT/statuses/update-in-progress" ]; then 
    echo "An update is already in progress. Exiting now."
    exit 2
fi

echo "Creating lock"
touch $UMBREL_ROOT/statuses/update-in-progress

# Cleanup just in case there's temp stuff lying around from previous update
echo "Cleaning up any previous mess"
[ -d /tmp/umbrel-$RELEASE ] && rm -rf /tmp/umbrel-$RELEASE

# Update status file
cat <<EOF > $UMBREL_ROOT/statuses/update-status.json
{"state": "installing", "progress": 10, "description": "Downloading Umbrel $RELEASE"}
EOF

# Clone new release
echo "Downloading Umbrel $RELEASE"

cd /tmp/umbrel-$RELEASE
wget -qO- "https://raw.githubusercontent.com/mayankchhabra/umbrel/$RELEASE/install-box.sh"
./install-box.sh

cd bin/update

echo "Running update install scripts of the new release"
for i in {00..99}; do
    if [ -x ${i}-run.sh ]; then
        echo "Begin ${i}-run.sh"
        ./${i}-run.sh $RELEASE $UMBREL_ROOT $UMBREL_USER
        echo "End ${i}-run.sh"
    fi
done

echo "Deleting cloned repository"
[ -d /tmp/umbrel-$RELEASE ] && rm -rf /tmp/umbrel-$RELEASE

# echo "Deleting update signal file"
# rm -f $UMBREL_ROOT/signals/update

echo "Removing lock"
rm -f $UMBREL_ROOT/statuses/update-in-progress

exit 0