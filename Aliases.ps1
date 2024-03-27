#!/usr/bin/pwsh

<#
This file is part of helpimnotdrowning's PwshUtils.

PwshUtils is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

PwshUtils is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
PwshUtils. If not, see <https://www.gnu.org/licenses/>.
#>

# Start process detached from current terminal
# Slightly broken on Linux: spamming ^C in the session this was function was
# called in while any other command is running *might* kill the spawned process
# I think this is a bug but I haven't reported it yet so /shrug
function Start-DetachedProcess {
	param (
		[String] $Executable,
		[String[]] $ArgumentList
		
	)
	
	$ArgString = $ArgumentList -join " "
	
	if ($IsLinux) {
		(bash -c "nohup $Executable $ArgString > /dev/null 2> /dev/null" &) | Out-Null
		
	} elseif ($IsMacOS) {
		(zsh -c "nohup $Executable $ArgString > /dev/null 2> /dev/null" &) | Out-Null
		
	} elseif ($IsWindows) {
		(Start-Process -WindowStyle Hidden -FilePath $Executable -ArgumentList $ArgString &) | Out-Null
		
	}
}

# Restart desktop environment
# Windows: restarts explorer
# KDE/Linux: restarts plasma
function Restart-DesktopEnvironment {
	if ($IsWindows) {
		Get-Process | Where-Object {$_.Path -match "C:\\WINDOWS\\explorer.exe"} | Stop-Process
		explorer
		
	} elseif ($IsKDELinux) {
		kquitapp5 plasmashell
		kstart5 plasmashell
		
	} else {
		Write-Error "Could not determine in-use desktop environment."
	
	}
}

# Get first occurance of command
function Get-RealCommand {
	return Get-Command -CommandType Application -TotalCount 1 @args
	
}

# Launch Intellij IDEA, with optional arguments passed along
function iidea {
	if ($IsWindows) {
		# installed as user, then pick last item to launch latest version (idk system path)
		$IDEAPath = "$((Get-Item "$env:LOCALAPPDATA/JetBrains/IntelliJ*")[-1])/bin/idea.bat"
		
	} elseif ($IsLinux) {
		# installed in opt, then pick last item to launch latest version
		$IDEAPath = "$((Get-Item "/opt/idea*")[-1])/bin/idea.sh"
		
	} elseif ($IsMacOS) {
		Write-Warning "Experimental! Attempting to launch IDEA, this might not work."
		
		# not mac user lole but it would be funny if this works
		$IDEAPath = "$((Get-Item "/Applications/Intellij*.app")[-1])/Contents/MacOS/idea"
		
	} else {
		Write-Error "Unsupported OS, IDEA start script location is unknown."
		
	}
	
	if (! (Test-Path $IDEAPath)) {
		Write-Error "Could not find IntelliJ IDEA start script." -ErrorAction Stop
		
	}
	
	Start-DetachedProcess -Executable $IDEAPath -ArgumentList $args
	
}

# Launch Intellij CLion, with optional arguments passed along
function clion {
	if ($IsWindows) {
		# installed as user, then pick last item to launch latest version (idk system path)
		$CLionPath = "$((Get-Item "$env:LOCALAPPDATA/JetBrains/CLion*")[-1])/bin/clion.bat"
		
	} elseif ($IsLinux) {
		# installed in opt, then pick last item to launch latest version
		$CLionPath = "$((Get-Item "/opt/clion*")[-1])/bin/clion.sh"
		
	} elseif ($IsMacOS) {
		Write-Warning "Experimental! Attempting to launch CLion, this might not work."
		
		# not mac user lole but it would be funny if this works
		$CLionPath = "$((Get-Item "/Applications/CLion*.app")[-1])/Contents/MacOS/clion"
		
	} else {
		Write-Error "Unsupported OS, CLion start script location is unknown."
		
	}
	
	if (! (Test-Path $CLionPath)) {
		Write-Error "Could not find CLion start script." -ErrorAction Stop
		
	}
	
	Start-DetachedProcess -Executable $CLionPath -ArgumentList $args
	
}

