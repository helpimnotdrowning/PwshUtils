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

function New-HostnameColor {
	#write-host $env:net_helpimnotdrowning_HostnameColor
	
	# Turns out that spawning another PowerShell session inside of the one you are trying to launch and waiting for it to finish
	#	can actually be quite annoying. This guard prevents an expensive generation when the variable is already present.
	if (!$env:net_helpimnotdrowning_HostnameColor || $env:net_helpimnotdrowning_AlwaysGenerateNewHostnameColor) {
		# Get hash of hostname with silly roundabout method since Powershell only lets us compute hashes for files/streams
		$HostMD5Hash = Get-FileHash -Algorithm MD5 -InputStream ( [IO.MemoryStream]::new( [ byte[] ][ char[] ] (hostname) ) )

		$ColorSeed = [Int32]("0x" + $HostMD5Hash.Hash.ToLower()[0..7] -replace " ", "" ) # UInt64 sinc MD5 is 128 bits

		# Create a new PowerShell instance to do our "math" inside
		#	This is needed because "Get-Random -SetSeed" changes the seed for the lifetime of the session -- using a new session
		#	prevents this from affecting the main instance. The R, G, & B channels are generated with the seed derived from the
		#	hostname and saved as an RGB color.
		$env:net_helpimnotdrowning_HostnameColor = (pwsh -NoProfile -Command {
			"#" +
			(Get-Random -Minimum 0x0 -Maximum 0xFF -SetSeed $Args[0]).toString("X").PadLeft(2, '0') +
			(Get-Random -Minimum 0x0 -Maximum 0xFF).toString("X").PadLeft(2, '0') +
			(Get-Random -Minimum 0x0 -Maximum 0xFF).toString("X").PadLeft(2, '0')
		} -Args $ColorSeed )

		# * But why the hostname? It's the only identifier I knew could be consistent from machine to machine;
		#	an IP address can change at the will of the DHCP server, a MAC address / disk|motherboard|CPU|GPU|etc serial no. can
		#	change with a hardware upgrade, but a human (or machine) defined name stays as long as the OS does (which is really all
		#	that matters).
	}
}
