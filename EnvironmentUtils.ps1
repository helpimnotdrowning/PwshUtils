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

### via https://web.archive.org/web/20240120223848/https://gist.github.com/alphp/78fffb6d69e5bb863c76bbfc767effda ###

if ($IsWindows) {
	Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
	[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
	public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@
}

function Send-WindowsEnvSettingChange {
	if ($IsWindows) {
		$HWND_BROADCAST = [IntPtr] 0xffff;
		$WM_SETTINGCHANGE = 0x1a;
		$result = [UIntPtr]::Zero
		
		[Void] ([Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", 2, 5000, [ref] $result))
		
	} else {
		Write-Warning "The settings change broadcast is only available on Windows; restart your computer to see environment changes."
		
	}
}

### ###

function Set-EnvironmentVariable {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrWhiteSpace()]
		[ValidateScript({ -not ($_.Trim() -like "* *")})] # no whitespace!
		[String] $Name,
		
		[Parameter(Mandatory)]
		[String] $Value,
		
		[ValidateNotNullOrWhiteSpace()]
		[EnvironmentVariableTarget] $Scope
		
	)
	
	$Name = $Name.Trim()
	
	if ($IsWindows) {
		# this is performed as a job!
		# setting a User envvar would usually take (number of top-level gui
		# windows open) seconds! the underlying Win32 call apparently has the
		# "Blocking" flag enabled, which blocks while it waits for all of its
		# 1-second timeouts to expire!
		# see https://stackoverflow.com/a/4826777 for more information
		#
		# nvm this causes Problems
		[Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
		
	} elseif ($IsLinux) {
		Write-Warning "Environment changes are not standardized on Linux! Support is experimental and bash-only (probably)"
		
		$BashLine = "
# env change by helpimnotdrowing's PwshUtils/EnvironmentUtils on $(Get-Date -Format "yyyy-dd-MM HH:mm:ss K")
export $Name=`"$Value`"

"
		
		switch ($Scope) {
			EnvironmentVariableTarget::Process {
				[Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
				break
				
			}
			
			EnvironmentVariableTarget::Machine {
				# emulate Machine scope by adding to global profile in /etc
				Add-Content -Path /etc/profile -Value $BashLine
				break
				
			}
			
			EnvironmentVariableTarget::User {
				# check if env home exists (because apparently it might not???)
				# and expand ~ if it does not
				
				# WARNING: yes, this will duplicate the variable up to three
				# times. it sucks, but is apparently the only way.
				
				<#
				TODO: a better way by injecting a single line to profiles that
				loads a file like ".net_helpimnotdrowning.env" which contains
				the env vars and flags to avoid duplicating them
				something like
				[.profile]
				| if [ -z NHND_EXPORTED_94F766E7 ]; then --> unset, proceeds
				| 	export PATH="$PATH:/opt/app/bin"
				| 	export NHND_EXPORTED_94F766E7=1
				| fi
				--> NHND_EXPORTED_94F766E7 not set, PATH is ...:/opt/app/bin
				
				[.bash_profile]
				| if [ -z NHND_EXPORTED_94F766E7 ]; then --> set, skips, does not duplicate
				| 	export PATH="$PATH:/opt/app/bin"
				| 	export NHND_EXPORTED_94F766E7=1
				| fi
				--> NHND_EXPORTED_94F766E7 is set, PATH unmodified ...:/opt/app/bin
				instead of duplicated ...:/opt/app/bin:.../opt/app/bin
				#>
				
				# emulate User scope by adding to user profile in ~
				Add-Content -Path "$HOME/.bashrc" -Value $BashLine
				
				if (Test-Path -Path "$HOME/.profile") {
					Add-Content -Path "$HOME/.profile" -Value $BashLine
					
				}
				
				if (Test-Path -Path "$HOME/.bash_profile") {
					Add-Content -Path "$HOME/.bash_profile" -Value $BashLine
					
				}
				
				break
				
			}
		}
		
	} else {
		throw [System.PlatformNotSupportedException]::new(
			"Setting environment variables is currently only available for Windows and (partially) Linux"
		)
	}
}

function Get-EnvironmentVariable {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrWhiteSpace()]
		[String] $Name,
		
		[ValidateNotNullOrWhiteSpace()]
		[EnvironmentVariableTarget] $Scope = [EnvironmentVariableTarget]::Process
		
	)
	
	if (-not $IsWindows) {
		if ($Scope -ne [EnvironmentVariableTarget]::Process) {
			Write-Warning "Scope '$Scope' is not available on non-Windows platforms, ignoring and using 'Process' scope"
			
		}
		
		return [Environment]::GetEnvironmentVariable($Name, [EnvironmentVariableTarget]::Process)
		
	} else {
		return [Environment]::GetEnvironmentVariable($Name, $Scope)
		
	}
}

function Update-Path {
	if ($IsWindows) {
		$MachinePath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
		$UserPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
		
		if ($MachinePath[-1] -ne ";") {
			$MachinePath += ";"
		}
		
		$env:PATH = "$MachinePath$UserPath"
		
	} else {
		Write-Warning "The PATH cannot be updated on non-Windows platforms. To see changes, create a new terminal instance or restart your computer"
		
	}
}

### heavily modified via
# https://web.archive.org/web/20240207164403/https://devblogs.microsoft.com/scripting/use-powershell-to-modify-your-environmental-path/ ###
function Add-ToPath {
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrWhiteSpace()]
		[String[]] $Directories,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrWhiteSpace()]
		[EnvironmentVariableTarget] $Scope,
		
		[Switch] $Clobber,
		
		[Switch] $KeepProcessPath
		
	)
	
	# Check for files, non-existant directories and throw if any are found
	$BadItems = $Directories | Where-Object { -not (Test-Path $_ -PathType Container) }
	
	if ($BadItems.Count -ne 0) {
		throw [System.IO.DirectoryNotFoundException]::new(
			"The following items are not directories or do not exist and can't be added to the PATH: $($BadItems -join " ")"
		)
	}
	
	#$EnvPath = [Environment]::GetEnvironmentVariable("PATH", $Scope)
	$EnvPath = Get-EnvironmentVariable -Name "PATH" -Scope $Scope
	
	if ($IsWindows) {
		$EnvSplitter = ";"
		
	} else {
		$EnvSplitter = ":"
		
	}
	
	
	$PathAdditions = ""
	(Get-Item $Directories).FullName | ForEach-Object {
		if ($_ -in ($EnvPath -split $EnvSplitter)) {
			Write-Warning "Ignoring duplicate PATH entry `"$_`""
			continue
			
		}
		
		$PathAdditions += "$_$EnvSplitter"
		
	}
	
	# Make sure there is a trailing semicolon for our upcoming entry
	if ($EnvPath[-1] -ne $EnvSplitter) {
		$EnvPath += $EnvSplitter
		
	}
	
	if ($Clobber) {
		# if you say so!
		Set-EnvironmentVariable -Name "PATH" -Value "$PathAdditions$EnvPath" -Scope $Scope
		
	} else {
		# Add to END of path, don't clobber existing system utils!
		Set-EnvironmentVariable -Name "PATH" -Value "$EnvPath$PathAdditions" -Scope $Scope
		
	}
	
	# tell the OS we changed the path so respectful programs will update!
	# edit:apparanely this is done by the SetEnvironmentVariable call itself!
	#Send-WindowsEnvSettingChange
	
	if (-not $KeepProcessPath) {
		# manually update powershell's path
		Update-Path
		
	}
}

### ###

function Remove-FromPath {
		param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrWhiteSpace()]
		[String] $Directory,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrWhiteSpace()]
		[EnvironmentVariableTarget] $Scope
		
	)
	
	if ((-not $IsWindows) -and -not ($Scope -eq [EnvironmentVariableTarget]::Process)) {
		throw [System.PlatformNotSupportedException]::new("Removing from PATH on non-Windows platforms is only available when scope is $([EnvironmentVariableTarget]::Process) (was $Scope)")
		
	}
	
	if ($IsWindows) {
		$EnvSplitter = ";"
		
	} else {
		$EnvSplitter = ":"
		
	}
	
	$NewPath = (Get-EnvironmentVariable -Name "PATH" -Scope $Scope) -split $EnvSplitter -ne $Directory -join $EnvSplitter
	
	Set-EnvironmentVariable -Name "PATH" -Value $NewPath -Scope $Scope
	
}