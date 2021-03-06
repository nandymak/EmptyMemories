<#
.SYNOPSIS
Primarily used to convert .m4a and .mp4 audio files to .mp3

.PARAMETER Bitrate
Default bitrate is 128..

.PARAMETER FullQuality
Preserve full quality. Default is to use lame compression to save disk space.

.PARAMETER Info
Show ffmpeg info. Default is to run quietly.

.PARAMETER Input
Path to an .m4a file or a directory containing .m4a files. 
This is not a recursive operation.

.PARAMETER OutputPath
Path of output directory. Default is same directory as .m4a file.

.PARAMETER Yes
Overwrite existing .mp3 files without prompting for confirmation.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[Parameter(Mandatory = $true, Position = 0)] [string] $InputPath,
	[string] $OutputPath,
	[int] $Bitrate = 128,
	[switch] $FullQuality,
	[switch] $Info,
	[switch] $Yes
)

Begin
{
	function EnsureConverter
	{
		if ((Get-Command ffmpeg -ErrorAction:SilentlyContinue) -eq $null)
		{
			Write-Host '... installing ffmpeg'
			choco install -y ffmpeg
		}
	}


	function Convert
	{
		param($name)

		$mp3 = [IO.Path]::ChangeExtension($name, 'mp3')

		if ($OutputPath)
		{
			$mp3 = Join-Path $OutputPath (Split-Path $mp3 -Leaf)
		}

		$loglevel = 'quiet'
		if ($Info) { $loglevel = 'info' }

		$over = ''
		if ($Yes) { $over = '-y' }

		if ($FullQuality)
		{
			Write-Host "... converting $name with full quality" -ForegroundColor Cyan
			ffmpeg -i $name -q:a 0 -map a -vn -loglevel $loglevel $over $mp3
		}
		else
		{
			Write-Host "... converting $name" -ForegroundColor Cyan
			ffmpeg -i $name -b:a $Bitrate`K -vn -loglevel $loglevel $over $mp3
			# or...
			#ffmpeg -i $name -acodec libmp3lame -aq 2 -loglevel $loglevel $over $mp3
		}
	}
}
Process
{
	if (!(Test-Path $InputPath))
	{
		Write-Host "... $InputPath is not found" -ForegroundColor Red
		return
	}

	EnsureConverter

	if ($OutputPath -and !(Test-Path $OutputPath))
	{
		Write-Host "... creating $OutputPath" -ForegroundColor Cyan
		New-Item $OutputPath -ItemType Directory -Force -Confirm:$false | Out-Null
	}

	if ((Get-Item $InputPath) -is [IO.DirectoryInfo])
	{
		Get-ChildItem $InputPath -Filter *.m4a | % { Convert $_.FullName }
	}
	else
	{
		Convert $InputPath
	}
}
