# CLAUDE.md

This file gives instructions to AI agents that work in this repository.
The text uses Simplified Technical English (ASD-STE100).
Write all new text in this file in the same style.

## How to communicate with the user

Use Simplified Technical English (ASD-STE100) in all messages to the user.
Obey these rules:

- Use the active voice. Write "The test fails", not "The test is failed".
- Use the present tense for facts. Use the past tense only for completed actions.
- Write one instruction in each sentence.
- Keep each sentence to 20 words or less.
- Use the imperative mood for procedures. Write "Run the tests", not "You should run the tests".
- Use one approved word for one meaning. Do not use synonyms for the same thing in one message.
- Use "do not" for prohibitions. Do not use "don't", "never", or "avoid".
- Use "make sure" to tell the user to check a result.
- Do not use gerunds as verbs. Write "Run the tests", not "Running the tests".
- Do not use phrasal verbs when a single verb exists. Write "remove", not "take out".
- Do not use idioms, slang, or figurative language.
- Start each paragraph with the most important fact.
- Use a numbered list for steps. Use a bullet list for items with no order.
- Use technical names, code, and file paths as written. These are not subject to STE rules.

## What this package is

`widget_library` is a Flutter package for developers.
It shows widgets and their states in a grid on a mobile device.
It exports one widget, `CatalogApp`, and the `CatalogEntry` and knob types.
It is not a production dependency.
It is not a design system.

## Where to find things

- `lib/widget_library.dart` - the public exports. Add new public types here.
- `lib/src/models/` - `CatalogEntry` and the theme controller.
- `lib/src/knobs/` - knob types, knob values, and the knob controller.
- `lib/src/screens/` - the grid screen and the detail screen.
- `lib/src/widgets/` - the knob panel, the specs panel, the empty state, and the error boundary.
- `test/` - widget tests. One test file for each screen or widget.
- `example/` - a sample app. It runs the catalog on a device.
- `docs/superpowers/specs/` - design documents for each feature.
- `docs/superpowers/plans/` - implementation plans and task logs.
- `README.md` - the user documentation. It is the source of truth for the public API.

## Rules for code

- Keep the package small. The README says it is approximately 500 lines of code. Keep that true.
- Do not add dependencies to `pubspec.yaml`. The package depends only on `flutter`.
- Do not add desktop or web support. The package is for Android and iOS only.
- Do not add these features: device frames, code generation, persistence, URL-shareable knobs, golden tests, a pub.dev release. The README lists them as out of scope.
- Obey `analysis_options.yaml`. Use `const` constructors. Use trailing commas. Do not use `print`.
- Use `entriesBuilder`, not `entries`, in all examples and tests. `entries` is deprecated.
- Give each new interactive widget a `Key` with the `wl.` prefix. See the key table in `README.md`, section "Agent automation (Marionette)". Add each new key to that table.

## Rules for documentation

- When you change the public API, update `README.md` in the same change.
- When you change behavior, add a line to `CHANGELOG.md` under a new version heading.
- Increase the version in `pubspec.yaml` for each release. Use the same version in `CHANGELOG.md`.
- Write a design document in `docs/superpowers/specs/` before you start a large feature.

## Procedure: make a change

1. Read the applicable test file in `test/` before you change a screen or widget.
2. Make the change.
3. Run `flutter analyze`. Make sure the output shows no issues.
4. Run `flutter test`. Make sure all tests pass.
5. If you changed the public API or behavior, update `README.md` and `CHANGELOG.md`.
6. Report the result of each command to the user. If a test fails, show the output.

## Procedure: run the example

1. Go to the `example/` directory.
2. Run `flutter run` with a device connected.
3. To see changes to a catalog entry, save the file and press `r` in the terminal.

## Commits

- Use the Conventional Commits format: `feat:`, `fix:`, `docs:`, `test:`, `chore:`.
- Put a scope in parentheses when applicable, for example `fix(example):`.
- Write the subject line in the imperative mood.
