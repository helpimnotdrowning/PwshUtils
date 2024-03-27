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

function Get-ArchiveTypeFromName {
	param (
		[String] $Name

	)

	$SplitName = $Name -split "\."

	if ($SplitName[-1] -ieq "tar" || $SplitName[-2] -ieq "tar") {
		return "tar"

	} elseif ($SplitName[-1] -ieq "zip") {
		return "zip"

	} else {
		Write-Warning "Could not determine archive type from extension for `"$Name`"! Defaulting to `"tar`"."
		return "tar"

	}
}

function Compress-XArchive {
	param (
		[String] $DestinationPath,
		[String[]] $Paths,
		[Switch] $Force,
		[Switch] $Confirm,
		[Switch] $PassThru,

		[ValidateSet("Automatic", "tar", "zip")]
		[String] $Backend = "Automatic"

	)

	if ($Confirm) {
		Remove-Item -Path $DestinationPath -Confirm -ErrorAction Ignore

	} else {
		Remove-Item -Path $DestinationPath -ErrorAction Ignore

	}


	if (($Backend -ieq "tar") -or (Get-ArchiveTypeFromName -Name $DestinationPath) -ieq "tar") {
		# let tar auto determine compression method from filename
		$Paths.Name | tar --posix --auto-compress --create --recursion --file $DestinationPath --files-from -

	} elseif (($Backend -ieq "zip") -or (Get-ArchiveTypeFromName -Name $DestinationPath) -ieq "zip") {
		echo "$($Paths.Name) | zip --recurse-paths -@ $DestinationPath"
		$Paths.Name | zip --recurse-paths -@ $DestinationPath


	}
}
