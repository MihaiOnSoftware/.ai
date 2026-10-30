Bug facts

- Symptom: when a work order is created through the public REST API with a dueDate that falls on a DST transition day for the organization's time zone, the stored dueDate is off by one hour. Reported by one integrator (ticket from support, 2026-10-24). Reproduced locally by Wen Zhao with America/Toronto and dueDate 2026-11-01T02:30:00 local.
- Suspected cause (not confirmed): the REST layer converts the local date with a fixed offset taken from the organization's current offset at request time rather than the offset on the target date. Wen saw this in restDateMapper.ts but did not step through it.
- Not affected: work orders created from the web app (they send UTC).
- Out of scope: changing the public API date format; migrating already-stored dates.
- Nobody is assigned. No priority has been set. No fix approach has been decided.
