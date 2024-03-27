#!/usr/bin/pwsh

<#

This file is part of helpimnotdrowning's PwshUtils.

helpimnotdrowning's PwshUtils is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

helpimnotdrowning's PwshUtils is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License along with
helpimnotdrowning's PwshUtils. If not, see <https://www.gnu.org/licenses/>. 

#>

### Experimental wt GUI shell command completion via
# https://github.com/microsoft/terminal/wiki/Experimental-Shell-Completion-Menu ###
function Send-Completions {
	$CommandLine = ""
	$CursorIndex = 0
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$CommandLine, [ref]$CursorIndex)
	$CompletionPrefix = $CommandLine

	$Result = "`e]633;Completions"
	if ($CompletionPrefix.Length -gt 0) {
		$Completions = TabExpansion2 -InputScript $CompletionPrefix -CursorColumn $CursorIndex
		
		if ($null -ne $Completions.CompletionMatches) {
			$Result += ";$($Completions.ReplacementIndex);$($Completions.ReplacementLength);$($CursorIndex);"
			$Result += $Completions.CompletionMatches | ConvertTo-Json -Compress
			
		}
	}
	
	$Result += "`a"

	Write-Host -NoNewLine $Result
}

function Set-MappedKeyHandlers {
	# Terminal suggest - always on keybindings
	Set-PSReadLineKeyHandler -Chord 'F12,b' -ScriptBlock {
		Send-Completions
		
	}
}

### Windows Terminal shell integration via
# https://devblogs.microsoft.com/commandline/shell-integration-in-the-windows-terminal/ ###

$Global:LastHistoryId__ = -1

function Global:Get-TerminalLastExitCode__ {
	if ($? -eq $True) {
		return 0
        
	}
    
	if ("$LASTEXITCODE" -ne "") {
        return $LASTEXITCODE
        
    }
    
	return -1
	
}

### OWN CODE FOR A BIT ###

function Enable-OMP {
	param (
		[String] $ThemePath
		
	)
	
	# windows termianl needs to make sure psreadline is here
	if (Get-Module -Name PSReadLine) {
		Set-MappedKeyHandlers
		
	} else {
		Write-Host "PsReadline was disabled. Shell Completion was not enabled."
		
	}
	
	# nuke ompprompt beforehand!
	if (Test-Path Function:/ompprompt) {
		Remove-Item Function:/ompprompt
		
	}
	
	# run OMP
	if ($ThemePath) {
		oh-my-posh init pwsh --config $ThemePath | Invoke-Expression
		
	} else {
		oh-my-posh init pwsh | Invoke-Expression
		
	}
	
	# wait: why script: scope?
	#	well, setting the prompt functions scope to global: isn't enough to
	# 	modify the parent scope (the interactive shell itself). apparently
	#	script: scope works for this AND scope can be set by renaming the
	#	function, isn't that neat!
	
	# save for later
	Rename-Item Function:/prompt script:ompprompt
	
	# MICROSOFT CODE BELOW
	
	# prompt wrapper with escape codes for signifying end and start of prompt
	function script:prompt {	
		# First, emit a mark for the _end_ of the previous command.
		$LastHistoryEntry = $(Get-History -Count 1)
		
		# Skip finishing the command if the first command has not yet started
		if ($Global:LastHistoryId__ -ne -1) {
			if ($LastHistoryEntry.Id -eq $Global:LastHistoryId__) {
			# Don't provide a command line or exit code if there was no history
			# entry (eg. ^C, enter on no command)
				$out += "`e]133;D`a"
				
			} else {
				$out += "`e]133;D;$(Get-TerminalLastExitCode__)`a"
				
			}
		}
		
		$out += "`e]133;A`a$(ompprompt)`e]133;B`a"

		$Global:LastHistoryId__ = $LastHistoryEntry.Id

		return $out
		
	}
	
	# END MS CODE

}
