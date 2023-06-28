[System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null

function Import-Xaml {
    [xml]$xaml = Get-Content -Path $PSScriptRoot\wpfwindow.xaml
    $manager = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xaml.NameTable
    $manager.AddNamespace("x","http://schemas.microsoft.com/winfx/2006/xaml");
    $xamlReader = New-Object System.Xml.XmlNodeReader $xaml
    [Windows.Markup.XamlReader]::Load($xamlReader)

}
$Window = Import-Xaml
#####

#satrt empty string
$Global:control = ''
$Global:id = '0'

###
$txtComputerName = $Window.FindName('txtComputerName')
$btnCheck = $Window.FindName('btnCheck')
$cmbBox = $Window.FindName('cmbBox')
$rbtnControl = $Window.FindName('rbtnControl')
$btnRemote = $Window.FindName('btnRemote')
$rbtnViewOnly = $Window.FindName('rbtnViewOnly')

#####
#Buttons

$btnCheck.add_Click({
    if ($txtComputerName.text -eq '') {
        [System.Windows.MessageBox]::Show('Computer Name Cannot be empty!','Error')
    }
    else {
     if(Test-Connection -ComputerName $txtComputerName.text -Count 1) {   
        $cmbBox.Items.Clear()
        $Global:userslist= @(Get-ActiveSessions -Name $txtComputerName.text | Where-Object State -EQ active)
        foreach ($user in $Global:userslist) {
        $cmbBox.Items.Add($user.username)
                 }}  
                 else {
                     $CompOffline = $txtComputerName.text
                    [System.Windows.MessageBox]::Show("$CompOffline is offline",'Error')
                 }          
        }
})


$rbtnControl.add_Click({
    $Global:control = '/control'
})

$rbtnViewOnly.add_Click({
    $Global:control = ''
})

$btnRemote.add_Click({
    if ($txtComputerName.text -eq '') {
        [System.Windows.MessageBox]::Show('Computer Name Cannot be empty!','Error')
    }
    else {
          $rmote = $txtComputerName.text
          $Global:id = ($Global:userslist[$cmbBox.SelectedIndex]).ID
        Start-Process "mstsc.exe" -ArgumentList "/shadow:$Global:id /v:$rmote $Global:control"
    }
})


###

Function Get-ActiveSessions{
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Name
        ,
        [switch]$Quiet
    )
    Begin{
        $return = @()
    }
    Process{
        If(!(Test-Connection $Name -Quiet -Count 1)){
            Write-Error -Message "Unable to contact $Name. Please verify its network connectivity and try again." -Category ObjectNotFound -TargetObject $Name
            Return
        }
        If([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")){ #check if user is admin, otherwise no registry work can be done
            #the following registry key is necessary to avoid the error 5 access is denied error
            $LMtype = [Microsoft.Win32.RegistryHive]::LocalMachine
            $LMkey = "SYSTEM\CurrentControlSet\Control\Terminal Server"
            $LMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($LMtype,$Name)
            $regKey = $LMRegKey.OpenSubKey($LMkey,$true)
            If($regKey.GetValue("AllowRemoteRPC") -ne 1){
                $regKey.SetValue("AllowRemoteRPC",1)
                Start-Sleep -Seconds 1
            }
            $regKey.Dispose()
            $LMRegKey.Dispose()
        }
        $result = qwinsta /server:$Name
        If($result){
            ForEach($line in $result[1..$result.count]){ #avoiding the line 0, don't want the headers
                $tmp = $line.split(" ") | Where-Object{$_.length -gt 0}
                If(($line[19] -ne " ")){ #username starts at char 19
                    If($line[48] -eq "A"){ #means the session is active ("A" for active)
                        $return += New-Object PSObject -Property @{
                            "ComputerName" = $Name
                            "SessionName" = $tmp[0]
                            "UserName" = $tmp[1]
                            "ID" = $tmp[2]
                            "State" = $tmp[3]
                            "Type" = $tmp[4]
                        }
                    }Else{
                        $return += New-Object PSObject -Property @{
                            "ComputerName" = $Name
                            "SessionName" = $null
                            "UserName" = $tmp[0]
                            "ID" = $tmp[1]
                            "State" = $tmp[2]
                            "Type" = $null
                        }
                    }
                }
            }
        }Else{
            Write-Error "Unknown error, cannot retrieve logged on users"
        }
    }
    End{
        If($return){
            If($Quiet){
                Return $true
            }
            Else{
                Return $return
            }
        }Else{
            If(!($Quiet)){
                Write-Host "No active sessions."
            }
            Return $false
        }
    }
}

#####

[void]$Window.ShowDialog()