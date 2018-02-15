# https://github.com/krlmlr/r-appveyor/tree/master/scripts

$CRAN = "https://cloud.r-project.org"

# Found at http://zduck.com/2012/powershell-batch-files-exit-codes/
Function Exec
{
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=1)]
        [scriptblock]$Command,
        [Parameter(Position=1, Mandatory=0)]
        [string]$ErrorMessage = "Execution of command failed.`n$Command"
    )
    $ErrorActionPreference = "Continue"
    & $Command 2>&1 | %{ "$_" }
    if ($LastExitCode -ne 0) {
        throw "Exec: $ErrorMessage`nExit code: $LastExitCode"
    }
}

Function Progress
{
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$Message = ""
    )

    $ProgressMessage = '== ' + (Get-Date) + ': ' + $Message

    Write-Host $ProgressMessage -ForegroundColor Magenta
}

Function InstallRtools {
  if ( -not(Test-Path Env:\RTOOLS_VERSION) ) {
    Progress "Determining Rtools version"
    $rtoolsver = $(Invoke-WebRequest ($CRAN + "/bin/windows/Rtools/VERSION.txt")).Content.Split(' ')[2].Split('.')[0..1] -Join ''
  }
  Else {
    $rtoolsver = $env:RTOOLS_VERSION
  }

  $rtoolsurl = $CRAN + "/bin/windows/Rtools/Rtools$rtoolsver.exe"

  Progress ("Downloading Rtools from: " + $rtoolsurl)
  & "C:\Program Files\Git\mingw64\bin\curl.exe" -s -o ../Rtools-current.exe -L $rtoolsurl

  Progress "Running Rtools installer"
  Start-Process -FilePath ..\Rtools-current.exe -ArgumentList /VERYSILENT -NoNewWindow -Wait
  Start-Process -FilePath ..\Rtools-current.exe -ArgumentList "/VERYSILENT /COMPONENTS=""extras extras64""" -NoNewWindow -Wait

  $RtoolsDrive = "C:"
  echo "Rtools is now available on drive $RtoolsDrive"

  Progress "Setting PATH"

  $env:PATH = $RtoolsDrive + '\Rtools\bin;' + $RtoolsDrive + '\Rtools\mingw_64\bin;' + $RtoolsDrive + '\msys64\usr\bin;' + $env:PATH
  $env:PATH = $env:PATH + $RtoolsDrive + '\qpdf\bin;'
  $env:BINPREF=$RtoolsDrive + '/Rtools/mingw_64/bin/'
}

Function Bootstrap {
  [CmdletBinding()]
  Param()

  Progress "Bootstrap: Start"

  Progress "Setting time zone"
  tzutil /g
  tzutil /s "GMT Standard Time"
  tzutil /g

InstallRtools
}
