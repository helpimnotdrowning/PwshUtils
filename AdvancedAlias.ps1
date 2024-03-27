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

# !!! WARNING WARNING !!!
# THIS SHIT DONT WORK RIGHT
# TOO COMPLICATED AND IT BREAKS RANDOMLY
# AVERT YOUR GAZE
# JUST MAKE A FUNCTION OR SOMETHING LIKE A NORMAL PERSON

# yeah im calling these "advanced aliases" they are MY creation
# something something GPLv3 ... << this statement is irrelevent since it is
# 	now the assigned license !
function New-AdvancedAlias {
	param(
		[Parameter(Mandatory)]
		[String] $Name,
		
		[String] $Description = "",
		
		[Parameter(Mandatory)]
		[String] $Command,
		
		[String[]] $CommandArgs = "",
		
		[String[]] $TrailArgs = ""
 	)
	
	$RandomID = (Get-Random -Min 0x0 -Max 0xfffffff).ToString("X").PadLeft(7, "0")
	
	<#
	alright, so the only way I found to generate a function *and* keep the
		param labels *and* keep pipeline inputs (not crushing everything into a
		string like a traditonal shell, which would break objects for commands
		who're expecting living objects) was to do this roundabout way to make
		a function.
	[1] Functions can't be created normally with dynamic names (which I do to
		avoid collisions), so a scriptblock is created under the
		`Function:` PSDrive.
	[2] Scriptblocks (and functions) don't remember variable names from their
		creation scope when called (since they get separated on creation I
		assume?). A workaround that lets us keep the context using
		GetNewClosure(): it takes a snapshot of the variables at creation with
		this function's calling context
	[3] Something quite silly happens with $args and $input ! $args is left out
		of the snapshot, so nothing fancy needs to be done to have the extra
		function params when calling. HOWEVER, $input seems to be treated
		differently, it is captured along with everything else! I thought this
		meant another dead end, but it seems adding the line
		`(Get-Item Variable:\input).Value` updates(?) it with the value it's
		supposed to have (the pipeline input) and everything works fine for
		some reason.
	#>
	
	New-Item -Path Function:\ -Name "global:__net_helpimnotdrowning_advancedalias_generated_func_$RandomID" -Value {
		if ($MyInvocation.ExpectingInput) {
			# man FUCK this language; see external comment above declaration for my rant
			(Get-Item Variable:\input).Value
			
			# strange errors are thrown about blank arguments if something is left in while blank/$null, so the command is made
			# 	based on what parts actually exist or not instead
			if ($CommandArgs) {
				if ($TrailArgs) {
					$input | & $Command @CommandArgs @args @TrailArgs # SORRY NO TRACEBACK GET TROLLED

				} else {
					$input | & $Command @CommandArgs @args # SORRY NO TRACEBACK GET TROLLED
				}
				
			} else {
				if ($TrailArgs) {
					$input | & $Command @args @TrailArgs # SORRY NO TRACEBACK GET TROLLED
					
				} else {
					$input | & $Command @args # SORRY NO TRACEBACK GET TROLLED
					
				}
			}
			
		} else {
			if ($CommandArgs) {
				if ($TrailArgs) {
					& $Command @CommandArgs @args @TrailArgs # SORRY NO TRACEBACK GET TROLLED
					
				} else {
					& $Command @CommandArgs @args # SORRY NO TRACEBACK GET TROLLED
					
				}
				
			} else {
				if ($TrailArgs) {
					& $Command @args @TrailArgs # SORRY NO TRACEBACK GET TROLLED
					
				} else {
					& $Command @args # SORRY NO TRACEBACK GET TROLLED
					
				}
			}
		}
		
	}.GetNewClosure() | Out-Null
	
	New-Alias -Name $Name -Value "global:__net_helpimnotdrowning_advancedalias_generated_func_$RandomID" -Description $Description -Scope 1 -Force
	
}