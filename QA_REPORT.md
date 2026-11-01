# QA Report

## Translation

- Game databases: 90
- Total rows: 27071
- Visible localizable rows: 26298
- Translated visible rows: 26298
- Missing translations: 0
- Special action/choice overrides used: 166
- Target text containing U+FFFD: 0

All source control markers, voice markers, and placeholder tokens were checked
against the translated rows. Any mismatch aborts the build.

## Fonts

- Rebuilt fonts: 38
- Font verification failures: 0
- Required distinct characters: 2585

All 38 Project font slots use a verified Unicode fallback with the complete
translated glyph set. Every required character is present and no glyph-coverage
failure remains. The fallback intentionally normalizes typeface styling in
places where preserving the original Latin-only font would reintroduce byte-wise
mojibake.

## Archives

- Rebuilt TTARCH2 archives: 8
- Original archive bytes: 41452343
- Patched archive bytes: 234854534

Every archive was decoded again after writing. All targeted entries matched
their replacement bytes, and every non-targeted entry remained byte-identical
to the original game resource.

## Safety

- No third-party EXE or installer is included.
- No network access is required or performed by the installer.
- Original archives are hash-checked before installation.
- Original archives are backed up and hash-checked.
- Installation and uninstallation use temporary files and post-write hashes.
- Unexpected game versions or modified archives cause an immediate abort.
- Installer and uninstaller round-trip passed in an isolated game-tree sandbox:
  all eight archives changed to the patched hashes and were then restored to
  the original hashes.

## In-game checks

- Launch screen: Simplified Chinese text rendered correctly.
- Main menu and chapter selection: Chinese labels rendered correctly.
- Detailed audio/video settings: Chinese labels and values rendered correctly.
- Episode 1 opening and story text: Chinese narrative and prompt text rendered
  correctly.
- The patch was built against official Steam-restored archive hashes.
