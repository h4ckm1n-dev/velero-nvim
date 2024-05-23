local Command = require("modules.command")
local TelescopePicker = require("modules.telescope_picker")

local Velero = {}

local function log_error(message)
	print("Error: " .. message)
end

local function fetch_namespaces()
	-- Run the shell command to get namespaces
	local namespaces, err = Command.run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")

	-- Check if the command was successful
	if not namespaces or namespaces == "" then
		log_error("Failed to fetch namespaces: " .. (err or "No namespaces found."))
		return nil
	end

	-- Split the namespaces into a list
	local namespace_list = vim.split(namespaces, "\n", { trimempty = true })

	-- Check if the list is empty
	if #namespace_list == 0 then
		log_error("No namespaces available.")
		return nil
	end

	return namespace_list
end

local function fetch_backups()
	-- Run the shell command to get backups
	local backups, err = Command.run_shell_command("velero backup get -o name")

	-- Check if the command was successful
	if not backups or backups == "" then
		log_error("Failed to fetch backups: " .. (err or "No backups found."))
		return nil
	end

	-- Split the backups into a list
	local backup_list = vim.split(backups, "\n", { trimempty = true })

	-- Check if the list is empty
	if #backup_list == 0 then
		log_error("No backups available.")
		return nil
	end

	return backup_list
end

function Velero.create_backup()
	local namespace_list = fetch_namespaces()
	if not namespace_list then
		return
	end

	TelescopePicker.select_from_list("Select Namespace for Backup", namespace_list, function(selected_namespace)
		TelescopePicker.input("Enter Backup Name", function(backup_name)
			local result, err = Command.run_shell_command(
				string.format("velero backup create %s --include-namespaces=%s", backup_name, selected_namespace)
			)
			if result then
				print("Velero backup created successfully: \n" .. result)
			else
				log_error("Failed to create Velero backup: " .. (err or "Unknown error"))
			end
		end)
	end)
end

function Velero.describe_backup()
	TelescopePicker.input("Enter Backup Name to Describe", function(backup_name)
		local result, err = Command.run_shell_command(string.format("velero backup describe %s", backup_name))
		if result then
			print("Velero backup description: \n" .. result)
		else
			log_error("Failed to describe Velero backup: " .. (err or "Unknown error"))
		end
	end)
end

function Velero.restore_backup()
	local backup_list = fetch_backups()
	if not backup_list then
		return
	end

	TelescopePicker.select_from_list("Select Backup to Restore", backup_list, function(selected_backup)
		TelescopePicker.input("Enter Restore Name", function(restore_name)
			local result, err = Command.run_shell_command(
				string.format("velero restore create %s --from-backup=%s", restore_name, selected_backup)
			)
			if result then
				print("Velero restore created successfully: \n" .. result)
			else
				log_error("Failed to create Velero restore: " .. (err or "Unknown error"))
			end
		end)
	end)
end

function Velero.describe_restore()
	TelescopePicker.input("Enter Restore Name to Describe", function(restore_name)
		local result, err = Command.run_shell_command(string.format("velero restore describe %s", restore_name))
		if result then
			print("Velero restore description: \n" .. result)
		else
			log_error("Failed to describe Velero restore: " .. (err or "Unknown error"))
		end
	end)
end

return Velero
