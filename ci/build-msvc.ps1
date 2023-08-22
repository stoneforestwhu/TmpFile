param (
    [ValidateSet('win64','win32')][string]$target = 'win64',
    [string]$config,
    [string]$buildRoot = 'build',
    [string]$qtRoot = 'Qt'
)

# https://stackoverflow.com/a/48999101
Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"
function Exec {
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$cmd
    )
    Write-Host ("> " + $cmd.ToString().Trim())
    & $cmd
    if ($LastExitCode -ne 0) {
        throw
    }
}

$qtVersion = '5.15.2'
$qtVersionDotless = $qtVersion -replace '\.'

if ($target -eq 'win64') {
    $toolchain = 'msvc2019_64'
    $arch = 'X86_64'
    $toolset = 'x64'
} else {
    $toolchain = 'msvc2019'
    $arch = 'X86'
    $toolset = 'Win32'
}

$baseUrl = "https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_$qtVersionDotless"

$packageUrl = "$baseUrl/qt.qt5.$qtVersionDotless.${target}_$toolchain"

$tag = "0-202011130602"

$suffix = "Windows-Windows_10-MSVC2019-Windows-Windows_10"

$modules = @('qtbase', 'qttools')

$qtToolchainPath = "$qtRoot\$qtVersion\$toolchain"
if (!(Test-Path $qtToolchainPath -PathType Container)) {

    foreach ($module in $modules) {
        $archive = "$qtVersion-${tag}${module}-${suffix}-$arch.7z"
        $archiveUrl = "$packageUrl/$archive"

        if (!(Test-Path $archive -PathType Leaf)) {
            Write-Host "Downloading $archiveUrl ..."
            # https://github.com/PowerShell/PowerShell/issues/2896
            do {
                try {
                    Invoke-WebRequest -Uri $archiveUrl -OutFile $archive -UserAgent NativeHost
                    $retry = $false
                }
                catch {
                    if (($_.Exception.GetType() -match "HttpResponseException") -and ($_.Exception -match "302")) {
                        $archiveUrl = $_.Exception.Response.Headers.Location.AbsoluteUri
                        Write-Host "Redirected to $archiveUrl ..."
                        $retry = $true
                    }
                    else {
                        throw $_
                                                                                }
                }
            } while ($retry)
        }

        Write-Host "Extracting $archive to $qtToolchainPath ..."
        Exec { 7z x -y "-o$qtRoot" $archive | Out-Null }
    }
}

$qtBinPath = Resolve-Path "$qtToolchainPath\bin"
Write-Host "Adding $qtBinPath to environment path."
$Env:Path = "$qtBinPath;$Env:Path"

$generator = 'Visual Studio 16 2019'

if (!$config) {
    $config = 'Debug'
    # Default to release on master and tag Appveyor builds
    if ((Test-Path Env:APPVEYOR) -And
        ((Test-Path Env:APPVEYOR_REPO_TAG_NAME) -Or
         (($Env:APPVEYOR_REPO_BRANCH -eq 'master') -And !(Test-Path Env:APPVEYOR_PULL_REQUEST_NUMBER)))) {
        $config = 'RelWithDebInfo'
    }
    # Default to release on tags GitHub builds
    if ($Env:GITHUB_EVENT_NAME -eq "push" -And $Env:GITHUB_REF.StartsWith('refs/tags/')) {
        $config = 'RelWithDebInfo'
    }
}

Write-Host "Configuring onto $buildRoot ..."
Exec { cmake "-S." "-B$buildRoot" -G $generator -A $toolset "-DCMAKE_PREFIX_PATH=$qtToolchainPath" "-DENABLE_GUI=ON" }

Write-Host "Building ..."
Exec { cmake --build $buildRoot --config $config --target ALL_BUILD --target check --target package "--" /verbosity:minimal /maxcpucount }
