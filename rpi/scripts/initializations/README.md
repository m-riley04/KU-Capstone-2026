# initialization

This folder holds all of the initialization scripts that are ran during device setup.

> NOTE: You should ***not*** need to run each script individually, and will be automatically run in the `init_sh` script. See details on this below.

## Adding New Script

The `init.sh` script iterates through and runs all initialization scripts matching the filename pattern `init_*.sh`. This means that to add a new initialization script, you must add the prefix `init_` to the filename. Doing so adds your script to the list of other initialization scripts automatically.
