local M = {}

function M.select_from_list(prompt, items, callback)
	require('telescope.pickers').new({}, {
		prompt_title = prompt,
		finder = require('telescope.finders').new_table {
			results = items,
		},
		sorter = require('telescope.config').values.generic_sorter({}),
		attach_mappings = function(_, map)
			map('i', '<CR>', function(prompt_bufnr)
				local selection = require('telescope.actions.state').get_selected_entry()
				require('telescope.actions').close(prompt_bufnr)
				callback(selection[1])
			end)
			return true
		end,
	}):find()
end

function M.input(prompt, callback)
	vim.ui.input({ prompt = prompt .. ": " }, function(input)
		if input then
			callback(input)
		else
			print("Input cancelled")
		end
	end)
end

return M
