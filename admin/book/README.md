# README.md

Follow these steps to generate and upload bookings:


edit the manifest to provide the policies and slots you need (see [practable/manifest-gce-develop](https://github.com/practable/manifest-gce-develop)

edit `./data/booking-plan.yaml` to represent the new bookings you want

run yamllint on the booking-plan 
```
yamllint ./data/booking-plan.yaml
```

Run the generate bookings script
```
./generate_bookings
```

Run the serve script
```
./serve
```

Check the status (option 0)
Export existing bookings (option 3)
Exit (Ctrl-C)

If retaining or modifying existing bookings, run merge script

```
./merge-bookings
```

If completely replacing bookings, edit `./data/exported_bookings.json` to contain just `[]` (i.e. empty array)

Then run 


```
./merge-bookings
```

Run the serve script
```
./serve
```

Replace the bookings (option 4)

Export the new bookings (option 3)

Exit (Ctrl-C)

check the exported bookings contain all the bookings we expected:

```
./compare_bookings
```

check the number of bookings in each window we provided in the booking plan

```
./check_exported_bookings
```

```
./show_counts
```
