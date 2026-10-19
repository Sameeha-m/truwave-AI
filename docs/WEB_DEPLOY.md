# Flutter web deployment

The `demo/web` branch builds the Flutter app as a GitHub Pages site at
`https://<owner>.github.io/truwave-AI/`. A push to `demo/web` or a manual run of
the **Build and deploy Flutter web** workflow builds and deploys the site. The
workflow does not depend on Render.

## One-time repository settings

1. In **Settings → Pages**, set **Build and deployment → Source** to **GitHub
   Actions**.
2. In **Settings → Secrets and variables → Actions → Variables**, create the
   repository variable `API_BASE_URL` with the HTTPS root URL of the deployed
   API, without a trailing slash or endpoint path. The app appends `/verify`.
   The workflow stops with a clear error when this variable is missing.
3. Ensure the API accepts browser requests from the GitHub Pages origin
   `https://<owner>.github.io` through its CORS policy. The project path is not
   part of a browser origin.
4. Ensure GitHub Actions is allowed to write Pages deployments. The workflow
   requests `pages: write` and `id-token: write`; repository or organization
   policy must permit those permissions.

The build embeds `API_BASE_URL` as `TRUWAVE_API_BASE_URL` and uses the project
site base path `/truwave-AI/`. The Flutter `web/index.html` already contains
the `$FLUTTER_BASE_HREF` placeholder required by `--base-href`.

## sqflite web setup

`flutter_app/pubspec.yaml` includes `sqflite_common_ffi_web` as a direct
dependency, and `lib/main.dart` selects `databaseFactoryFfiWeb` when running on
web. The workflow runs `dart run sqflite_common_ffi_web:setup` before the web
build; this creates `sqlite3.wasm` and `sqflite_sw.js` in `flutter_app/web/` for
the build artifact.
