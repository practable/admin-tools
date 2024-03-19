## Helpful procedures

### Checking server health

These examples are written with reference to `ed0` but apply to other instances running the full stack.

First check the [status page](https://app.practable.io/ed0/status/). If this page is being served, then the instance is running and does not need to be rebooted at this stage.

If ALL of the experiments have streams missing, then it is likely that the relay requires restarting. To restart the relay, log in to the server

```
cd ~/sources/admin-tools/ed0
./login.sh
```

Once logged in, check the current load using top

```
top
```

Typically you should see around 40% load on relay, and about 20% load on `nginx` at rest, and under heavy usage the `relay` load approaches 70%. If there is no load then there is either a problem with the relay, or with the experiments themselves (e.g. campus network outage).

Exit top with `q`

Check the status of the `relay` service

```
sudo systemctl status relay
```

If this is `active` but there is NO load showing in top, then it needs restarting. If it is `inactive` then it needs restarting. Restart it:

```
sudo systemctl restart relay
```

This can take a minute or two. If it takes longer than two minutes, then you can `control-C` and try 

```
sudo systemctl status relay 
sudo system stop relay #if it is still running, then try stopping it
sudo system start relay #else just try starting it
```

but really, it amounts to the same thing. After restarting, check the service is `active`

```
sudo systemctl status relay
```

And if it is active, check the load on it in `top`

```
top
```

If these steps have not been successful, then check the disk capacity

```
sudo df ./ -h
```

If there is more than 50% disk used, then it's likely there is a build up of log files. Currently, status is running in debug mode, producing GB of logging. You can safely delete the status server logs at this time. This should return the disk usage to closer to 31% (although `df` only reports the correct value after a delay/status is restarted).

```
cd /var/log/status
ls -alh 
sudo rm status.log
sudo systemctl restart status
```
Don't worry if the first few re-freshes of the status page appear to show the experiments are down - it takes a few minutes for `status` to collect information and start reporting the correct state of the system, then a further period of `STATUS_HEALTH_STARTUP=15m` until status will start adjusting the availability of experiments. Experiments will show as unavailable on the status, but bookable anyway.

If the disk is too full, you won't be able to log on, so if in doubt, better to delete the `status.log` at this time.

If the instance needs restarting, then go to the google cloud console, choose the `practable.io` organisation, then the `app-practable-io-alpha` project, then `Compute Engine` in the menu on the left, and then select the instance, and restart it (see option under the three vertical dots in the right hand column of the entry for the instance in the list of VMs).

Note that restarting the instance has the following consequences
- timeout while system restarts
- all user bookings are lost (if the instance is still running, you can export and re-import after restart, but if it is not running, there is no way to export and you must restart)
- the booking manifest needs re-uploading 


To upload the manifest:
```
cd ~/sources/manifest-ed0
./check.sh
./upload.sh
```

### Disk full issues

If you are trying to identify the source of disk usage, then the `du` tool is helpful.

`sudo du -h -d 1`

Snaps sometimes fill up ... but the minimum number of versions that must be retained is two.

Consider editing the terraform plan and increasing the disk size.
