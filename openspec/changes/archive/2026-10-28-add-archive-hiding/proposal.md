## Why

`linny.vim` can archive a document (`m` → `archive` writes `archive: true`), but the
menu never acts on the flag: archived documents keep showing up in every term listing
and widget. The only way to hide them is an `except` rule in every view of every
config. Linden Index Spec 0.4.0 (§5.4) adds an optional notebook-level
`lindenConfig/notebook.yml` with an archive policy that clients follow.

## What Changes

- Read `lindenConfig/notebook.yml` at `linny#Init` into `g:linny_notebook_config`.
- New module `linny.archive`: archive field (default `archive`), `default_hidden`
  (default `false`), `is_archived`, `is_visible`, a session toggle
  `g:linny_show_archived`, and the list of archived documents from the props index.
- Hide archived documents, when `default_hidden: true`, in: L2 term listings, the
  `starred_documents` widget and the `recently_modified_documents` widget.
- L2 menu: when documents are hidden, show how many, and a `<show archived>` /
  `<hide archived>` toggle on hotkey `a`.
- New widget type `archived_documents` for level-0 views: lists all archived documents.
- Without `notebook.yml` (or without `archive.default_hidden: true`) behaviour is
  unchanged.

## Capabilities

### New Capabilities
- `archive-hiding`: notebook-level archive policy in the menu.

### Modified Capabilities

## Impact

- `autoload/linny.vim` (`linny#Init`), `autoload/linny_menu.vim` (event dispatch),
  `lua/linny/notebook.lua`, new `lua/linny/archive.lua`, `lua/linny/menu/render.lua`,
  `lua/linny/menu/widgets.lua`, `lua/linny/menu/views.lua`, `doc/linny.txt`, tests.
