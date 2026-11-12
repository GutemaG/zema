# Plan: Keep listening (a Pixel-style Now Playing for Zema)

> Source: product owner, 2026-11-12 ("on my Pixel, Now Playing identifies songs with the
> screen off; how does that work?"). Plans 010 FR-1 and FR-2. **Not scheduled**: the
> remaining 009 work comes first.

## Goal

You start Keep listening once, for example at the start of a service, and put the phone
away. As each song plays, Zema identifies it. The song shows on the lock screen, and its
synced lyrics are ready to open.

## How it compares with Pixel's Now Playing

Pixel listens all the time on a separate low-power chip that only Google's system
software can use. Android doesn't give other apps that chip, or silent always-on
listening. So Zema gets close, but not all the way:

| | Pixel Now Playing | Zema Keep listening |
|---|---|---|
| Starts | On by itself, always | You start it in the app |
| Screen off / locked | Works | Works once started |
| Song on the lock screen | Yes | Yes, in the notification, updated on each song |
| Lyrics | No | Synced lyrics, following the song |
| Which songs | Popular songs, Google's list | The library now; the catalog after 009 FR-2/FR-3 |
| Mic is on | Not shown | Notification and the green mic dot the whole time |
| Battery | Almost none | Noticeable; meant for 1–2 hours |
| Stops | Never | When you stop it, or after a time limit (default 1 hour) |

## How it works

1. **Start**: a Keep listening switch on the Listen screen, with a length (30 min, 1 h,
   2 h). Android allows an app to start using the microphone only while it is open, so
   it can't start from the background.
2. **Foreground service** (Kotlin): `foregroundServiceType="microphone"`, with a
   notification showing the current song, Stop, and Open lyrics. Permissions:
   `FOREGROUND_SERVICE_MICROPHONE` and `POST_NOTIFICATIONS`.
3. **Listening in bursts**: record about 10 s, identify with the existing engine
   (offline index, worker isolate), then pause. After a match:
   - check again every 20–30 s, to catch the next song;
   - when the matched song is near its end, check sooner.
   - After no match, back off (20 s, then 40 s, then 60 s).
   - Nothing that was heard is kept.
4. **Following songs** (FR-2):
   - the same song at the expected place keeps the lyrics running;
   - the same song at a different place re-syncs (moves the lyrics);
   - a different song switches the lyrics.
   - The open lyrics screen and the notification both follow the current song.
5. **Ending**: at the time limit, when you tap Stop, or when another app takes the
   microphone (a call). The notification says why.
6. **iOS**: only while Zema is open (Apple's rules); no screen-off listening.

## Build steps

| Step | What | Depends on |
|------|------|------------|
| 1 | Burst loop in Dart: repeated identify, the song-change rules, the back-off; unit tests with clock control | Listen (009 FR-5) ✓ |
| 2 | Kotlin foreground service holding the microphone; recording handed to Dart; notification with song and Stop | 1 |
| 3 | Lyrics screen and notification follow the current song; Open lyrics from the notification | 2, 009 FR-7 ✓ |
| 4 | Time limit and interruptions (calls, another app using the mic); no automatic restart after the app is killed | 2 |
| 5 | Measure battery per hour on a mid-range phone; tune the burst timing to the 010 goal (each song shown within 15 s) | 3 |
| 6 | Play Store: microphone foreground-service declaration and the privacy text | 5 |

## Risks

- **Battery savers** (Tecno, Infinix, Samsung) may stop the service; 009 FR-18's guidance
  applies here too.
- **Play policy** on microphone foreground services: the use must be user-started,
  visible, and explained in the listing.
- **Match rate in a hall**: the spike measured 82–93% offline at 0 dB babble. A song may
  take two bursts to be found.
- **Only library songs** until the catalog lookup (009 FR-2/FR-3) exists.

## Open questions

| Question | Default until decided |
|----------|-----------------------|
| Default length | 1 hour |
| Show lyrics on the lock screen itself (over the lock screen), or only in the notification? | Notification only |
| Burst timing | As above, tuned in step 5 |
