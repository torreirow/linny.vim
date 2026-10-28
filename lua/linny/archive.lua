-- linny/archive.lua - Notebook archive policy (Linden Index Spec 0.4.0 §5.4)
-- Decides whether a document is archived and whether listings should hide it.
-- Policy comes from lindenConfig/notebook.yml (g:linny_notebook_config); without it
-- nothing is hidden.

local M = {}

--- Archive section of the notebook config
--- @return table The `archive` table from notebook.yml, or {}
local function archive_config()
  local config = vim.g.linny_notebook_config
  if type(config) == 'table' and type(config.archive) == 'table' then
    return config.archive
  end
  return {}
end

--- Front-matter key that marks a document archived
--- @return string The field name (default "archive")
function M.field()
  local field = archive_config().field
  if type(field) == 'string' and field ~= '' then
    return field
  end
  return 'archive'
end

--- Whether the notebook hides archived documents by default
--- @return boolean
function M.default_hidden()
  return archive_config().default_hidden == true
end

--- Whether a document is archived
--- Only the boolean true archives; the string "true" does not.
--- @param front_matter table|nil Document front matter from the props index
--- @return boolean
function M.is_archived(front_matter)
  if type(front_matter) ~= 'table' then
    return false
  end
  return front_matter[M.field()] == true
end

--- Whether listings should currently hide archived documents
--- @return boolean
function M.hiding_active()
  return M.default_hidden() and vim.g.linny_show_archived ~= 1
end

--- Whether a document should appear in listings right now
--- @param front_matter table|nil Document front matter from the props index
--- @return boolean
function M.is_visible(front_matter)
  return not (M.hiding_active() and M.is_archived(front_matter))
end

--- Flip showing archived documents for this session
function M.toggle_show()
  if vim.g.linny_show_archived == 1 then
    vim.g.linny_show_archived = 0
  else
    vim.g.linny_show_archived = 1
  end
end

--- Load the props index (filename -> front matter)
--- @return table
function M.props_index()
  return vim.fn['linny#parse_json_file'](vim.g.linny_index_path .. '/_index_docs_with_props.json', {})
end

--- Keep only the files that should currently be listed
--- @param files table List of filenames
--- @param props table|nil Props index; loaded when nil and hiding is active
--- @return table Filtered list, original order
function M.filter_visible(files, props)
  if not M.hiding_active() then
    return files
  end
  props = props or M.props_index()
  local visible = {}
  for _, file in ipairs(files) do
    if M.is_visible(props[file]) then
      table.insert(visible, file)
    end
  end
  return visible
end

--- All archived documents in the notebook
--- @param props table|nil Props index; loaded when nil
--- @return table Sorted list of filenames
function M.archived_docs(props)
  props = props or M.props_index()
  local docs = {}
  for file, front_matter in pairs(props) do
    if M.is_archived(front_matter) then
      table.insert(docs, file)
    end
  end
  table.sort(docs)
  return docs
end

return M
