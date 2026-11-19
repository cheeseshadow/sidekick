# Sidekick

Sidekick is a small macOS window that floats above other windows and shows a task list
from a markdown file. It is for people who work on several things at once, for example
while agents run in the background, and lose track of what they were doing. The window
answers one question at a glance: what am I in the middle of, and what is left?

Sidekick only displays the list. People and agents change the list by editing the file,
and the window updates and animates when the file changes.

`DESIGN.md` describes how the app works.

## How to use the list

Sidekick works well for a short list and badly for a long one. The advice below is for
the people and agents who edit the tasks file, and it keeps the list short.

- **The file is a working list for today or the current session, not a backlog.** If a
  task is not meant to happen today, it belongs in an issue tracker or planning notes.
- **In progress (`[/]`) marks the tasks in focus.** These are the tasks to come back to
  after a distraction, including work that waits on an agent or a reply. The window
  highlights them in a card at the top.
- **Planned (`[ ]`) is what is left for today or the session.** The window shows at most
  `max_visible_tasks` open tasks and counts the rest as "N more" in the footer. If the
  footer shows hidden tasks, the list has turned into a backlog.
- **One line per task.** Start with a verb and name the thing, for example
  `Review the pull request`. A link to the ticket or pull request is fine. The window
  shows only top-level tasks: lines indented by two or more spaces or a tab can hold
  steps, but they do not appear. If a step matters right now, make it the task text.
- **Change either the status or the text in one save, not both.** Sidekick matches tasks
  between saves by their text. If a task's text is new, Sidekick matches it to the task
  that was at the same position with the same status. A status change, a move and a text
  edit each animate as that change. A task whose text and status both change looks like
  a removed task and a new one.
- **Leave done tasks until the day or session ends.** The window hides them and shows
  only a done count, which shows progress. Clear them when a new day or session starts.
- **Agents mark their own tasks.** If an agent adds a task for its own work, it marks the
  task `[/]` when it starts and `[x]` when it finishes. An agent does not reorder, rewrite
  or remove tasks it did not add unless the user asks.

## Tasks file format

```markdown
# Any heading, ignored by the window

- [/] Review the pull request
- [ ] Reply to the email about the demo
- [x] Book the meeting room
```

| Line | Shown as |
|---|---|
| `- [/] Task` | In progress, in the highlighted card at the top |
| `- [ ] Task` | Planned, below the card |
| `- [x] Task` or `- [X] Task` | Done, counted in the "N done" line |
| Anything else, including task lines indented by two or more spaces or a tab | Not shown |

`*` works in place of `-`. Task text supports inline markdown: bold, italic, `code`,
strikethrough and links. Links are not clickable.

## Config

Sidekick reads `~/.config/sidekick/config.json`. Only `tasks_file` is required:

```json
{
  "tasks_file": "~/path/to/tasks.md"
}
```

`DESIGN.md` lists the optional keys: window width, font size, the visible task limit, hover
behavior, accent color and background tint. The menu bar icon has Open Tasks File and Open
Config File.

If the tasks file is in a folder that syncs with cloud storage, keep the file downloaded on
the Mac. Sidekick reads the local file and does not download it.

## Build and install

Sidekick builds with Xcode's Swift toolchain from the command line. Xcode must be
installed and its license accepted.

1. Create a self-signed code signing certificate in Keychain Access: Certificate Assistant
   → Create a Certificate, Identity Type "Self-Signed Root", Certificate Type "Code
   Signing". Name it `Sidekick app certificate` to match the Makefile default. With a
   stable signature, macOS remembers the app's file permissions across rebuilds.
2. Run `make install`. It builds the app, signs it, copies it to `~/Applications` and
   starts it. For a certificate with another name, run
   `make install SIGN_IDENTITY="<certificate name>"`. If the keychain has no certificate
   with that name, the Makefile signs the app ad hoc and prints a warning.
3. Add Sidekick to Login Items in System Settings to start it at login.

`make test` runs the tests for the tasks file parser, the window content and the config.

## License

Sidekick is available under the MIT license. See `LICENSE`.
