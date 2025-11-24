-- Simple C++ class file generator for Neovim (vertical split default)
-- Usage: :CppClass  (prompts for class name)
-- Install: save as ~/.config/nvim/lua/custom/cpp_class_generator.lua
-- Then require("custom.cpp_class_generator").setup({...}) in your config.

local M = {}

local function ensure_dir(path)
  if path == "" or path == "." then return true end
  vim.fn.mkdir(path, "p")
  return true
end

local function file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file" or false
end

local function write_file(path, content)
  local fh, err = io.open(path, "w")
  if not fh then return nil, err end
  fh:write(content)
  fh:close()
  return true
end

local function to_upper(s)
  return string.upper((s or ""):gsub("%W", "_"))
end

local function header_template(classname, opts)
  local ext = opts.header_extension or ".h"
  if opts.use_pragma_once then
    return table.concat({
      "#pragma once",
      "",
      "#include <iostream>",
      "",
      "class " .. classname .. " {",
      "public:",
      "  " .. classname .. "();",
      "  " .. classname .. "(const " .. classname .. "& obj);",
      "  ~" .. classname .. "();",
      "",
      "  " .. classname .. "& operator=(const " .. classname .. "& obj);",
      "",
      "private:",
      "  // TODO: add members",
      "};",
    "",
      "std::ostream&	operator<<(std::ostream& os, const "..classname.."&obj);",
      "",
      "",
    }, "\n")
  else
    local guard = to_upper(classname .. "_" .. (ext:gsub("^%.", "")) .. "_H")
    return table.concat({
      "#ifndef " .. guard,
      "#define " .. guard,
      "#include <iostream>",
      "",
      "class " .. classname .. " {",
      "public:",
      "  " .. classname .. "();",
      "  " .. classname .. "(const " .. classname .. "& obj);",
      "  ~" .. classname .. "();",
      "",
      "  " .. classname .. "& operator=(const " .. classname .. "& obj);",
      "",
      "private:",
      "  // TODO: add members",
      "};",
    "",
      "std::ostream&	operator<<(std::ostream& os, const "..classname.."&obj);",
      "",
      "#endif // " .. guard,
      "",
    }, "\n")
  end
end

local function source_template(classname, header_name)
  return table.concat({
    '#include "' .. header_name .. '"',
    "",
    classname .. "::" .. classname .. "(){",
    "",
	"}",
    "",
    classname .. "::" .. classname .. "(const " .. classname .. "& other){",
    "",
	"}",
    "",
    classname .. "::~" .. classname .. "(){",
    "",
	"}",
    "",
    classname .. "& " .. classname .. "::operator=(const " .. classname .. "& obj){",
    "",
	"}",
    "",
    "std::ostream&	operator<<(std::ostream& os, const "..classname.."&obj){",
	"	return(os << );",
	"}"
  }, "\n")
end

local function make_paths(classname, opts)
  local header_ext = opts.header_extension or ".h"
  local source_ext = opts.source_extension or ".cpp"

  local header_name = classname .. header_ext
  local source_name = classname .. source_ext

  local header_path = (opts.include_dir == "." or opts.include_dir == "" ) and header_name
                      or (opts.include_dir .. "/" .. header_name)
  local source_path = (opts.src_dir == "." or opts.src_dir == "" ) and source_name
                      or (opts.src_dir .. "/" .. source_name)

  return header_name, source_name, header_path, source_path
end

local function do_write_and_open(header_path, source_path, header_content, source_content, opts)
  local okh, errh = write_file(header_path, header_content)
  local oks, errs = write_file(source_path, source_content)
  if not okh or not oks then
    vim.notify("Error writing files: " .. tostring(errh or errs), vim.log.levels.ERROR)
    return
  end
  vim.notify("Created " .. header_path .. " and " .. source_path, vim.log.levels.INFO)
  if opts.open_after_create then
    -- open header then open source in vertical or horizontal split based on option
    vim.cmd("edit " .. header_path)
    if opts.open_in_vertical then
      vim.cmd("vsplit " .. source_path)
    else
      vim.cmd("split " .. source_path)
    end
  end
end

function M.create_class(opts)
  opts = opts or {}
  local default_opts = {
    header_extension = ".h",
    source_extension = ".cpp",
    include_dir = ".", -- root by default
    src_dir = ".",     -- root by default
    use_pragma_once = true,
    open_after_create = true,
    open_in_vertical = true, -- default to vertical split
  }
  opts = vim.tbl_extend("force", default_opts, opts)

  vim.ui.input({ prompt = "Class name: " }, function(classname)
    if not classname or classname:match("^%s*$") then
      vim.notify("Class creation cancelled", vim.log.levels.INFO)
      return
    end
    classname = classname:gsub("%s+", "") -- strip spaces

    local header_name, source_name, header_path, source_path = make_paths(classname, opts)

    ensure_dir(opts.include_dir)
    ensure_dir(opts.src_dir)

    local header_content = header_template(classname, opts)
    local source_content = source_template(classname, header_name)

    if file_exists(header_path) or file_exists(source_path) then
      vim.ui.input({ prompt = "Files exist. Overwrite? (y/N): " }, function(answer)
        if not answer or not answer:lower():match("^y") then
          vim.notify("Aborted: will not overwrite existing files", vim.log.levels.WARN)
          return
        end
        do_write_and_open(header_path, source_path, header_content, source_content, opts)
      end)
    else
      do_write_and_open(header_path, source_path, header_content, source_content, opts)
    end
  end)
end

function M.setup(user_opts)
  user_opts = user_opts or {}
  local default_opts = {
    header_extension = ".h",
    source_extension = ".cpp",
    include_dir = ".",   -- set to "." to write in project root
    src_dir = ".",
    use_pragma_once = true,
    open_after_create = true,
    open_in_vertical = true, -- vertical split by default
    keymap = "<leader>cg",
    create_cmd = "CppClass",
  }
  local opts = vim.tbl_extend("force", default_opts, user_opts)

  -- Create command
  vim.api.nvim_create_user_command(opts.create_cmd, function()
    M.create_class(opts)
  end, {})

  -- Create keymap
  if opts.keymap and opts.keymap ~= "" then
    vim.keymap.set("n", opts.keymap, function() vim.cmd(opts.create_cmd) end, { desc = "Generate C++ Class" })
  end
end

return M
