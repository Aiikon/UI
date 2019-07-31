﻿#
# Module manifest for module 'UI'
#
# Generated by: Justin Coon
#
# Generated on: 2/20/2019
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = '0193373c-f353-4086-a2f3-ba17322c6761'

# Author of this module
Author = 'Justin Coon'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = @'
(c) 2019 Justin Coon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'@

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('UI.psm1')

# Functions to export from this module
FunctionsToExport = @(
    'Show-UIWindow'
    'Set-UIKnownProperty'
    'New-UIObject'
    'New-UIObjectCollection'
    'New-UIPowerShell'
    'Invoke-UIPowerShell'
    'Add-UIBinding'
    'Add-UIEvent'
    'Find-UIParent'
    'Get-UIScreenshot'
    'Show-UIMessageBox'
    'New-UIStyle'
    'New-UISetter'
    'New-UITrigger'
    'New-UIDataTrigger'
    'New-UISolidColorBrush'
    'New-UILinearGradientBrush'
    'New-UIWindow'
    'New-UIBorder'
    'New-UIContentControl'
    'New-UIDockPanel'
    'New-UIExpander'
    'New-UIGrid'
    'New-UIGridSplitter'
    'New-UIGroupBox'
    'New-UIItemsControl'
    'New-UIScrollViewer'
    'New-UIStackPanel'
    'New-UITabControl'
    'New-UITabItem'
    'New-UITreeView'
    'New-UITreeViewItem'
    'New-UIUniformGrid'
    'New-UIViewBox'
    'New-UIWrapPanel'
    'New-UIContextMenu'
    'New-UIMenu'
    'New-UIMenuItem'
    'New-UIButton'
    'New-UICheckBox'
    'New-UIComboBox'
    'New-UIDataGrid'
    'New-UIDatePicker'
    'New-UIEllipse'
    'New-UIGridViewColumn'
    'New-UIImage'
    'New-UILabel'
    'New-UIListView'
    'New-UILine'
    'New-UIPasswordBox'
    'New-UIPolygon'
    'New-UIPolyline'
    'New-UIProgressBar'
    'New-UIRadioButton'
    'New-UIRectangle'
    'New-UIRichTextBox'
    'New-UISlider'
    'New-UITextBlock'
    'New-UITextBox'
    'New-UIRotateTransform'
    'New-UIScaleTransform'
)

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

