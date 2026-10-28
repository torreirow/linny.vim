# archive-hiding Specification

## Purpose
TBD - created by archiving change add-archive-hiding. Update Purpose after archive.

## Requirements

### Requirement: Notebook config is loaded at init

`linny#Init` SHALL read `lindenConfig/notebook.yml` into `g:linny_notebook_config`, and
SHALL set it to an empty dictionary when the file does not exist.

#### Scenario: No notebook.yml

- **WHEN** the notebook has no `lindenConfig/notebook.yml`
- **THEN** `g:linny_notebook_config` is `{}` and no document is hidden

#### Scenario: notebook.yml present

- **WHEN** `notebook.yml` contains `archive: { default_hidden: true }`
- **THEN** `g:linny_notebook_config.archive.default_hidden` is `v:true`

### Requirement: Archived documents are hidden from listings

When `archive.default_hidden` is `true` and `g:linny_show_archived` is not set, the
menu SHALL omit documents whose front-matter value for `archive.field` (default
`archive`) is boolean `true` from L2 term listings, the `starred_documents` widget and
the `recently_modified_documents` widget.

#### Scenario: Archived document in a term

- **WHEN** `week-3.md` has `archive: true`, belongs to term `customer/technative`, and
  hiding is active
- **THEN** the L2 menu for `customer/technative` does not list `week-3.md`

#### Scenario: String value is not archived

- **WHEN** a document has `archive: "true"`
- **THEN** it is listed

#### Scenario: Custom field

- **WHEN** `notebook.yml` sets `archive: { field: archived, default_hidden: true }`
- **THEN** a document with `archived: true` is hidden and one with only `archive: true`
  is listed

#### Scenario: Recent documents keep their count

- **WHEN** the `recently_modified_documents` widget has `number: 5` and two of the five
  most recent files are archived
- **THEN** the widget lists the five most recent non-archived documents

### Requirement: Archived documents can be shown

The L2 menu SHALL show the number of hidden archived documents and a toggle on hotkey
`a` that flips `g:linny_show_archived` and re-renders. A level-0 view MAY use widget
type `archived_documents`, which SHALL list every archived document.

#### Scenario: Toggle in a term

- **WHEN** hiding is active, a term has one hidden archived document and the user
  presses `a`
- **THEN** the menu re-renders with the archived document listed and a `<hide
  archived>` toggle

#### Scenario: Archived widget

- **WHEN** the root view has a widget `type: archived_documents`
- **THEN** it lists every document whose archive field is `true`, regardless of the
  toggle
