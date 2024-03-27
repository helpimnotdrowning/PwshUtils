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

function ConvertTo-Base64 {
	[Alias("base64")]
	param (
		[Parameter(Mandatory, ValueFromPipeline, ParameterSetName="StringInput")]
        [AllowEmptyString]
		[String] $String,
		
        
		[Switch] $SplitTo76
	)
	
	process {
		$Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
		
		if ($SplitTo76) {
			$_SplitTo76 = [System.Base64FormattingOptions]::InsertLineBreaks
		
		} else {
			$_SplitTo76 = [System.Base64FormattingOptions]::None
		
		}
		
		return [System.Convert]::ToBase64String($Bytes, 0, $Bytes.Count, $_SplitTo76)
		
	}
}

function ConvertFrom-Base64 {
	[Alias("dbase64")]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[String] $B64String
	)
	
	process {
		return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64String))
		
	}
}
