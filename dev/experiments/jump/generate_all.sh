#!/bin/bash
(cd ./scripts; ./host pvna 00 05 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
(cd ./scripts; ./host pend 00 37 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
(cd ./scripts; ./host spin 30 77 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
(cd ./scripts; ./host trus 00 07 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
(cd ./scripts; ./client pvna 00 05 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
(cd ./scripts; ./client pend 00 37 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
(cd ./scripts; ./client spin 30 77 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
(cd ./scripts; ./client trus 00 07 https://app.practable.io/dev/jump ~/secret/app.practable.io/dev/jump.pat)
