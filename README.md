# Field Notes

A Flutter app for customers, sites, and field notes. Records are stored locally in Hive; queued changes are uploaded when the app syncs with the backend.

## Quick Start & Environment Setup

This project uses a secure public configuration workflow. Secrets and local URLs are kept in a local `.env` file that is excluded from version control.

### 1. Initialize Your Environment

Generate your local `.env` configuration from the provided template:

```sh
# On macOS / Linux
./scripts/setup_env.sh

# On Windows
scripts\setup_env.bat

# Or manually
cp .env.example .env
```

### 2. Configure Backend Endpoint (Optional)

Adjust `BASE_URL` in `.env` if needed for your platform:
- **Android Emulator**: `BASE_URL=http://10.0.2.2:8080`
- **iOS Simulator / Desktop**: `BASE_URL=http://127.0.0.1:8080`
- **Web**: `BASE_URL=http://localhost:8080`

For full configuration and public repository security details, see [Environment & Security Setup Guide](docs/ENVIRONMENT_SETUP.md).

### 3. Run the App

```sh
flutter pub get
flutter run
```

## Where code lives

| Folder / file | Responsibility |
| --- | --- |
| `lib/main.dart` | Load configuration, initialize services, start the app |
| `lib/app.dart` | Provide BLoCs and configure the theme and router |
| `lib/features/<feature>/screens/` | Display widgets and respond to user input |
| `lib/features/<feature>/bloc/` | Handle events and emit states for the screen |
| `lib/repositories/` | Read and save records; coordinate storage and API calls |
| `lib/models/` | Represent records and convert them to and from JSON |
| `lib/core/storage/` | Open Hive boxes and manage saved session data |
| `lib/core/network/` | Send HTTP requests and translate failures |
| `lib/core/sync/` | Upload queued changes and download server updates |
| `lib/core/widgets/` | Share buttons, fields, loading views, and error views |
| `lib/core/di/service_locator.dart` | Create shared services and inject their dependencies |
| `lib/routes/app_router.dart` | Define navigation and authentication redirects |

## Follow one feature

Start with field notes, reading these files in order:

1. `lib/features/field_notes/screens/field_note_form_screen.dart`: collects input and sends `SubmitFieldNoteForm`.
2. `lib/features/field_notes/bloc/field_note_form_bloc.dart`: loads form data, handles selections, validates input, saves through the repository, and emits success or error states. The separate `FieldNoteBloc` manages the notes list.
3. `lib/repositories/field_note_repository.dart`: saves the note in Hive, queues a `SyncMutation`, and triggers sync.
4. `lib/models/field_note.dart`: converts the note into local JSON or an API write payload.
5. `lib/core/sync/sync_manager.dart`: pushes queued mutations and pulls server changes.

A **BLoC event** is a request to do something, such as saving a note. A **state** describes what the screen should display, such as loading, a list of notes, or an error. A **repository** handles data access so the screen can focus on presentation.

Repository interfaces describe the available operations. Classes ending in `Impl` provide the actual implementation. Dependencies are passed through constructors; `ServiceLocator` wires them together at startup.

## Understand synchronization

A mutation is a queued save or delete operation. Saving locally and uploading to the server are separate steps:

1. A repository updates the local Hive box.
2. It adds a mutation to `syncMutationsBox`.
3. `SyncManager` uploads a batch of up to 100 mutations.
4. Server acknowledgements remove accepted mutations from the queue and update local versions.
5. The manager downloads changes in pages and saves the latest cursor.

A **cursor** marks how far the app has read server changes. A **version** helps the server detect conflicting updates. Parent records are saved before child records: customer, site, then note. Deletes use the reverse order.

Automatic sync uploads only when the local queue contains changes. Saves are grouped with a 500 ms delay; startup and reconnection retry pending changes. There is no periodic polling. Automatic uploads do not download server updates; manual sync downloads updates, and login restores server data. Failed uploads stay queued until another save, reconnect, app restart, or manual retry. Large queues are uploaded in batches until empty or no progress is made. `compute()` prepares batch payloads and parses downloaded changes outside the UI isolate. An isolate is a separate Dart execution context that helps keep the interface responsive.

`toJson()` stores the local model. `toWritePayload()` sends only fields accepted by the API. `SyncMutation.toApiPayload()` also cleans older queued records before upload. Note timestamps are converted to UTC strings ending in `Z`, so `occurredAt` includes a timezone.

## Make changes

- For layout or text, edit the feature screen or shared widget.
- For a user action, update the event and its BLoC handler.
- For data access, edit the repository.
- For a new field, update the model, form, and API payload sanitization together.
- For backend paths or connection settings, start with `ApiConstants` and `ApiClient`.

Keep methods focused on one job and use descriptive names. Add comments to explain ordering rules, compatibility handling, and other decisions that are hard to infer from the code.

## Verify changes

```sh
flutter analyze
flutter test
```

Tests cover model serialization, session storage, timestamp normalization, and authentication failure handling. Tests use fake repositories or temporary Hive storage to avoid depending on a running backend.
