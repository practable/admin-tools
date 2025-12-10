# ansible dynamic inventory

There is an inconvenience with gcp dynamic inventory - you can only specify one auth key, so if you use a different key on a different project
you need to switch the inventory file (or use same service account key, which is insecure / could risk confusing actions on different projects).

The gcp plugin only accepts `<path>/gcp.yaml` as the file, not variations on this name, so you can't have more than one file either

Thus, there are two files, and you simply symlink to whichever one you want to be doing work with at the time, in `/opt/ansible/inventory`.

Note that dynamic inventory is configured in `/etc/ansible/ansible.cfg`

```
sudo ln -s  gcp.yaml.test gcp.yaml
#or
sudo ln -s  gcp.yaml.app gcp.yaml
```
