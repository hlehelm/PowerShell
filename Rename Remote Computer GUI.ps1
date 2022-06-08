# Made By Mohammed Hlehel

# Get User Credential
$cred = Get-Credential -Credential $env:USERDOMAIN\$env:USERNAME
# Check Credential
 $username = $cred.username
 $password = $cred.GetNetworkCredential().password
 $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

if ($domain.name -eq $null)
{
 Write-Error "Authentication failed - please verify your username and password."
break 
}
    else
{
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$UpdateComputer                  = New-Object system.Windows.Forms.Form
$UpdateComputer.ClientSize       = '400,400'
$UpdateComputer.text             = "Remote Computer Rename"
$UpdateComputer.TopMost          = $false

$ComputerName                    = New-Object system.Windows.Forms.Label
$ComputerName.text               = "Computer Name"
$ComputerName.AutoSize           = $true
$ComputerName.width              = 25
$ComputerName.height             = 10
$ComputerName.location           = New-Object System.Drawing.Point(133,70)
$ComputerName.Font               = 'Microsoft Sans Serif,10'

$LabelComputerName               = New-Object system.Windows.Forms.TextBox
$LabelComputerName.multiline     = $false
$LabelComputerName.width         = 179
$LabelComputerName.height        = 20
$LabelComputerName.visible       = $true
$LabelComputerName.location      = New-Object System.Drawing.Point(96,97)
$LabelComputerName.Font          = 'Microsoft Sans Serif,15'

$NewComputerName                 = New-Object system.Windows.Forms.Label
$NewComputerName.text            = "New Computer Name"
$NewComputerName.AutoSize        = $true
$NewComputerName.width           = 25
$NewComputerName.height          = 10
$NewComputerName.location        = New-Object System.Drawing.Point(133,145)
$NewComputerName.Font            = 'Microsoft Sans Serif,10'

$LabelNewComputerName            = New-Object system.Windows.Forms.TextBox
$LabelNewComputerName.multiline  = $false
$LabelNewComputerName.width      = 179
$LabelNewComputerName.height     = 20
$LabelNewComputerName.visible    = $true
$LabelNewComputerName.location   = New-Object System.Drawing.Point(96,174)
$LabelNewComputerName.Font       = 'Microsoft Sans Serif,15'

$Exec                            = New-Object system.Windows.Forms.Button
$Exec.text                       = "Execute"
$Exec.width                      = 133
$Exec.height                     = 58
$Exec.location                   = New-Object System.Drawing.Point(116,245)
$Exec.Font                       = 'Playbill,29'

$Hlehel                          = New-Object system.Windows.Forms.Label
$Hlehel.text                     = "By Mohammed Hlehel"
$Hlehel.AutoSize                 = $true
$Hlehel.width                    = 25
$Hlehel.height                   = 10
$Hlehel.location                 = New-Object System.Drawing.Point(116,325)
$Hlehel.Font                     = 'Microsoft Sans Serif,10'

$UpdateComputer.controls.AddRange(@($ComputerName,$LabelComputerName,$NewComputerName,$LabelNewComputerName,$Exec,$Hlehel))

$exec.add_Click({

$cname=$LabelComputerName.Text
$Nname=$LabelNewComputerName.Text

if (Test-Connection -ComputerName $cname -Count 1) 
 {
Rename-Computer -ComputerName $cname -NewName $Nname -Force -DomainCredential $cred -Restart

$LabelComputerName.ResetText()
$LabelNewComputerName.ResetText()
}
else {Write-Host "Computer : $cname Is Offline or not exist, try again" -ForegroundColor Red}
$LabelComputerName.ResetText()
$LabelNewComputerName.ResetText()

})

[Void]$UpdateComputer.ShowDialog()

}