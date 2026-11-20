# System Context: Share Lyrics Clips

```
Library file + synced lyrics (002, 003)
  └─ Clip editor (Flutter) ── start/end, look (background, dim, text, names, pictures) ──┐
                                                ▼
     Frame painter (Flutter, one PNG per line change)
                                                ▼
     ClipEncoder (Dart interface) ── zema/clip channel ──► Android ClipEncoder.kt
        MediaExtractor/MediaCodec: cut + AAC     ┐
        Surface input: frames → H.264           ├─► MediaMuxer → MP4 (cache dir)
                                                 ┘
                                                ▼
     System share menu (ShareChannel) / save to gallery (MediaStore)
```

- **In**: the user's own audio file and the song's lyrics and timing, all on the phone.
- **Out**: one MP4 in the app cache, shared by the user. Nothing is uploaded by Zema.
