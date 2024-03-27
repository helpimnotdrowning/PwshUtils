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

class AnsiEscapeCodes {
    static [String] $Reset = $PSStyle.Reset
    static [String] $Blink = $PSStyle.Blink
    static [String] $BlinkOff = $PSStyle.BlinkOff
    static [String] $Bold = $PSStyle.Bold
    static [String] $BoldOff = $PSStyle.BoldOdd
    static [String] $Dim = $PSStyle.Dim
    static [String] $DimOff = $PSStyle.DimOff
    static [String] $Hidden = $PSStyle.Hidden
    static [String] $HiddenOff = $PSStyle.HiddenOff
    static [String] $Reverse = $PSStyle.Reverse
    static [String] $ReverseOff = $PSStyle.ReverseOff
    static [String] $Italic = $PSStyle.Italic
    static [String] $ItalicOff = $PSStyle.ItalicOff
    static [String] $Underline = $PSStyle.Underline
    static [String] $UnderlineOff = $PSStyle.UnderlineOff
    static [String] $Strikethrough = $PSStyle.Strikethrough
    static [String] $StrikethroughOff = $PSStyle.StrikethroughOff
    
    static [String] $FBlack = $PSStyle.Foreground.Black
    static [String] $FBrightBlack = $PSStyle.Foreground.BrightBlack
    static [String] $FWhite = $PSStyle.Foreground.White
    static [String] $FBrightWhite = $PSStyle.Foreground.BrightWhite
    static [String] $FRed = $PSStyle.Foreground.Red
    static [String] $FBrightRed = $PSStyle.Foreground.BrightRed
    static [String] $FMagenta = $PSStyle.Foreground.Magenta
    static [String] $FBrightMagenta = $PSStyle.Foreground.BrightMagenta
    static [String] $FBlue = $PSStyle.Foreground.Blue
    static [String] $FBrightBlue = $PSStyle.Foreground.BrightBlue
    static [String] $FCyan = $PSStyle.Foreground.Cyan
    static [String] $FBrightCyan = $PSStyle.Foreground.BrightCyan
    static [String] $FGreen = $PSStyle.Foreground.Green
    static [String] $FBrightGreen = $PSStyle.Foreground.BrightGreen
    static [String] $FYellow = $PSStyle.Foreground.Yellow
    static [String] $FBrightYellow = $PSStyle.Foreground.BrightYellow

    static [String] $BBlack = $PSStyle.Background.Black
    static [String] $BBrightBlack = $PSStyle.Background.BrightBlack
    static [String] $BWhite = $PSStyle.Background.White
    static [String] $BBrightWhite = $PSStyle.Background.BrightWhite
    static [String] $BRed = $PSStyle.Background.Red
    static [String] $BBrightRed = $PSStyle.Background.BrightRed
    static [String] $BMagenta = $PSStyle.Background.Magenta
    static [String] $BBrightMagenta = $PSStyle.Background.BrightMagenta
    static [String] $BBlue = $PSStyle.Background.Blue
    static [String] $BBrightBlue = $PSStyle.Background.BrightBlue
    static [String] $BCyan = $PSStyle.Background.Cyan
    static [String] $BBrightCyan = $PSStyle.Background.BrightCyan
    static [String] $BGreen = $PSStyle.Background.Green
    static [String] $BBrightGreen = $PSStyle.Background.BrightGreen
    static [String] $BYellow = $PSStyle.Background.Yellow
    static [String] $BBrightYellow = $PSStyle.Background.BrightYellow
    
}

function ConvertTo-AnsiColorCode {
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="StringColor")]
        [ValidateLength(6, 8)]
        [ValidatePattern("(#|0x)?[0-9a-fA-F]{6}")] # MATCH (optional '#' || '0x') + (ANY 6 chars IN (0..9 || a..f || A..F))
        [String] $ColorString,
        
        
        [Parameter(Mandatory, ParameterSetName="TripletByteColor")]
        [ValidateNotNull()]
        [Byte] $Red,
        
        [Parameter(Mandatory, ParameterSetName="TripletByteColor")]
        [ValidateNotNull()]
        [Byte] $Blue,
        
        [Parameter(Mandatory, ParameterSetName="TripletByteColor")]
        [ValidateNotNull()]
        [Byte] $Green,
        
        
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="IntColor")]
        [ValidateNotNull()]
        [Int] $Color,
        
        
        [ValidateSet("Foreground", "Background")]
        [String] $Type = "Foreground"
    )
    
    if ($ColorString) {
        # strip '#' from color; its allowed for convenience but we don't actually want that
        if ($ColorString[0] -eq "#") {
            $Color = [Int]"0x$($ColorString[1..6] -join '')"
            
        # already in 0x form :D
        } elseif ($ColorString[1] -eq 'x') {
            $Color = [Int]$ColorString
            
        # just a pile of characters, add 0x prefix
        } else {
            $Color = [Int]("0x$ColorString")
        
        }
        
    } elseif ($Red -and $Green -and $Blue) {
        # add together channels to form full color
        $Color = ($Red -shl 16) + ($Green -shl 8) + ($Blue)
        
    }
    
    write-host $color
    
    switch ($Type) {
        "Foreground" { return $PSStyle.Foreground.FromRgb($Color) }
        "Background" { return $PSStyle.Background.FromRgb($Color) }
        
    }
}