# admin

Admin website for moderators (planned): browse lyrics, review the submission queue,
approve / request changes / reject, edit songs and recordings.

Planned stack: Flutter web, sharing `packages/zema_core` with the mobile app.
Deployed as static files (e.g. Vercel or Firebase Hosting). Access control is enforced
by the backend rules in `backend/`, not by the site itself.

Not created yet. When starting:

    flutter create --platforms web --org com.zemaapp --project-name zema_admin apps/admin

then add `resolution: workspace` and a `zema_core` path dependency to its pubspec, and
add `apps/admin` to the root `pubspec.yaml` workspace list.