# Create a new project directory, optionally copying setting IDE settings from
# a different project over
function New-ProjectDir {
	param (
		[String] $Name,
		[String] $SettingsDir
		
	)
	
	$NewCode = ([String](1 + [int]((Get-ChildItem -Directory)[-1].Name -split "-")[0])).PadLeft(3, "0")
	$NewName = "$NewCode-$Name"
	
	New-Item -ItemType Directory -Path ./$NewName/
	
	if ($SettingsDir) {
		Copy-Item -Path $SettingsDir/.vscode/ -Destination ./$NewName/ -ErrorAction Ignore
		Copy-Item -Path $SettingsDir/.idea/ -Destination ./$NewName/ -ErrorAction Ignore
		
		Copy-Item -Path $SettingsDir/.clang-tidy -Destination ./$NewName/ -ErrorAction Ignore
		
		Copy-Item -Path $SettingsDir/*URH* -Destination ./$NewName/ -ErrorAction Ignore
		
		Copy-Item -Path $SettingsDir/Makefile -Destination ./$NewName/ -ErrorAction Ignore
		
	}
	
}

# Alias ls to Powershell's gci
# Does nothing on Windows since this is the default
Set-Alias -Name ls -Value Get-ChildItem -Force

# Invoke local ls binary with optional arguments (and color)
function uls {
	if ($MyInvocation.ExpectingInput) {
			$input | & (Get-RealCommand ls) --color=auto @args
		
	} else {
		& (Get-RealCommand ls) --color=auto @args
		
	}
}

# Invoke local grep binary with optional arguments (and color)
function grep {
	if ($MyInvocation.ExpectingInput) {
		$input | & (Get-RealCommand grep) --color=auto @args
		
	} else {
		& (Get-RealCommand grep) --color=auto @args
		
	}
}

# h(uman)grep (with color and convenience filename:line# at start), easier to
# read but less consumable
function hgrep {
	if ($MyInvocation.ExpectingInput) {
		$input | & (Get-RealCommand grep) -I -n -H --color=auto @args
		
	} else {
		& (Get-RealCommand grep) -I -n -H --color=auto @args
		
	}
}

# Follow growing file
function follow {
	if ($MyInvocation.ExpectingInput) {
		$input | & (Get-RealCommand tail) +1f @args
		
	} else {
		& (Get-RealCommand tail) +1f @args
		
	}
}

# Put pipeline input through $env:PAGER (or less when not present)
function page {
	if (! $MyInvocation.ExpectingInput) {
		Write-Error "The page function expects pipeline input!" -ErrorAction Stop
		
	}
	
	if ($env:PAGER) {
		$input | & "$env:PAGER"
		
	} else {
		$input | & (Get-RealCommand less)
		
	}
}

# Put specified file through $env:PAGER (or less when not present)
function fpage {
	if ($MyInvocation.ExpectingInput) {
		$input | Get-Content -Raw @args | page
		
	} else {
		Get-Content -Raw @args | page
		
	}
}

# Force cmdlets to output color (and other ANSI escape codes), even when the
# receiver doesn't support it (eg. pipeline)
# Can be placed in the middle of a pipeline when needed, this function passes
# along pipeline objects untouched (hopefully
function Start-AnsiOut {
	# "Ansi" = always show ansi escape codes, like --color=always
	$PSStyle.OutputRendering = "Ansi"
	
	# cast input enumerator to a workable list
	$i = @($input)
	
	if ($i.Count -gt 0) {
		# one-item list brought down to itself (uncontained in list)
		return $i
		
	}
	
	# empty list is null
	return $null
	
}

# Force cmdlets to output plaintext (no ANSI codes), even when the receiver
# supports it (eg. a tty)
# Can be placed in the middle of a pipeline when needed, this function passes
# along pipeline objects untouched (hopefully
function Stop-AnsiOut {
	# "PlainText" = never show ansi escape codes, like --color=never
	$PSStyle.OutputRendering = "PlainText"
	
	# cast input enumerator to a workable list
	$i = @($input)
	
	if ($i.Count -gt 0) {
		# one-item list brought down to itself (uncontained in list)
		return $i
		
	}
	
	# empty list is null
	return $null
	
}

# Restores normal ANSI escape functionality, only outputting when the receiver
# can support it
# Can be placed in the middle of a pipeline when needed, this function passes
# along pipeline objects untouched (hopefully
function Reset-AnsiOut {
	# "Host" = show ansi escape codes when tty, like --color=auto
	$PSStyle.OutputRendering = "Host"
	
	# cast input enumerator to a workable list
	$i = @($input)
	
	if ($i.Count -gt 0) {
		# one-item list brought down to itself (uncontained in list)
		return $i
		
	}
	
	# empty list is null
	return $null
	
}

