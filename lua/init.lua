-- /velero-nvim/lua/init.lua
local M = {}

function M.setup()
	-- Define Velero commands
	vim.api.nvim_create_user_command("VeleroCreateBackup", function()
		require("modules.velero").create_backup()
	end, {})

	vim.api.nvim_create_user_command("VeleroDescribeBackup", function()
		require("modules.velero").describe_backup()
	end, {})

	vim.api.nvim_create_user_command("VeleroRestoreBackup", function()
		require("modules.velero").restore_backup()
	end, {})

	vim.api.nvim_create_user_command("VeleroDescribeRestore", function()
		require("modules.velero").describe_restore()
	end, {})
end

return M
