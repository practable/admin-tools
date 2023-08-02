# admin-tools
Administrative tools - these require credentials from your system administrator, that will be in a form like [this](https://github.com/practable/credentials-example)

## Prerequsites

- [jq](https://stedolan.github.io/jq/)
- [websocat](https://github.com/vi/websocat)
- [mo](https://github.com/tests-always-included/mo)
- [relay](https://github.com/practable/relay)
- [yq](https://github.com/mikefarah/yq)

For logins via shellrelay, you will get remote host authentication warnings unless you add this line to `~/.ssh/config` (you may need to create the file, in which case you only need this line, no other lines are required)
```
NoHostAuthenticationForLocalhost yes
```

### For token
- python 3
- extra modules required: `humanize`, `pytest`, `pyjwt`

## Session relay

For a quick look at which , say, `trus` experiments are connected, use:

```
./getSessionStats.s | grep trus
```

To see details of message traffic, show extra lines, this example is 

```
$ ./getSessionStats.sh| grep trus -A 18 -B1
  {
    "topic": "trus00-video",
    "canRead": false,
    "canWrite": true,
    "connected": "2022-09-06 17:57:32.005911887 +0000 UTC m=+5005749.041827758",
    "remoteAddr": "129.215.182.88",
    "userAgent": "Go-http-client/1.1",
    "stats": {
      "tx": {
        "last": "20.01161ms",
        "size": 5783,
        "fps": 23.869676144597026
      },
      "rx": {
        "last": "Never",
        "size": 0,
        "fps": 0
      }
    }
  },
--
  {
    "topic": "trus00-data",
    "canRead": true,
    "canWrite": true,
    "connected": "2022-09-06 17:56:36.299197457 +0000 UTC m=+5005693.335113328",
    "remoteAddr": "129.215.182.88",
    "userAgent": "Go-http-client/1.1",
    "stats": {
      "tx": {
        "last": "1.361034858s",
        "size": 65,
        "fps": 1.1077586188437158
      },
      "rx": {
        "last": "210h28m24.519900974s",
        "size": 9,
        "fps": 0.06805585812345667
      }
    }
  },
```

If you are not getting data, check that the access server is working ok (this example is working ok)

```
./checkAccess.sh
$client_token=ey...
https://relay-access.practable.io/session/stats
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    91  100    91    0     0   1716      0 --:--:-- --:--:-- --:--:--  1716
{"uri":"wss://relay.practable.io/session/stats?code=575bf3fd-de78-4349-a9d6-04788fd19ed7"}
```
##  Shellrelay

Note that for a limited period, we are running an older version of the relay code for shell, and the latest version for shell2. Therefore with the latest version of relay installed on your admin machine, only shell2 scripts will work. The shell scripts will fail with a message about an audience in the JSON token. 


## Tokens

This script was written to support a specific use case, with the following features

- short duration tokens (three days) to be issued to students on various days during the semester
- the duration to exclude weekend working time (e.g. a three-day token starting on Friday ends on Wednesday, not Monday)

It relies on the admin credentials being available - see [private credentails repo](https://github.com/practable/credentials-uoe-soe) (note if this 404s it is because you are not an admin on our UoE system and hence won't have access to our credentials file).

### Usage
```
./generate <groups> <start_at> <every> <duration> <end_by> <code> <link_stub>
```


### Example 

```
cd tokens
./generate "truss everyone"  2022-10-04T06:00:00Z 1d 3d  2022-12-21T06:00:00Z truss22 "https://book.practable.io/?c="
```
Note that in the time strings, the T and Z are required to suit the time format, and timezone support is incomplete, so assume everything is in UTC.

The 'every', and 'duration' parameters support durations in a bash-like duration format (represented here in pseudo regexp form): `([0-9]*d)*(?[0-9]*h)*(?[0-9]*m)*(?[0-9]*s)*` i.e. `1d2h` would be 26 hours.

You run the tests in the script with `./test` because pytest ignores files that don't end in `.py` (so this script temporarily makes a file with the right ending, then deletes it after the tests).

The output from the script is found in `./output/<now>`. The `generate` script relies on finding the `user-token.sh` script in the same directory, hence the decision to use automatically-created subdirectories rather than try and get both scripts on the path.

You can check the token details in the `./output/<now>/validated-tokens.csv` file. This is the file to share with your course organiser, so they can distribute the links to their students. The output might look something like this:

|link                                                             |nbf_ts    |nbf                |exp                |signature|duration|groups               |
|-----------------------------------------------------------------|----------|-------------------|-------------------|---------|--------|---------------------|
|https://book.practable.io/?c=truss22-Tue-04-Oct-for-3-days-5YAXQ1|1664875038|2022-10-04 09:17:18|2022-10-07 09:17:18|True     |3 days  |['truss', 'everyone']|
|https://book.practable.io/?c=truss22-Wed-05-Oct-for-5-days-BC12JK|1664946000|2022-10-05 05:00:00|2022-10-10 05:00:00|True     |5 days  |['truss', 'everyone']|
|https://book.practable.io/?c=truss22-Thu-06-Oct-for-5-days-G78MV1|1665032400|2022-10-06 05:00:00|2022-10-11 05:00:00|True     |5 days  |['truss', 'everyone']|


## Develop

Before making this repo public it was scanned for secrets using [git secrets](https://github.com/msalemcode/git-secrets), including these [patterns](https://github.com/timdrysdale/git-secrets-patterns).

```
git secrets --scan-history
```


## Trouble shooting

If an experiment does not appear to be connecting to `session relay`, or `shell relay` then the likely causes are

0. power or network wiring issue (unlikely)
1. SD card issue (unlikely)
2. tokens expired (also unlikely, but some earlier experiments only had 1yr tokens)

## How to diagnose a token issue

0. Book out the other experiments in the container
1. Turn container off
2. Connect your linux laptop to the network port on the container and enable wifi sharing to wired connections
3. Turn container power on
4. Identify the sub net used for sharing, by listing the IP addresses of all your laptop network interfaces, and looking at the address associated with your physical network interface, usually `eth0` or similar (can be more exotic name on laptops though)
```
ip addr
```
It's usually going to be something in the `10.42.0.0/24` subnet, so we'll proceed on that basis (modify the below accordingingly if needed)

5. Map the experiments you can see on your local network
```
sudo nmap -sP 10.42.0.0/24
```
6. Identify which one you want, by looking at the mac addresses. If you are not sure which `mac` you want, either check in the secrets repo with e.g. for pen00
```
export EXPT=pend00
~/secret/mac $EXPT
```
Not all experiments have a `mac` in `~/secret/experiments.yaml` so you may get a null response (e.g. there is no entry for `pvna00` at this time)

```
# change xx to suit the IP you found above
export IP=10.42.0.xx 
```

8. Check the user name and password of the experiment
```
export USER=$(~/secret/eu $EXPT) && echo user=$USER
~secret/ep $EXPT
```

7. If you do not know which one is which, then simply try logging in and checking
```
# enter password when prompted
ssh $USER@$IP 
```

8. check what machine you are on
Now you are logged in to the rpi, following commands are run on the experiment unless mentioned otherwise
```
export name={$(< /etc/practable/data.access) && export name=${name##*/} && echo $name
```

9. now check the token(s)

```
cat /etc/practable/data.token
```

copy the token and then run on your laptop the following command, then paste in the token
```
decode-jwt
```

The output will look like this:
```
{
  "alg": "HS256",
  "typ": "JWT"
}
{
  "topic": "pvna01-data",
  "prefix": "session",
  "scopes": [
    "write",
    "read"
  ],
  "aud": "https://relay-access.practable.io",
  "exp": 1835171888,
  "iat": 1677491888,
  "nbf": 1677491888
}
exp: Sat 26 Feb 09:58:08 GMT 2028
iat: Mon 27 Feb 09:58:08 GMT 2023
nbf: Mon 27 Feb 09:58:08 GMT 2023
```

Check that the `exp` date is not in the past - if it is, replace the token by editing
`/etc/practable/data.token`

10. Do the same for `/etc/practable/video.token` if there is a video feed.

11. Once the tokens are updated, force experiment to use them
```
sudo systemctl restart session-rules
```

12. Confirm that the streams are now showing on `session-relay`
on laptop

```
cd ~/sources/admin-tools/aws/sessionrelay
./getSessionStats.sh | grep $EXPT -B 1 -A 18
```

13. Now check the token for shell relay 

on the experiment
```
cd /etc/systemd/system
#may be called shellhost2.service
cat shellhost.service | grep TOKEN
```

The output will look like
```
Environment=SHELLHOST_TOKEN=eyJhbGc...<snip>...
```
copy the token string (everything after the equals sign) and run `decode-jwt` on your laptop as before.

If the token has expired, then edit the service file to have the new token contents.

Then restart the service

```
sudo systemctl daemon-reload
sudo systemctl restart shellhost.service
```

