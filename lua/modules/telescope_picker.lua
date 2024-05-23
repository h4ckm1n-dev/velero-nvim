-- modules/telescope_picker.lua

local M = {}

local function invoke_callback(callback, value)
	if type(callback) == "function" then
		callback(value)
	else
		print("Error: Callback is not a function.")
	end
end

function M.select_from_list(prompt_title, list, callback)
	if type(list) ~= "table" or #list == 0 then
		print("Error: List must be a non-empty table.")
		return
	end

	if type(callback) ~= "function" then
		print("Error: Callback must be a function.")
		return
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = prompt_title,
			finder = require("telescope.finders").new_table({ results = list }),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
					require("telescope.actions").close(prompt_bufnr)
					if selection then
						invoke_callback(callback, selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

function M.multi_select_from_list(prompt_title, list, callback)
	if type(list) ~= "table" or #list == 0 then
		print("Error: List must be a non-empty table.")
		return
	end

	if type(callback) ~= "function" then
		print("Error: Callback must be a function.")
		return
	end

	local action_state = require("telescope.actions.state")
	local actions = require("telescope.actions")

	require("telescope.pickers")
		.new({}, {
			prompt_title = prompt_title,
			finder = require("telescope.finders").new_table({
				results = list,
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local current_picker = action_state.get_current_picker(prompt_bufnr)
					local selections = current_picker:get_multi_selection()
					local selected_items = {}
					for _, entry in ipairs(selections) do
						table.insert(selected_items, entry.value)
					end
					actions.close(prompt_bufnr)
					if #selected_items > 0 then
						invoke_callback(callback, selected_items)
					end
				end)
				map("i", "<Tab>", function(prompt_bufnr)
					local current_picker = action_state.get_current_picker(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					current_picker._multi:toggle(selection)
					current_picker:refresh(false)
				end)
				return true
			end,
		})
		:find()
end

function M.input(prompt_title, callback)
	if type(callback) ~= "function" then
		print("Error: Callback must be a function.")
		return
	end

	local input = vim.fn.input(prompt_title .. ": ")
	if input ~= "" then
		invoke_callback(callback, input)
	else
		print("Error: " .. prompt_title .. " cannot be empty.")
	end
end

return M
