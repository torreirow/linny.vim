## Context

Spec 0.4.0 §5.4: a document is archived when its front-matter value for
`archive.field` is the boolean `true`; the index stays complete; clients SHOULD hide
archived documents when `default_hidden: true` and SHOULD offer a way to show them.
`_index_docs_with_props.json` already contains every document's front matter.

## Goals / Non-Goals

Goals: hide archived documents in listings; a way to see them; zero change without
config. Non-goals: archived terms (L2 `archive: true`), indexer changes, opening an
archived document directly (unaffected).

## Decisions

### Decision 1: Config loaded once, in `linny#Init`
`notebook.yml` is read with the existing `linny#parse_yaml_to_dict` and stored in
`g:linny_notebook_config` (`{}` when absent). Switching notebooks re-runs `linny#Init`,
so the config follows the open notebook. `linny.notebook.init()` stays pure Lua.

### Decision 2: One `linny.archive` module, everything else asks it
All listings call `archive.is_visible(front_matter)`. One place decides, so the field
name and the toggle cannot drift between widgets.

### Decision 3: Session toggle, not persisted
`g:linny_show_archived` (default off) flips hiding for the session. Policy is the
notebook's (`default_hidden`); peeking at the archive is a momentary need.

### Decision 4: Recent documents filtered against the props index
`recently_modified_documents` lists files with `ls -1t`, not the index. When hiding is
active it lists all files, drops archived ones using the props index, then takes the
configured number, so the widget still shows `number` documents.

### Decision 5: Only boolean `true` archives
`archive: "true"` (string) does not hide a document, per spec.

## Risks / Trade-offs

- Documents not yet in the index (just created) have no props entry: they are treated
  as not archived, i.e. shown. Safe default.
