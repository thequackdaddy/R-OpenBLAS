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

Function InstallQpdf
{
  # Have to use TLS 1.2
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
  $qpdf_gh = "https://api.github.com/repos/qpdf/qpdf/releases"
  $qpdf_local = "c:\qpdf"
  $qpdf = Invoke-WebRequest $qpdf_gh | ConvertFrom-Json
  $assets = $($qpdf | Sort-Object -Property id -Descending | Where-Object prerelease -eq 0 | Select-Object -First 1).assets
  $download_url = $($assets | Where-Object name -Like "*mingw64*" | Select-Object -First 1).browser_download_url

  Progress ("Downloading QPDF from: " + $download_url)
  Invoke-WebRequest -Uri $download_url -OutFile qpdf.zip
  Progress ("Unzipping QPDF")
  7z x qpdf.zip -o$qpdf_local
  Progress ("QPDF installed at " + $qpdf_local)
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
  # Start-Process -FilePath ..\Rtools-current.exe -ArgumentList /VERYSILENT -NoNewWindow -Wait
  Start-Process -FilePath ..\Rtools-current.exe -ArgumentList "/VERYSILENT /COMPONENTS=""rtools mingw_32 mingw_64 checkutils aspell extras""" -NoNewWindow -Wait

  $RtoolsDrive = "C:"
  echo "Rtools is now available on drive $RtoolsDrive"

  Progress "Setting PATH"

  $env:PATH = $RtoolsDrive + '\Rtools\bin;' + $RtoolsDrive + '\Rtools\mingw_64\bin;' + $env:PATH
}

Function Bootstrap {
  [CmdletBinding()]
  Param()

  Progress "Bootstrap: Start"

  Progress "Setting time zone"
  tzutil /g
  tzutil /s "GMT Standard Time"
  tzutil /g

  # InstallMiktex
  InstallQpdf
  InstallRtools

  New-Item "r-source\SVN-REVISION" -ItemType file
  "Revision: 50001" | Add-Content -Path "r-source\SVN-REVISION"
  (Get-Date) | Add-Content -Path "r-source\SVN-REVISION"
}
