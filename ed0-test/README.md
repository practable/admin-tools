# ed0-alternate guidance

## installation

run these playbooks:

configure-kernel
pre-install-setup
install-book
install-jump
install-relay
install-status
install-webhook
update-static-contents

## Logging in from campus

If you get asked for an sshgate password, your kerberos pre-authorisation is stale, so refresh that, e.g.
```
kinit youruun@EASE.ED.AC.UK
```

Note the formatting of the username - it's not your actual email.

Also, you need to have installed kerberos and added an ssh config - see [credentials-uoe-soe](https://github.com/practable/credentials-uoe-soe/blob/main/dot-ssh/config)init repo


## restarting the instance

check current bookings are finished
export any future bookings
restart the instance

upload the manifest 
import future bookings
check experiment status

If the disk has been wiped, then full install with the ansible playbooks is needed



## Generating booking links 

Booking links are generated with `./book/generate_bookings` using  `./data/booking-plan.yml`

Problem: the booking plans are currently kept in `github.com/booking-links` and not supplied in this admin-tools repo.
Solution: Make a symlink in ./book/ to the appropriate dir in the booking-links repo, e.g.

```
ln -s /home/tim/sources/booking-links/2024-02-12 ./data
```

Then navigate to `./book/` and run the scripts as required. 

