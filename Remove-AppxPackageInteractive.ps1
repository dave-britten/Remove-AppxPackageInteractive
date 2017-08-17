<#
Copyright (c) 2017, Dave Britten
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of the FreeBSD Project.
#>

#GUI code adapted from this nice tutorial:
#https://foxdeploy.com/2015/04/10/part-i-creating-powershell-guis-in-minutes-using-visual-studio-a-new-hope/

$inputXML = @"
<Window x:Class="AppxPackageRemover.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:AppxPackageRemover"
        mc:Ignorable="d"
        Title="AppxPackageRemover" Height="350" Width="525" x:Name="MainWindow">
	<Grid>
		<ListBox x:Name="lstPackages" Margin="10,10,10,34.96" DisplayMemberPath="Label" SelectedValuePath="Name" SelectionMode="Extended"/>
		<Button x:Name="btnRemove" Content="Remove" HorizontalAlignment="Right" Margin="0,0,10,10" Width="75" Height="19.96" VerticalAlignment="Bottom"/>
	</Grid>
</Window>
"@

$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)

try{
    $Form=[Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}

$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "$($_.Name)" -Value $Form.FindName($_.Name)}

#Sample entry of how to add data to a field

#$vmpicklistView.items.Add([pscustomobject]@{'VMName'=($_).Name;Status=$_.Status;Other="Yes"})

$packages = Get-AppxPackage | Sort-Object -Property Name,Architecture
$packages | Foreach-Object {
    $lstPackages.Items.Add([pscustomobject]@{'Label'=$_.Name + " (" + $_.Architecture + ")";'Name'=$_.PackageFullName;'IsProvisioned'=$false})
} | out-null

try {
    $packagesProvisioned = Get-AppxProvisionedPackage -Online | Sort-Object -Property DisplayName
    $packagesProvisioned | Foreach-Object {
        $lstPackages.Items.Add([pscustomobject]@{'Label'=$_.DisplayName + " (Provisioned)";'Name'=$_.PackageName;'IsProvisioned'=$true})
    } | out-null
} catch {
    Write-Host "Warning: Could not get list of provisioned packages. You must be running with Administrator privileges to manage provisioned packages."
}

$btnRemove.Add_Click({$Form.DialogResult=$true; $Form.Close()})

$DialogResult = $Form.ShowDialog()

if ($DialogResult -eq $true) {
    $remove = $lstPackages.SelectedItems
    $remove | Foreach-Object {
        Write-Host "Removing"$_.Label
        if ($_.IsProvisioned) {
            Remove-AppxProvisionedPackage -Online -PackageName $_.Name
        } else {
            Remove-AppxPackage -Package $_.Name
        }
    } | out-null
}
