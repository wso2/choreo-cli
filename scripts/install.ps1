function Get-Architecture {
    switch ([Environment]::Is64BitOperatingSystem) {
        $true { return "amd64" }
        $false { return "386" }
    }
}

function Get-Version {
    param($version)
    if ($version) {
        return $version
    }

    # If LAST_RELEASE is set to true, get the latest release version
    if ($env:LAST_RELEASE -eq "true") {
        Write-Host "Fetching latest release version..."
        $response = Invoke-WebRequest -Method Get -Uri "https://api.github.com/repos/wso2/choreo-cli/releases"
        $object = $response.Content | ConvertFrom-Json
        foreach ($release in $object) {
            if ($release.prerelease -eq $true) {
                return $release.tag_name
            }
        }
    }

    $url = "https://github.com/wso2/choreo-cli/releases/latest"
    $redirect_response = Invoke-WebRequest -Method Get -Uri $url -MaximumRedirection 0 -ErrorAction SilentlyContinue

    if ($redirect_response.StatusCode -eq 302) {
        $location = $redirect_response.Headers.Location
        $version = $location.Split("/")[-1]
        return $version
    }
}

function Main {
    param($version)
    $ARCH = Get-Architecture
    $VERSION = Get-Version $version
    $WDP_INSTALL_DIR = if ($env:WDP_INSTALL) {
        "$env:WDP_INSTALL"
    } else {
        "$HOME\.wdp"
    }
    $WDP_EXE = "$WDP_INSTALL_DIR\wdp.exe"
    $INSTALLER_ZIP = "$WDP_INSTALL_DIR\wdp-cli-$VERSION-windows-$ARCH.zip"
    $BinDir = "$WDP_INSTALL_DIR\bin"
    
    if (!(Test-Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir | Out-Null
    }

    $prevProgressPreference = $ProgressPreference
    try {
        # Invoke-WebRequest on older powershell versions has severe transfer
        # performance issues due to progress bar rendering - the screen updates
        # end up throttling the download itself. Disable progress on these older
        # versions.
        if ($PSVersionTable.PSVersion.Major -lt 7) {
            Write-Output "Downloading Chroeo CLI version $VERSION..."
            $ProgressPreference = "SilentlyContinue"
        }

        $downloadUri = "https://github.com/wso2/choreo-cli/releases/download/$VERSION/wdp-cli-$VERSION-windows-$ARCH.zip"
        Invoke-WebRequest $downloadUri -OutFile $INSTALLER_ZIP
    } finally {
        $ProgressPreference = $prevProgressPreference
    }

    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
        Expand-Archive $INSTALLER_ZIP -Destination $BinDir -Force
    } else {
        write-host "Error extracting archive!"
    }

    Remove-Item $INSTALLER_ZIP

    $User = [EnvironmentVariableTarget]::User
    $Path = [Environment]::GetEnvironmentVariable("Path", $User)

    if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) {
        [Environment]::SetEnvironmentVariable('Path', "$Path;$BinDir", $User)
        $Env:Path += ";$BinDir"
    }

    if (!(Get-Item $WDP_EXE -ErrorAction SilentlyContinue).LinkTarget) {
      # if wdp.exe is not already a symlink, make it so.

      # delete any existing file
      Remove-Item $WDP_EXE -ErrorAction SilentlyContinue

      # creating symlinks on windows requires administrator privileges by default,
      # passing `-Verb runAs` means we'll pop up a UAC dialog here
      Start-Process -FilePath "$env:comspec" -ArgumentList "/c", "mklink", $WDP_EXE -Verb runAs -WorkingDirectory "$env:windir"
    }

    Write-Output "wdp cli was installed successfully to $WDP_EXE"
    Write-Output "Run 'wdp --help' to get started"
}

Main $args[0]
