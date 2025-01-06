# ed0-staging guidance

## Logging in from campus

If you get asked for an sshgate password, your kerberos pre-authorisation is stale, so refresh that, e.g.
```
kinit youruun@EASE.ED.AC.UK
```

Note the formatting of the username - it's not your actual email.

Also, you need to have installed kerberos and added an ssh config - see [credentials-uoe-soe](https://github.com/practable/credentials-uoe-soe/blob/main/dot-ssh/config)init repo


## staging server for checking that ansible scripts will run without error 

The purpose of this server is to allow us to upgrade the operating system image on the ed0 instance, using this staging server to first check that all the ansible scripts still run. This should allow us to detect possible issues with installer and configuration incompatibilities.


## Installation order

go to `./playbooks`

configure-kernel
pre-install-setup
install-nginx
install-relay
install-jump
install-book
install-status
install-webhook

Note that github has not been configured to issue calls to the webhook on the staging server






