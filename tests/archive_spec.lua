-- Tests for archive hiding (Linden Index Spec 0.4.0 §5.4)
-- Run with: nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

--- Build a throwaway notebook with an index, returns its base path
local function make_notebook(opts)
  local base = vim.fn.tempname()
  vim.fn.mkdir(base .. '/content', 'p')
  vim.fn.mkdir(base .. '/lindenConfig', 'p')
  vim.fn.mkdir(base .. '/lindenIndex/customer/acme', 'p')
  vim.fn.mkdir(base .. '/state', 'p')

  local props = {
    ['live.md'] = { title = 'Live doc', customer = 'acme' },
    ['old.md'] = { title = 'Old doc', customer = 'acme', archive = true },
    ['stringy.md'] = { title = 'Stringy doc', customer = 'acme', archive = 'true' },
    ['other.md'] = { title = 'Other doc', customer = 'acme', archived = true },
  }
  vim.fn.writefile({ vim.json.encode(props) }, base .. '/lindenIndex/_index_docs_with_props.json')
  vim.fn.writefile({ vim.json.encode(vim.tbl_keys(props)) }, base .. '/lindenIndex/customer/acme/index.json')
  vim.fn.writefile({ vim.json.encode({ 'live.md', 'old.md' }) }, base .. '/lindenIndex/_index_docs_starred.json')

  -- Content files, oldest first so `ls -1t` lists old.md and other.md first
  local order = { 'live.md', 'stringy.md', 'other.md', 'old.md' }
  for i, f in ipairs(order) do
    local path = base .. '/content/' .. f
    vim.fn.writefile({ '---', 'title: ' .. f, '---' }, path)
    vim.uv.fs_utime(path, 1000000 + i * 100, 1000000 + i * 100)
  end

  if opts and opts.notebook_yml then
    vim.fn.writefile(opts.notebook_yml, base .. '/lindenConfig/notebook.yml')
  end

  vim.g.linny_open_notebook_path = base
  vim.g.linny_path_wiki_content = base .. '/content'
  vim.g.linny_path_wiki_config = base .. '/lindenConfig'
  vim.g.linny_index_path = base .. '/lindenIndex'
  vim.g.linny_state_path = base .. '/state'
  vim.g.linny_cache_index_docs_titles = {
    ['live.md'] = 'Live doc', ['old.md'] = 'Old doc',
    ['stringy.md'] = 'Stringy doc', ['other.md'] = 'Other doc',
  }
  return base
end

--- Texts of the rendered menu items
local function menu_texts()
  local texts = {}
  for _, item in ipairs(vim.t.linny_menu_items or {}) do
    table.insert(texts, item.text)
  end
  return texts
end

local function has_text(texts, needle)
  for _, t in ipairs(texts) do
    if string.find(t, needle, 1, true) then
      return true
    end
  end
  return false
end

describe("linny.archive", function()
  local archive

  before_each(function()
    package.loaded['linny.archive'] = nil
    archive = require('linny.archive')
    vim.g.linny_notebook_config = nil
    vim.g.linny_show_archived = nil
  end)

  describe("without notebook config", function()
    it("uses field 'archive' and hides nothing", function()
      assert.are.equal('archive', archive.field())
      assert.is_false(archive.default_hidden())
      assert.is_false(archive.hiding_active())
      assert.is_true(archive.is_visible({ archive = true }))
    end)

    it("still recognises archived documents", function()
      assert.is_true(archive.is_archived({ archive = true }))
      assert.is_false(archive.is_archived({ title = 'x' }))
      assert.is_false(archive.is_archived(nil))
    end)
  end)

  describe("with default_hidden", function()
    before_each(function()
      vim.g.linny_notebook_config = { archive = { default_hidden = true } }
    end)

    it("hides archived documents", function()
      assert.is_true(archive.hiding_active())
      assert.is_false(archive.is_visible({ archive = true }))
      assert.is_true(archive.is_visible({ archive = false }))
      assert.is_true(archive.is_visible(nil))
    end)

    it("does not treat the string 'true' as archived", function()
      assert.is_false(archive.is_archived({ archive = 'true' }))
      assert.is_true(archive.is_visible({ archive = 'true' }))
    end)

    it("toggle_show shows and hides again", function()
      archive.toggle_show()
      assert.is_false(archive.hiding_active())
      assert.is_true(archive.is_visible({ archive = true }))
      archive.toggle_show()
      assert.is_true(archive.hiding_active())
    end)
  end)

  describe("with a custom field", function()
    it("only the configured field archives", function()
      vim.g.linny_notebook_config = { archive = { field = 'archived', default_hidden = true } }
      assert.are.equal('archived', archive.field())
      assert.is_true(archive.is_archived({ archived = true }))
      assert.is_false(archive.is_archived({ archive = true }))
    end)
  end)

  describe("filter_visible and archived_docs", function()
    local props = {
      ['a.md'] = { archive = true },
      ['b.md'] = {},
      ['c.md'] = { archive = true },
    }

    it("returns the list unchanged when hiding is off", function()
      local files = { 'a.md', 'b.md' }
      assert.are.same(files, archive.filter_visible(files, props))
    end)

    it("drops archived files and keeps order when hiding is on", function()
      vim.g.linny_notebook_config = { archive = { default_hidden = true } }
      assert.are.same({ 'b.md', 'unknown.md' }, archive.filter_visible({ 'a.md', 'b.md', 'unknown.md', 'c.md' }, props))
    end)

    it("lists archived documents sorted", function()
      assert.are.same({ 'a.md', 'c.md' }, archive.archived_docs(props))
    end)
  end)
end)

