
$InstallOpenSSHPath = 'C:\Program Files\'
$OpenSSHPath = 'C:\Program Files\OpenSSH-Win64'
$OpenSSHWin64ZipFile = "$env:USERPROFILE\downloads\OpenSSH-Win64.zip"


#region Remove Symbolic Link
if (Test-Path c:\pwsh)
{remove-item c:\pwsh}

if (Test-Path c:\pwsh)
{
    Write-Host "Removeal of Symbolic Link failed" -ForegroundColor Red
}
else
{
    Write-Host "Removeal of Symbolic Link was successful" -ForegroundColor Green
}
#endregion Remove Symbolic Link

#region Remove Default Shell for OpenSSH
$RemovePwshDefaultShell = @{
    Path = "HKLM:\SOFTWARE\OpenSSH" 
    Name = "DefaultShell" 
}
Remove-ItemProperty @RemovePwshDefaultShell

$CheckPwshDefaultShell = @{
    Path = "HKLM:\SOFTWARE\OpenSSH" 
    Name = "DefaultShell" 
}

try
{
    Get-ItemProperty @CheckPwshDefaultShell -ErrorAction Stop
}
catch
{
    Write-Host "Pwsh Default Shell Registry entry removed" -ForegroundColor Green
}

#endregion Remove Default Shell for OpenSSH

#region Remove Services
# Set SSH services to Manual
Set-Service sshd -StartupType Manual
Set-Service ssh-agent -StartupType Manual

# Stop SSH services
Stop-Service sshd
Stop-Service ssh-agent

$OpenSSHPath = 'C:\Program Files\OpenSSH'
pwsh.exe $OpenSSHPath\uninstall-sshd.ps1

if (netstat -bano | Select-String -Pattern ':22')
{
    Write-Host "Still listening on Port 22" -ForegroundColor Red
}
else
{
    Write-Host "No longer listening on Port 22" -ForegroundColor Green
}
#endregion Remove Services


#region Remove env:Path entry

# Remove $OpenSSHPath from Machine env:Path
$path = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')

# Remove $OpenSSHPath from Machine env:Path
$path = ($path.Split(';') | Where-Object { $_ -ne $AddToPath }) -join ';'

# Apply the settings
[System.Environment]::SetEnvironmentVariable('PATH', $path, 'Machine')

# Test that removal of $OpenSSHPath from Machine env:Path was successful
$TestMachinePathAdded = ([Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) -split ';')
if ($TestMachinePathAdded -like $OpenSSHPath  )
{
    Write-Host "Error - Not Removed From Machine Path" -ForegroundColor Red
}
else
{
    Write-Host "Removed From Machine Path" -ForegroundColor Green
}


# Set Path to User env:Path
$path = [System.Environment]::GetEnvironmentVariable("Path", "User")

# Remove $OpenSSHPath from User env:Path
$path = ($path.Split(';') | Where-Object { $_ -ne $AddToPath }) -join ';'

# Apply the settings
[System.Environment]::SetEnvironmentVariable('PATH', $path, 'User')

# Test that removal of $OpenSSHPath from User env:Path was successful
$TestUserPathAdded = ([Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User) -split ';')
if ($TestUserPathAdded -like $OpenSSHPath  )
{
    Write-Host "Error - Not Removed From User Path" -ForegroundColor Red
}
else
{
    Write-Host "Removed From User Path" -ForegroundColor Green
}
#endregion Remove env:Path entry


#region Remove Folders
remove-item 'C:\ProgramData\ssh' -Confirm:$false -Force 
remove-item $OpenSSHPath  -Confirm:$false -Force 
#endregion Remove Folders

#region Remove FireWall Rules
netsh advfirewall firewall delete rule name="sshd"
#endregion Remove FireWall Rules
netsh advfirewall firewall show rule name="sshd"