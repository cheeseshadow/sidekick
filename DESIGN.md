# Sidekick

Sidekick is a macOS app that helps the user keep track of what they are doing while they
work on several things at once. It shows a small window that floats above other windows
with two things: the tasks in focus, highlighted at the top, and the rest of the tasks for
today or for the current session below them.

The window takes as little screen space as possible. Every element in it is either a task
or something the user needs to see to get back on track. Anything else stays in the file.

Sidekick only displays the list. People and agents change the list by editing a markdown
file, and Sidekick redraws and animates when the file changes.

## Tasks file

Sidekick reads one markdown file and uses these lines:

| Line | Meaning |
|---|---|
| `- [/] Task` | A task in progress. |
| `- [ ] Task` | A planned task. |
| `- [x] Task` or `- [X] Task` | A done task. |

Sidekick ignores every other line, headings included. The file can use headings and notes
to organize the list for the people and tools that edit it, and none of that appears in the
window. `*` works in place of `-`.

Sidekick also ignores task lines indented by two or more spaces or a tab. The file can
break a task into steps, but the window shows only the tasks themselves, because a second
level of tasks competes with the first.

`[/]` for "in progress" follows the Obsidian Tasks plugin convention. Starting work on a
task is a one-character change, and the task keeps its place in the file.

Task text supports inline markdown: bold, italic, `code`, strikethrough and links. A link
shows its text in the accent color. Links are not clickable.

Example:

```markdown
# Today

## Project
- [/] Review the pull request
- [ ] Reply to the email about the demo
- [x] Book the meeting room

## Release
- [/] Write the release notes
  - [x] Collect the changes
  - [ ] Draft the summary
- [ ] Update the website
```

The window for this file shows:

```
┃ ● Review the pull request
┃ ● Write the release notes
  ○ Reply to the email about the demo
  ○ Update the website
  1 done
```

## Matching tasks between saves

Sidekick compares each new version of the file with the previous one and animates the
differences. A task's identity is its text. If a task's text did not exist in the previous
version, Sidekick gives it the identity of the task at the same position, if that task had
the same status and is gone from the new version. So a status change, a move and a text
edit each animate as that change, and a task whose text and status both change in one save
animates as a removed task and a new one.

## Layout

The window shows, top to bottom:

1. **In progress**: every `[/]` task, in file order, inside a highlighted card. These are
   the tasks the user must come back to after a distraction, so they are the most visible
   thing in the window. With no task in progress, the card is not shown.
2. **Planned**: every `[ ]` task, in file order.
3. **Footer**: one line with the number of hidden tasks and the number of done tasks, for
   example "4 more · 1 done". Either part is left out when it is zero, and the line is
   not shown when both are zero. Done tasks themselves are not shown.

Task text wraps to as many lines as it needs.

The window shows at most `max_visible_tasks` open tasks. In progress tasks take the slots
first, in file order, and planned tasks get the rest. The tasks past the limit are hidden
and counted as "N more" in the footer. The limit is a failure state, not a target: a
working list stays well below it. When a visible task is completed, the next hidden task
appears with the "task added" animation.

The window has no title, no section labels and no group labels. The card and the marker
style tell the groups apart.

If the file has only done tasks, the window shows only the footer. If the file has no tasks
at all, the window shows "Nothing on the list".

## Config file

Sidekick reads `~/.config/sidekick/config.json`:

```json
{
  "tasks_file": "~/path/to/tasks.md"
}
```

| Key | Required | Meaning |
|---|---|---|
| `tasks_file` | Yes | Path to the tasks file. |
| `window_width` | No | The window width in points. More than 0. |
| `font_size` | No | The task text size in points. The footer and the markers scale with it. More than 0. |
| `max_visible_tasks` | No | How many open tasks the window shows, in progress and planned together. 1 or more. |
| `hover_opacity_percent` | No | Window opacity while the cursor is over it, from 0 to 100. 100 turns the fade off. |
| `hover_fade_back_delay_ms` | No | How long the window waits after the cursor leaves before it fades back, in milliseconds. 0 or more. |
| `accent_color` | No | The accent color, as `#RRGGBB`. Without it, Sidekick uses the system accent color. |
| `background_tint_light` | No | A tint over the background blur in light mode, as `#RRGGBB`. Without it, the blur has no tint. |
| `background_tint_dark` | No | A tint over the background blur in dark mode, as `#RRGGBB`. Without it, the blur has no tint. |
| `background_tint_opacity_percent` | No | How much the tint covers the blur, from 0 to 100. |