describe("linny.notebook.load_config", function()
  local notebook

  before_each(function()
    package.loaded['linny.notebook'] = nil
    notebook = require('linny.notebook')
  end)

  it("sets an empty dict when notebook.yml is missing", function()
    make_notebook()
    notebook.load_config()
    assert.are.equal(0, vim.fn.eval('len(g:linny_notebook_config)'))
    assert.are.equal(4, vim.fn.eval('type(g:linny_notebook_config)'), "should be a dict, not a list")
  end)

  it("parses notebook.yml", function()
    make_notebook({ notebook_yml = { 'archive:', '  field: archived', '  default_hidden: true' } })
    notebook.load_config()
    assert.are.equal('archived', vim.g.linny_notebook_config.archive.field)
    assert.is_true(vim.g.linny_notebook_config.archive.default_hidden)
  end)
end)

describe("archive hiding in the menu", function()
  local render, widgets, archive

  before_each(function()
    for _, m in ipairs({ 'linny.archive', 'linny.menu.render', 'linny.menu.widgets', 'linny.menu.items', 'linny.menu.views', 'linny.menu.state' }) do
      package.loaded[m] = nil
    end
    render = require('linny.menu.render')
    widgets = require('linny.menu.widgets')
    archive = require('linny.archive')
    vim.t.linny_menu_items = {}
    vim.t.linny_menu = nil
    vim.g.linny_show_archived = nil
  end)

  describe("level2", function()
    it("lists archived documents when notebook.yml is absent", function()
      make_notebook()
      require('linny.notebook').load_config()
      render.level2('customer', 'acme')
      local texts = menu_texts()
      assert.is_true(has_text(texts, 'Old doc'))
      assert.is_false(has_text(texts, '<show archived>'))
    end)

    it("hides archived documents and offers the toggle", function()
      make_notebook({ notebook_yml = { 'archive:', '  default_hidden: true' } })
      require('linny.notebook').load_config()
      render.level2('customer', 'acme')
      local texts = menu_texts()
      assert.is_true(has_text(texts, 'Live doc'))
      assert.is_true(has_text(texts, 'Stringy doc'))
      assert.is_true(has_text(texts, 'Other doc'))
      assert.is_false(has_text(texts, 'Old doc'))
      assert.is_true(has_text(texts, '1 archived hidden'))
      assert.is_true(has_text(texts, '<show archived>'))
    end)

    it("shows archived documents after toggling", function()
      make_notebook({ notebook_yml = { 'archive:', '  default_hidden: true' } })
      require('linny.notebook').load_config()
      archive.toggle_show()
      render.level2('customer', 'acme')
      local texts = menu_texts()
      assert.is_true(has_text(texts, 'Old doc'))
      assert.is_true(has_text(texts, '<hide archived>'))
    end)

    it("honours a custom archive field", function()
      make_notebook({ notebook_yml = { 'archive:', '  field: archived', '  default_hidden: true' } })
      require('linny.notebook').load_config()
      render.level2('customer', 'acme')
      local texts = menu_texts()
      assert.is_true(has_text(texts, 'Old doc'))
      assert.is_false(has_text(texts, 'Other doc'))
    end)
  end)

  describe("widgets", function()
    it("starred_docs_list skips archived documents", function()
      make_notebook({ notebook_yml = { 'archive:', '  default_hidden: true' } })
      require('linny.notebook').load_config()
      assert.are.same({ 'live.md' }, widgets.starred_docs_list())
    end)

    it("recent_files returns the requested number of non-archived files", function()
      make_notebook({ notebook_yml = { 'archive:', '  default_hidden: true' } })
      require('linny.notebook').load_config()
      assert.are.same({ 'other.md', 'stringy.md' }, widgets.recent_files(2))
    end)

    it("recent_files is unchanged without notebook.yml", function()
      make_notebook()
      require('linny.notebook').load_config()
      assert.are.same({ 'old.md', 'other.md' }, widgets.recent_files(2))
    end)

    it("archived_documents widget lists every archived document", function()
      make_notebook({ notebook_yml = { 'archive:', '  default_hidden: true' } })
      require('linny.notebook').load_config()
      widgets.archived_documents({})
      local texts = menu_texts()
      assert.is_true(has_text(texts, 'Old doc'))
      assert.is_false(has_text(texts, 'Live doc'))
    end)
  end)
end)
