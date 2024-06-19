# Define the URL and paths
$repoURL = "https://github.com/RobRich999/Chromium_Clang/releases"
$tempDir = [System.IO.Path]::GetTempPath()
$chromiumAppDir = [System.IO.Path]::Combine($env:USERPROFILE, "AppData", "Local", "Chromium", "Application")

# Function to get the latest version info from GitHub
function Get-LatestVersionInfo {
    $html = Invoke-WebRequest -Uri $repoURL
    $latestRelease = $html.Links | Where-Object { $_.href -like "*releases/tag/*win64-avx2*" } | Select-Object -First 1
    if ($latestRelease -eq $null) {
        Write-Error "No release found for 'win64-avx2'."
        exit
    }

    $latestVersion = $latestRelease.href -replace ".*\/releases\/tag\/v([^\/]+)-win64-avx2", '$1'
    $downloadURL = "$repoURL/download/v$latestVersion-win64-avx2/mini_installer.exe"
    
    return [PSCustomObject]@{
        Version = $latestVersion
        DownloadURL = $downloadURL
    }
}

# Function to install the latest version
function Install-LatestVersion {
    param (
        [string]$url,
        [string]$tempPath
    )
    $installerPath = Join-Path -Path $tempPath -ChildPath "mini_installer.exe"
    Invoke-WebRequest -Uri $url -OutFile $installerPath
    Start-Process -FilePath $installerPath -Wait
    Remove-Item -Path $installerPath
}

# Function to get the installed version
function Get-InstalledVersion {
    $installedVersion = $null
    if (Test-Path -Path $chromiumAppDir) {
        $subDirs = Get-ChildItem -Path $chromiumAppDir -Directory
        if ($subDirs.Count -gt 0) {
            $installedVersion = ($subDirs | Sort-Object Name | Select-Object -First 1).Name
        }
    }
    return $installedVersion
}

# Check if version file exists and read version
$installedVersion = Get-InstalledVersion

# Get the latest version from GitHub
$latestVersionInfo = Get-LatestVersionInfo

# Compare versions and install if necessary
if ($installedVersion -eq $null -or 
    $latestVersionInfo.Version -notlike "$installedVersion*") {
    Write-Output "Installing new version: $($latestVersionInfo.Version)"
    Install-LatestVersion -url $latestVersionInfo.DownloadURL -tempPath $tempDir
    Write-Output "Installation completed."
} else {
    Write-Output "Latest version is already installed: $installedVersion"
}
