# Remove-AppxPackageInteractive

## What is it?
Remove-AppxPackageInteractive is a simple Powershell GUI wrapper for Remove-AppxPackage and Remove-AppxPackageProvisioned, which simplifies uninstalling unwanted junk that comes with Windows 10.

## Usage
From Powershell, cd to the directory containing the script, and do:

    .\Remove-AppxPackageInteractive.ps1

This will open a window that allows you to select one or more packages (use the Ctrl key). After making a selection, click the "Remove" button to uninstall all selected packages. To cancel, simply close the dialog with the standard X button.
