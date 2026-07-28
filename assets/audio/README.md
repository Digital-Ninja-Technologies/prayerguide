# Ambience audio

Drop your own royalty-cleared ambience tracks in here with these exact
filenames — the Prayer Timer's Rain / Ocean / Instrumental pills play
them on loop:

- `rain.mp3`
- `ocean.mp3`
- `instrumental.mp3`

Any format `audioplayers` supports works (mp3, wav, ogg, m4a) — just update
the extension in `lib/features/timer/ambience_player.dart`'s `_fileFor` map
to match if you use something other than `.mp3`. Files aren't included in
this repo (licensing), so the timer will show a "couldn't play" message for
any track whose file is missing until you add it.

Aim for a seamless loop (no audible seam at the wrap-around) and a
consistent, moderate volume across all three so switching tracks doesn't
jolt the volume up or down.
