local Command = require("modules.command")
local TelescopePicker = require("modules.telescope_picker")

local Velero = {}

local function log_error(message)
	print("Error: " .. message)
end

local function fetch_namespaces()
	local namespaces, err = Command.run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")
	if not namespaces or namespaces == "" then
		log_error("Failed to fetch namespaces: " .. (err or "No namespaces found."))
		return nil
	end
	local namespace_list = vim.split(namespaces, "\n", { trimempty = true })
	return namespace_list
end

local function fetch_resources(namespace)
	local resources, err = Command.run_shell_command("kubectl get all -n " .. namespace .. " -o name")
	if not resources or resources == "" then
		log_error("Failed to fetch resources: " .. (err or "No resources found."))
		return nil
	end
	local resource_list = vim.split(resources, "\n", { trimempty = true })
	return resource_list
end

local function fetch_backups()
	local backups, err = Command.run_shell_command("velero backup get -o name")
	if not backups or backups == "" then
		log_error("Failed to fetch backups: " .. (err or "No backups found."))
		return nil
	end
	local backup_list = vim.split(backups, "\n", { trimempty = true })
	return backup_list
end

function Velero.create_backup()
	local namespace_list = fetch_namespaces()
	if not namespace_list or vim.tbl_isempty(namespace_list) then
		log_error("Namespace list is empty or nil.")
		return
	end

	TelescopePicker.select_from_list("Select Namespace for Backup", namespace_list, function(selected_namespace)
		TelescopePicker.select_from_list("Do you want to select specific resources? (yes/no)", { "yes", "no" },
			function(user_choice)
				if user_choice == "yes" then
					local resource_list = fetch_resources(selected_namespace)
					if not resource_list or vim.tbl_isempty(resource_list) then
						log_error("Resource list is empty or nil.")
						return
					end

					TelescopePicker.select_from_list("Select Resources for Backup", resource_list,
						function(selected_resource)
							TelescopePicker.input("Enter Backup Name", function(backup_name)
								local cmd = string.format(
									"velero backup create %s --include-namespaces=%s --include-resources=%s",
									backup_name,
									selected_namespace,
									selected_resource
								)
								local result, err = Command.run_shell_command(cmd)
								if result then
									print("Velero backup created successfully: \n" .. result)
								else
									log_error("Failed to create Velero backup: " .. (err or "Unknown error"))
								end
							end)
						end)
				else
					TelescopePicker.input("Enter Backup Name", function(backup_name)
						local cmd = string.format(
							"velero backup create %s --include-namespaces=%s",
							backup_name,
							selected_namespace
						)
						local result, err = Command.run_shell_command(cmd)
						if result then
							print("Velero backup created successfully: \n" .. result)
						else
							log_error("Failed to create Velero backup: " .. (err or "Unknown error"))
						end
					end)
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
	if not backup_list or vim.tbl_isempty(backup_list) then
		log_error("Backup list is empty or nil.")
		return
	end

	TelescopePicker.select_from_list("Select Backup to Restore", backup_list, function(selected_backup)
		local namespace_list = fetch_namespaces()
		if not namespace_list or vim.tbl_isempty(namespace_list) then
			log_error("Namespace list is empty or nil.")
			return
		end

		TelescopePicker.select_from_list("Select Namespace to Restore To", namespace_list, function(target_namespace)
			local resource_list = fetch_resources(target_namespace)
			if not resource_list or vim.tbl_isempty(resource_list) then
				log_error("Resource list is empty or nil.")
				return
			end

			TelescopePicker.select_from_list("Select Resources to Restore", resource_list, function(selected_resource)
				TelescopePicker.input("Enter Restore Name", function(restore_name)
					local cmd = string.format(
						"velero restore create %s --from-backup=%s --namespace-mappings=%s:%s --include-resources=%s",
						restore_name,
						selected_backup,
						selected_backup,
						target_namespace,
						selected_resource
					)
					local result, err = Command.run_shell_command(cmd)
					if result then
						print("Velero restore created successfully: \n" .. result)
					else
						log_error("Failed to create Velero restore: " .. (err or "Unknown error"))
					end
				end)
			end)
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
