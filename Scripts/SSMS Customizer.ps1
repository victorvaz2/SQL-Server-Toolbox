<# File and backup file variables to be used later #>
$SSMSSeetingsFile = "$Env:userprofile\Documents\Visual Studio 2015\Settings\SQL Server Management Studio\NewSettings.vssettings"
$SSMSSeetingsBackupFile = "$Env:userprofile\Documents\Visual Studio 2015\Settings\SQL Server Management Studio\NewSettings.vssettings.backup"

<# Copy out file to a backup file #>
Copy-Item -Path $SSMSSeetingsFile -Destination $SSMSSeetingsBackupFile

<# Import our XML File into PowerShell #>
$XMLDocument = [XML](Get-Content $SSMSSeetingsFile)

<# Enabling line numbers on editor #>
$LineNode = ((($XMLDocument.UserSettings.ToolsOptions.ToolsOptionsCategory | `
Where-Object {$_.name -eq "TextEditor"}).ToolsOptionsSubCategory | `
Where-Object {$_.Name -eq "SQL"}).PropertyValue | `
Where-Object {$_.Name -eq "ShowLineNumbers"})

$LineNode.'#text' = 'true'

<# Add sp_whoisactive to ctrl+3 #>
$LineNode = ((($XMLDocument.UserSettings.Category | `
Where-Object {$_.name -eq "Environment_Group"}).Category | `
Where-Object {$_.name -eq "Environment_KeyBindings"}).KeyboardShortcuts.UserShortcuts.Shortcut | `
Where-Object {$_.Command -eq "Query.CustomSP2"}) <# Checks if the hotkey was previously changed (will fail if it has) #>
$LineNode.Command = "Query.sp_whoisactive"

<# Save the file#>
$XMLDocument.Save($SSMSSeetingsFile)
