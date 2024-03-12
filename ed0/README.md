# ed0 guidance


## Genearing booking links 

Booking links are generated with `./book/generate_bookings` using  `./data/booking-plan.yml`

Problem: the booking plans are currently kept in `github.com/booking-links` and not supplied in this admin-tools repo.
Solution: Make a symlink in ./book/ to the appropriate dir in the booking-links repo, e.g.

```
ln -s /home/tim/sources/booking-links/2024-02-12 ./data
```

Then navigate to `./book/` and run the scripts as required. 

