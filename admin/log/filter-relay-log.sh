#!/bin/bash
cat relay.log | grep -v 'alive' | grep -v 'routine' > relay-filtered.log
