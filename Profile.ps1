# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
$MaximumHistoryCount = 512
$FormatEnumerationLimit = 100

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------

# PSReadline provides Bash like keyboard cursor handling
if ($host.Name -eq 'ConsoleHost')
{
	Import-Module PSReadline

	Set-PSReadLineOption -MaximumHistoryCount 4000
	Set-PSReadlineOption -ShowToolTips:$true

	# With these bindings, up arrow/down arrow will work like
	# PowerShell/cmd if the current command line is blank. If you've
	# entered some text though, it will search the history for commands
	# that start with the currently entered text.
	Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
	Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

	Set-PSReadlineKeyHandler -Key "Tab" -Function "MenuComplete"
	Set-PSReadlineKeyHandler -Chord 'Shift+Tab' -Function "Complete"
}

# fzf is a fuzzy file finder, and will provide fuzzy location searching
# when using Ctrl+T, and will provide better reverse command searching via
# Ctrl-R.
Import-Module PSFzf -ArgumentList 'Ctrl+T','Ctrl+R'

# Git support
Import-Module Git
Initialize-Git
Import-Module Posh-Git

# Colorize directory output
Import-Module PSColor

# Utils
Import-Module StreamUtils
Import-Module StringUtils
Import-Module Profile

# ---------------------------------------------------------------------------
# Custom Aliases
# ---------------------------------------------------------------------------
set-alias unset      remove-variable
set-alias mo         measure-object
set-alias eval       invoke-expression
set-alias n          'C:\Program Files (x86)\Notepad++\notepad++.exe'
set-alias vi         vim.exe

# ---------------------------------------------------------------------------
# Visuals
# ---------------------------------------------------------------------------
#set-variable -Scope Global WindowTitle ''

function prompt
{
	$local:pathObj = (get-location)
	$local:path    = $pathObj.Path
	$local:drive   = $pathObj.Drive.Name

	if(!$drive) # if there's no drive, it might be a special path (eg, a UNC path)
	{
		if($path.contains('::')) # if it's a special path, get the provider's path name
		{
			$path = $pathObj.ProviderPath
		}
		if($path -match "^\\\\([^\\]+)\\") # if it's a UNC path, use the server name as the drive
		{
			$drive = $matches[1]
		}
	}
	
	$local:title = $path
	if($WindowTitle) { $title += " - $WindowTitle" }

	$path = [IO.Path]::GetFileName($path)
	if(!$path) { $path = '\' }

	if($NestedPromptLevel)
	{
		Write-Host -NoNewline -ForeGroundColor Green "$NestedPromptLevel-";
	}
	
	$private:h = @(Get-History);
	$private:nextCommand = $private:h[$private:h.Count - 1].Id + 1;
	Write-Host -NoNewline -ForeGroundColor Red "${private:nextCommand}|";	 
	
	Write-Host -NoNewline -ForeGroundColor Blue "${drive}";
	Write-Host -NoNewline -ForeGroundColor White ":";
	Write-Host -NoNewline -ForeGroundColor White "$path";
	
	# Show GIT Status, if loaded:
	if (Get-Command "Write-VcsStatus" -ErrorAction SilentlyContinue)
	{
		$realLASTEXITCODE = $LASTEXITCODE
		Write-VcsStatus
		$global:LASTEXITCODE = $realLASTEXITCODE
	}

	$host.ui.rawUi.windowTitle = $title
	
	return ">";
}

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

# starts a new execution scope
function Start-NewScope 
{
	param($Prompt = $null) Write-Host "Starting New Scope"
	if ($Prompt -ne $null)
	{
		if ($Prompt -is [ScriptBlock])
		{
			$null = New-Item function:Prompt -Value $Prompt -force
		}
		else
		{
			function Prompt {"$Prompt"}
		}
	}
	$host.EnterNestedPrompt()
}

# 'cause shutdown commands are too long and hard to type...
function Restart
{
	shutdown /r /t 1
}

# --------------------------------------------------------------------------
# EXO Helpers
# --------------------------------------------------------------------------

function dev($project)
{
	cd "$(get-content Env:INETROOT)\sources\dev\$project"
}

function test($project)
{
	cd "$(get-content Env:INETROOT)\sources\test\$project"
}

function bcc
{
	build -Cc
}