- Sidekick expands `~` to the home folder.
- Sidekick reads the config at launch and again when the config file changes.
- If the config file is missing or invalid, or the tasks file does not exist or cannot be
  read, the window shows a message that says what is wrong and names the path.

## Window

### Behavior

- The window floats above normal windows, shows on every desktop and over full-screen apps.
- Clicking the window does not take focus from the app in front.
- The window has no title bar. Dragging anywhere in it moves it, and Sidekick remembers the
  position between launches. The width is always `window_width`.
- The window height always matches the content, up to a maximum that depends on the screen
  height. Past that, the window stops growing and cuts off the bottom rows. A list that
  long has stopped being a working list, so Sidekick does not scroll it.
- When the cursor enters the window, the window fades to `hover_opacity_percent`, so the
  user can see what is under it. When the cursor leaves, the window waits
  `hover_fade_back_delay_ms` and fades back to full opacity. The wait keeps a cursor
  passing along the edge from making the window flicker. The faded window still takes
  clicks, so the user can drag it while it is faded.
- Sidekick has no Dock icon and does not appear in the app switcher.
- A menu bar icon has four items: Show Window or Hide Window, Open Tasks File (in the
  default app for markdown), Open Config File (in the default app for JSON) and Quit
  Sidekick. Open Tasks File is disabled while the config is missing or invalid. Open
  Config File is disabled while the config file does not exist.
- Moving is the only interaction with the window.

### Look

The window must look calm enough to leave on screen all day.

- Background: the macOS translucent blur material, with an optional tint from the config.
  Rounded corners, a thin hairline border and a soft shadow.
- Accent: used for the card, its markers, the completion check mark and link text.
- Type: the system font at `font_size` for every task. Weight and color set the hierarchy,
  not size. In progress tasks use a medium weight and the primary color. Planned tasks
  use the regular weight and the secondary color. The footer is smaller and uses the
  tertiary color.
- Markers: an in progress task has an accent dot. A planned task has a hollow ring.
- Alignment: planned task markers line up with the card's markers, and the footer lines
  up with the task text.

## Animations

Sidekick animates only when the file changes. Nothing moves while the list is unchanged,
because motion on an idle window pulls the eye away from the work. The window height
follows each change.

- **Task added**: the row fades in and slides into place while the rows around it make
  space.
- **Task started** (`[ ]` to `[/]`): the row moves from its place in Planned into the In
  progress card, and the hollow marker turns into the accent dot.
- **Task completed** (`[/]` or `[ ]` to `[x]`): the marker fills and draws its check mark,
  then a strikethrough line draws across the text from left to right, then the row fades
  out, the rows below close the gap and the done count goes up by one.
- **Task removed**: the row fades out and the rows below close the gap.
- **Task text edited**: the text crossfades in place.

If several tasks change in one save, their animations run together.

If the macOS "Reduce motion" setting is on, every change is a short crossfade with no
movement.

## Updates

Sidekick checks the modification date, size and file number of the tasks file and the
config file several times a second, and redraws when one of them changes. Many editors
save by writing a new file in place of the old one, which a watcher on the open file
handle would miss. The checks and the file reads run off the main thread, so a slow file
system does not block the window.

## Build and install

Sidekick is a Swift package using AppKit for the window and SwiftUI for the content. It
builds from the command line with Xcode's Swift toolchain, with no Xcode project. The
`Makefile` sets `DEVELOPER_DIR` to Xcode, because the Command Line Tools lack the compiler
plugins for SwiftUI's macros, such as `@State` and `@Entry`.

`make install` does the following:

1. Builds the release binary with `swift build -c release`.
2. Wraps it in `Sidekick.app` with an `Info.plist` that marks it as an accessory app
   (`LSUIElement`).
3. Signs the bundle with the self-signed certificate that `SIGN_IDENTITY` names. If the
   login keychain has no such certificate, it signs the bundle ad hoc and prints a warning.
4. Copies the bundle to `~/Applications` and restarts the app.

If the tasks file is in a folder that macOS protects, such as iCloud Drive, Documents or
Desktop, macOS asks for permission to read it. macOS ties that permission to the app's
signing identity. The self-signed certificate keeps the identity the same across
rebuilds, so the user grants the permission once. An ad hoc signature changes with every
build and brings the prompt back.

The user creates the certificate once in Keychain Access and adds Sidekick to Login Items
in System Settings.

## Out of scope

- Changing tasks from the window: starting, ticking, adding, editing, reordering or
  deleting.
- Clickable links.
- More than one tasks file or window.
