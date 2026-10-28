## 1. Config

- [x] 1.1 `linny.notebook.load_config()` reads `lindenConfig/notebook.yml` into `g:linny_notebook_config`
- [x] 1.2 Call it from `linny#Init`

## 2. Archive module

- [x] 2.1 `lua/linny/archive.lua`: field, default_hidden, is_archived, hiding_active, is_visible, toggle, archived_docs

## 3. Menu

- [x] 3.1 L2 listing skips hidden documents; shows hidden count and `a` toggle
- [x] 3.2 `starred_documents` and `recently_modified_documents` skip hidden documents
- [x] 3.3 New widget `archived_documents`, dispatched from `views.render`
- [x] 3.4 `togglearchived` event in `linny_menu#` dispatch

## 4. Docs and tests

- [x] 4.1 `doc/linny.txt`: notebook.yml, toggle, widget
- [x] 4.2 Tests: archive module, notebook config loading, render/widget filtering
- [x] 4.3 CHANGELOG entry
- [x] 4.4 Full test suite: no new failures
