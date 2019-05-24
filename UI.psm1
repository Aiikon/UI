[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')

$Script:ReservedParameters = @"
AsFactory
Content
Children
Child
Items
Margin
Padding
BorderThickness
CornerRadius
GridRow
GridRowSpan
GridCol
GridColSpan
Dock
LayoutTransform
ContextMenu
Style
Align
AlsoSet
ErrorAction
WarningAction
Verbose
Debug
ErrorVariable
WarningVariable
OutVariable
OutBuffer
PipelineVariable
"@ -split "[`r`n]+"

$Script:ReservedParameterDict = @{}
foreach ($reservedParameter in $Script:ReservedParameters)
{
    $Script:ReservedParameterDict[$reservedParameter] = $true
}

$Script:SimplePropertyDict = @{}
$Script:BindPropertyDict = @{}
$Script:EventPropertyDict = @{}
$Script:ProcessedParameterDict = @{}

Add-Type -ReferencedAssemblies PresentationCore, PresentationFramework, WindowsBase @'
using System;
using System.Windows;
using System.Windows.Data;
using System.Collections.Generic;
using System.Linq;

namespace Rhodium.UI
{
    public enum Align
    {
        TopLeft, TopRight, TopCenter, TopStretch,
            BottomLeft, BottomRight, BottomCenter, BottomStretch,
            CenterLeft, CenterRight, Center, CenterStretch,
            StretchLeft, StretchRight, StretchCenter, Stretch
    };

    public class ValueConverterGroup : List<IValueConverter>, IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return this.Aggregate(value, (current, converter) => converter.Convert(current, targetType, parameter, culture));
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class InvertBoolConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            var castValue = value as bool?;
            if (castValue == null || castValue.Value == false)
                return true;
            else
                return false;
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BoolToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            var castValue = value as bool?;
            if (castValue == null || castValue.Value == false)
                return System.Windows.Visibility.Collapsed;
            else
                return System.Windows.Visibility.Visible;
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
'@

# ======================================================================================================================
# Property Management
# ======================================================================================================================

Function Set-UIKnownProperty
{
    Param
    (
        [Parameter(Position=0)] [object] $Control,
        [Parameter(Position=1)] [hashtable] $Properties
    )
    End
    {
        $controlType = $Control.GetType()
        $asFactory = !!$Properties['AsFactory']

        foreach ($property in $Properties.Keys)
        {
            if ($Script:SimplePropertyDict.Contains($property))
            {
                $Control.$property = $Properties[$property]
            }
            if ($asFactory) { continue }
            if ($Script:BindPropertyDict.Contains($property))
            {
                $bindProperty = $Script:BindPropertyDict[$property]
                [void]$Control.SetBinding($controlType::"${bindProperty}Property", $Properties[$property])
            }
            elseif ($Script:EventPropertyDict.Contains($property))
            {
                $eventProperty = $Script:EventPropertyDict[$property]
                $Control."Add_$eventProperty"($Properties[$property])
            }
        }
        
        if ($Properties.Contains('Content')) { $children = $Properties['Content'] }
        elseif ($Properties.Contains('Children')) { $children = $Properties['Children'] }
        elseif ($Properties.Contains('Child')) { $children = $Properties['Child'] }
        elseif ($Properties.Contains('Items')) { $children = $Properties['Items'] }
        else { $children = $null }
        if ($children -is [scriptblock])
        {
            $variables = $null
            if ($asFactory)
            {
                $defaultParameterValues = New-Object System.Management.Automation.DefaultParameterDictionary @{"New-UI*:AsFactory"=$true}
                $variables = New-Object PSVariable PSDefaultParameterValues, $defaultParameterValues
            }
            $children = $children.InvokeWithContext($null, $variables, $null)
        }
        if ($children -and !$asFactory) { foreach ($child in $children) { $Control.AddChild($child) } }
        
        if ($Properties.Contains('Margin')) { $Control.Margin = New-Object System.Windows.Thickness $Properties['Margin'] }
        if ($Properties.Contains('Padding')) { $Control.Padding = New-Object System.Windows.Thickness $Properties['Padding'] }
        if ($Properties.Contains('BorderThickness')) { $Control.BorderThickness = New-Object System.Windows.Thickness $Properties['BorderThickness'] }
        if ($Properties.Contains('CornerRadius')) { $Control.CornerRadius = New-Object System.Windows.CornerRadius $Properties['CornerRadius'] }
        
        if ($Properties.Contains('GridRow')) { [System.Windows.Controls.Grid]::SetRow($Control, $Properties['GridRow']) }
        if ($Properties.Contains('GridRowSpan')) { [System.Windows.Controls.Grid]::SetRowSpan($Control, $Properties['GridRowSpan']) }
        if ($Properties.Contains('GridCol')) { [System.Windows.Controls.Grid]::SetColumn($Control, $Properties['GridCol']) }
        if ($Properties.Contains('GridColSpan')) { [System.Windows.Controls.Grid]::SetColumnSpan($Control, $Properties['GridColSpan']) }
        if ($Properties.Contains('Dock')) { [System.Windows.Controls.DockPanel]::SetDock($Control, $Properties['Dock']) }
        
        if ($Properties.Contains('LayoutTransform'))
        {
            $transform = $Properties['LayoutTransform']
            if ($transform -is [scriptblock]) { $transform = & $transform }
            if (@($transform).Count -gt 1)
            {
                $group = New-Object System.Windows.Media.TransformGroup
                foreach ($child in $transform) { $group.Children.Add($child) }
                $transform = $group
            }
            $Control.LayoutTransform = $transform
        }

        if ($Properties.Contains('ContextMenu'))
        {
            $contextmenu = $Properties['ContextMenu']
            if ($contextmenu -is [scriptblock]) { $contextmenu = & $contextmenu }
            $Control.ContextMenu = $contextmenu
        }

        if ($Properties.Contains('Style'))
        {
            $style = $Properties['Style']
            if ($style -is [scriptblock]) { $style = New-UIStyle $style }
            $Control.Style = Get-UIStyleFinalized $style $controlType
        }

        if ($Properties.Contains('Align'))
        {
            $align = $Properties['Align']
            if ($align -in 'TopLeft', 'TopRight', 'TopCenter', 'TopStretch') { $Control.VerticalAlignment = 'Top' }
            elseif ($align -in 'BottomLeft', 'BottomRight', 'BottomCenter', 'BottomStretch') { $Control.VerticalAlignment = 'Bottom' }
            elseif ($align -in 'CenterLeft', 'CenterRight', 'Center', 'CenterStretch') { $Control.VerticalAlignment = 'Center' }
            else { $Control.VerticalAlignment = 'Stretch' }
            if ($align -in 'TopLeft', 'CenterLeft', 'BottomLeft', 'StretchLeft') { $Control.HorizontalAlignment = 'Left' }
            elseif ($align -in 'TopRight', 'CenterRight', 'BottomRight', 'StretchRight') { $Control.HorizontalAlignment = 'Right' }
            elseif ($align -in 'TopCenter', 'Center', 'BottomCenter', 'StretchCenter') { $Control.HorizontalAlignment = 'Center' }
            else { $Control.HorizontalAlignment = 'Stretch' }
        }

        if ($Properties.Contains('AlsoSet'))
        {
            foreach ($pair in $Properties['AlsoSet'].GetEnumerator())
            {
                $Control.($pair.Key) = $pair.Value
            }
        }

        if (!$asFactory) { return $Control }

        # If in factory mode, make a new factory and copy all properties from the control to the factory
        $factory = New-Object System.Windows.FrameworkElementFactory $controlType
        
        # Copy all basic properties
        $copyPropertyList = New-Object System.Collections.Generic.List[string]
        $otherSimplePropertyList = 'Margin', 'Padding', 'BorderThickness', 'CornerRadius', 'ContextMenu', 'Style', 'LayoutTransform'
        foreach ($property in ($Script:SimplePropertyDict.Keys + $otherSimplePropertyList))
        {
            if ($Properties.Contains($property)) { $copyPropertyList.Add($property) }
        }
        foreach ($property in $Properties['AlsoSet'].Keys) { $copyPropertyList.Add($propery) }
        if ($Properties.Contains('Align')) { $copyPropertyList.Add('VerticalAlignment'); $copyPropertyList.Add('HorizontalAlignment') }
        foreach ($copyProperty in $copyPropertyList)
        {
            $factory.SetValue($controlType::"${copyProperty}Property", $Control.$copyProperty)
        }

        # Set advanced properties
        if ($Properties.Contains('GridRow')) { $factory.SetValue([System.Windows.Controls.Grid]::RowProperty, $Properties['GridRow']) }
        if ($Properties.Contains('GridRowSpan')) { $factory.SetValue([System.Windows.Controls.Grid]::RowSpanProperty, $Properties['GridRowSpan']) }
        if ($Properties.Contains('GridCol')) { $factory.SetValue([System.Windows.Controls.Grid]::ColumnProperty, $Properties['GridCol']) }
        if ($Properties.Contains('GridColSpan')) { $factory.SetValue([System.Windows.Controls.Grid]::ColumnSpanProperty, $Properties['GridColSpan']) }
        if ($Properties.Contains('Dock')) { $factory.SetValue([System.Windows.Controls.DockPanel]::DockProperty, $Properties['Dock']) }

        # Set bindings and events
        foreach ($eventProperty in $eventPropertyList)
        {
            if (!$Properties.Contains("Add${eventProperty}")) { continue }
            $delegate = [System.Windows.RoutedEventHandler]$Properties["Add${eventProperty}"]
            $factory.AddHandler($controlType::"${eventProperty}Event", $delegate)
        }
        foreach ($property in $Properties.Keys)
        {
            if ($Script:BindPropertyDict.Contains($property))
            {
                $bindProperty = $Script:BindPropertyDict[$property]
                $binding = New-Object System.Windows.Data.Binding $Properties[$property]
                $factory.SetBinding($controlType::"${bindProperty}Property", $binding)
            }
            elseif ($Script:EventPropertyDict.Contains($property))
            {
                $eventProperty = $Script:EventPropertyDict[$property]
                $delegate = [System.Windows.RoutedEventHandler]$Properties[$property]
                $factory.AddHandler($controlType::"${eventProperty}Event", $delegate)
            }
        }
        
        # Add children / set content property
        if ($children)
        {
            foreach ($child in $children) { $factory.AppendChild($child) }
        }

        $factory
    }
}

Function Add-UIBinding
{
    Param
    (
        [Parameter(ValueFromPipeline=$true)] [object] $Control,
        [Parameter(Mandatory=$true,Position=0)] [string] $Property,
        [Parameter(Mandatory=$true,Position=1)] [string] $Path,
        [Parameter()] [object] $FallbackValue,
        [Parameter()] [ValidateSet('Self', 'TemplatedParent', 'PreviousData')] $RelativeSource,
        [Parameter()] [ValidateSet('InvertBool', 'BoolToVisibility')] [string[]] $Converter
    )
    Process
    {
        if (!$Control) { return }
        $type = $Control.GetType()
        if ($Control -is [System.Windows.FrameworkElementFactory]) { $type = $Control.Type }
        $dp = $type::"${Property}Property"
        if (!$dp)
        {
            Write-Error "Property '$Property' is not avaialble for '$($type.Name)'."
            $Control
            return
        }

        $binding = New-Object System.Windows.Data.Binding $Path
        if ($RelativeSource) { $binding.RelativeSource = [System.Windows.Data.RelativeSource]::$RelativeSource }
        if ($PSBoundParameters['FallbackValue']) { $binding.FallbackValue = $FallbackValue -as $dp.PropertyType }

        if ($Converter)
        {
            if ($Converter.Count -eq 1)
            {
                $finalConverter = New-Object "Rhodium.UI.${Converter}Converter"
            }
            else
            {
                $finalConverter = New-Object Rhodium.UI.ValueConverterGroup
                foreach ($converterName in $Converter)
                {
                    $finalConverter.Add((New-Object "Rhodium.UI.${converterName}Converter"))
                }
            }
            $binding.Converter = $finalConverter
        }

        if ($Control -is [System.Windows.FrameworkElementFactory])
        {
            $Control.SetBinding($dp, $binding)
        }
        else
        {
            [void][System.Windows.Data.BindingOperations]::SetBinding($Control, $dp, $binding)
        }
        $Control
    }
}

Function Add-UIEvent
{
    Param
    (
        [Parameter(ValueFromPipeline=$true)] [object] $Control,
        [Parameter(Mandatory=$true,Position=0)] [string] $Event,
        [Parameter(Mandatory=$true,Position=1)] [scriptblock] $Script
    )
    Process
    {
        if (!$Control) { return }
        try
        {
            $Control."Add_$Event"($Script)
        }
        catch
        {
            Write-Error "Event '$Event' is not available for '$($Control.GetType().Name)'."
        }
        $Control
    }
}

Function New-UIObject
{
    Param
    (
        [Parameter(ValueFromPipeline=$true,Position=0)] [object] $BaseObject
    )
    Process
    {
        try { [void][Rhodium.UI.UIObject] }
        catch
        {
            $text = [System.IO.File]::ReadAllText("$PSScriptRoot\UIObject\UIObject.cs")
            Add-Type -TypeDefinition $text -ReferencedAssemblies WindowsBase
            Update-TypeData -TypeName "Rhodium.UI.UIObject" -TypeAdapter "Rhodium.UI.UIObjectAdapter"
        }
        [Rhodium.UI.UIObject]::FromPSObject([pscustomobject]$BaseObject)
    }
}

Function New-UIObjectCollection
{
    Param
    (
        [Parameter(ValueFromPipeline=$true)] [object] $InputObject
    )
    Begin
    {
        try { [void][Rhodium.UI.UIObject] }
        catch
        {
            $text = [System.IO.File]::ReadAllText("$PSScriptRoot\UIObject\UIObject.cs")
            Add-Type -TypeDefinition $text -ReferencedAssemblies WindowsBase
            Update-TypeData -TypeName "Rhodium.UI.UIObject" -TypeAdapter "Rhodium.UI.UIObjectAdapter"
        }
        $collection = New-Object Rhodium.UI.UIObjectCollection
    }
    Process
    {
        if (!$InputObject) { return }
        if ($InputObject -is [Rhodium.UI.UIObject]) { $collection.Add($InputObject) }
        else { $collection.Add([Rhodium.UI.UIObject]::FromPSObject([pscustomobject]$InputObject)) }
    }
    End
    {
        ,$collection
    }
}

Function New-UIPowerShell
{
    Param
    (
        [Parameter()] [PSVariable[]] $SetVariables
    )
    End
    {
        New-UIObject | Out-Null # To load the types

        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $typeData = New-Object System.Management.Automation.Runspaces.TypeData ([Rhodium.UI.UIObject])
        $typeData.TypeAdapter = [Rhodium.UI.UIObjectAdapter]
        $typeEntry = New-Object System.Management.Automation.Runspaces.SessionStateTypeEntry $typeData, $false
        $iss.Types.Add($typeEntry)
        $typeData = New-Object System.Management.Automation.Runspaces.TypeData ([Rhodium.UI.UIObjectCollection])
        $typeEntry = New-Object System.Management.Automation.Runspaces.SessionStateTypeEntry $typeData, $false
        $iss.Types.Add($typeEntry)
        $iss.Commands.Add((New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry 'New-UIObject', ${function:New-UIObject}))
        $iss.Commands.Add((New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry 'New-UIObjectCollection', ${function:New-UIObjectCollection}))

        $runspace = [RunSpaceFactory]::CreateRunspace($iss)
        $runspace.ApartmentState = "STA"
        $runspace.ThreadOptions = "ReuseThread"
        $runspace.Open()

        if ($SetVariables)
        {
            foreach ($var in $SetVariables)
            {
                $runspace.SessionStateProxy.SetVariable($var.Name, $var.Value)
            }
        }

        $powershell = [PowerShell]::Create()
        $powershell.Runspace = $runspace

        $powershell
    }
}

Function Invoke-UIPowerShell
{
    Param
    (
        [Parameter(Mandatory=$true)] [ScriptBlock] $ScriptBlock,
        [Parameter()] [PSVariable[]] $SetVariables
    )
    End
    {
        $powershell = New-UIPowerShell -SetVariables $SetVariables
        [void]$powershell.AddScript($ScriptBlock).BeginInvoke()
        $powershell
    }
}

Function Find-UIParent
{
    Param
    (
        [Parameter(Mandatory=$true,ParameterSetName='Type')] [string] $Type
    )
    process
    {
        $parent = $PSCmdlet.SessionState.PSVariable.GetValue("this")
        while ($parent)
        {
            if ($parent.GetType().Name -eq $Type) { return $parent }
            $parent = $parent.Parent
        }
    }
}

Function Get-UIScreenshot
{
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [object] $UIElement,
        [Parameter(Mandatory=$true)] [ValidateSet('Clipboard')] $As
    )
    Process
    {
        $renderer = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($UIElement.ActualWidth, $UIElement.ActualHeight, 96d, 96d, [System.Windows.Media.PixelFormats]::Default)
        $renderer.Render($UIElement)

        $pngEncoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $pngEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($renderer))

        $memStream = New-Object System.IO.MemoryStream
        $pngEncoder.Save($memStream)
        $memStream.Close()

        $bytes = $memStream.ToArray()

        $memStream = New-Object System.IO.MemoryStream @($bytes, 0, $bytes.Length)
        $image = [System.Drawing.Image]::FromStream($memStream)
        [System.Windows.Forms.Clipboard]::SetImage($image)
    }
}

Function Show-UIMessageBox
{
    Param
    (
        [Parameter(Position=0,ValueFromPipeline=$true,Mandatory=$true)] [string] $Message,
        [Parameter()] [string] $Caption,
        [Parameter()] [System.Windows.Forms.MessageBoxButtons] $Buttons
    )
    Process
    {
        $Caption = "$Caption"
        if ($Buttons) { return [System.Windows.MessageBox]::Show($Message, $Caption, $Buttons) }
        else { [void][System.Windows.MessageBox]::Show($Message, $Caption) }
    }
}

Function New-UIStyle
{
    Param
    (
        [Parameter(Mandatory=$true,Position=0)] [scriptblock] $Definition
    )
    End
    {
        $def = [ordered]@{}
        $def.Type = 'WpfStyle'
        $def.Definition = & $Definition
        $def.FinalizeDict = @{}
        [pscustomobject]$def
    }
}

Function New-UISetter
{
    Param
    (
        [Parameter(Mandatory=$true,Position=0)] [string] $Property,
        [Parameter(Mandatory=$true,Position=1)] [object] $Value
    )
    End
    {
        $def = [ordered]@{}
        $def.Type = 'WpfSetter'
        $def.Property = $Property
        $def.Value = $Value
        [pscustomobject]$def
    }
}

Function New-UITrigger
{
    Param
    (
        [Parameter(Mandatory=$true,Position=0)] [string] $Property,
        [Parameter(Mandatory=$true,Position=1)] [object] $Value,
        [Parameter(Mandatory=$true,Position=2)] [scriptblock] $Definition
    )
    End
    {
        $def = [ordered]@{}
        $def.Type = 'WpfTrigger'
        $def.Property = $Property
        $def.Value = $Value
        $def.Definition = & $Definition
        [pscustomobject]$def
    }
}

Function New-UIDataTrigger
{
    Param
    (
        [Parameter(Mandatory=$true,Position=0)] [string] $Path,
        [Parameter(Mandatory=$true,Position=1)] [object] $Value,
        [Parameter(Mandatory=$true,Position=2)] [scriptblock] $Definition
    )
    End
    {
        $def = [ordered]@{}
        $def.Type = 'WpfDataTrigger'
        $def.Path = $Path
        $def.Value = $Value
        $def.Definition = & $Definition
        [pscustomobject]$def
    }
}

Function Get-UIStyleFinalized
{
    Param
    (
        [Parameter(Mandatory=$true,Position=0)] [object] $UIStyle,
        [Parameter(Mandatory=$true,Position=1)] [type] $Type
    )
    End
    {
        if ($UIStyle.FinalizeDict.Contains($Type))
        {
            return $UIStyle.FinalizeDict[$Type]
        }

        $style = New-Object System.Windows.Style
        $style.TargetType = $Type

        foreach ($item in $UIStyle.Definition)
        {
            if ($item.Type -eq 'WpfSetter')
            {
                $setter = New-Object System.Windows.Setter
                $setter.Property = $Type::"$($item.Property)Property"
                $setter.Value = $item.Value -as $setter.Property.PropertyType
                $style.Setters.Add($setter)
            }
            elseif ($item.Type -in 'WpfTrigger', 'WpfDataTrigger')
            {
                if ($item.Type -eq 'WpfTrigger')
                {
                    $trigger = New-Object System.Windows.Trigger
                    $trigger.Property = $Type::"$($item.Property)Property"
                    $trigger.Value = $item.Value -as $trigger.Property.PropertyType
                }
                elseif ($item.Type -eq 'WpfDataTrigger')
                {
                    $trigger = New-Object System.Windows.DataTrigger
                    $trigger.Binding = New-Object System.Windows.Data.Binding $item.Path
                    $trigger.Value = $item.Value
                }
                foreach ($subItem in $item.Definition)
                {
                    if ($subItem.Type -eq 'WpfSetter')
                    {
                        $setter = New-Object System.Windows.Setter
                        $setter.Property = $Type::"$($subItem.Property)Property"
                        $setter.Value = $subItem.Value -as $setter.Property.PropertyType
                        $trigger.Setters.Add($setter)
                    }
                }
                $style.Triggers.Add($trigger)
            }
        }

        $UIStyle.FinalizeDict[$Type] = $style
        return $style
    }
}

Function New-UISolidColorBrush
{
    [OutputType([System.Windows.Media.SolidColorBrush])]
    [CmdletBinding(DefaultParameterSetName='RGB')]
    Param
    (
        [Parameter(Mandatory=$true,ParameterSetName='RGB')] [ValidateCount(3,3)] [byte[]] $RGB,
        [Parameter(Mandatory=$true,ParameterSetName='ARGB')] [ValidateCount(4,4)] [byte[]] $ARGB,
        [Parameter(Mandatory=$true,ParameterSetName='Name')] [string] $Name
    )
    End
    {
        if ($RGB) { $color = [System.Windows.Media.Color]::FromRgb($RGB[0], $RGB[1], $RGB[2]) }
        elseif ($ARGB) { $color = [System.Windows.Media.Color]::FromArgb($ARGB[0], $ARGB[1], $ARGB[2], $ARGB[3]) }
        elseif ($Name) { $color = [System.Windows.Media.Color]$Name }
        New-Object System.Windows.Media.SolidColorBrush $color
    }
}

Function New-UILinearGradientBrush
{
    [OutputType([System.Windows.Media.LinearGradientBrush])]
    Param
    (
        [Parameter(Mandatory=$true)] [ValidateCount(2,2)] [double[]] $StartPoint,
        [Parameter(Mandatory=$true)] [ValidateCount(2,2)] [double[]] $EndPoint,
        [Parameter(Mandatory=$true)] [object[]] $GradientStops

    )
    End
    {
        trap { $PSCmdlet.ThrowTerminatingError($_) }
        $brush = New-Object System.Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object System.Windows.Point $StartPoint
        $brush.EndPoint = New-Object System.Windows.Point $EndPoint

        foreach ($stopArray in $GradientStops)
        {
            $gradientStop = New-Object System.Windows.Media.GradientStop
            $gradientStop.Offset = $stopArray[0]
            if ($stopArray.Count -eq 2)
            {
                $gradientStop.Color = $stopArray[1]
            }
            elseif ($stopArray.Count -eq 4)
            {
                $gradientStop.Color = [System.Windows.Media.Color]::FromRgb($stopArray[1], $stopArray[2], $stopArray[3])
            }
            elseif ($stopArray.Count -eq 5)
            {
                $gradientStop.Color = [System.Windows.Media.Color]::FromArgb($stopArray[1], $stopArray[2], $stopArray[3], $stopArray[4])
            }
            else
            {
                throw "GradientStop must be an array of arrays, each containing the Offset followed by a Color, RGB or ARBG values."
            }
            $brush.GradientStops.Add($gradientStop)
        }

        $brush
    }
}

# ======================================================================================================================
# Manual Functions
# ======================================================================================================================

Function Show-UIWindow
{
    Param
    (
        [Parameter(ValueFromPipeline=$true,ParameterSetName='Input')] [System.Windows.Window] $Window,
        [Parameter(Position=0,ParameterSetName='Content')] [object] $Content,
        [Parameter(ParameterSetName='Content')] [string] $Title,
        [Parameter(ParameterSetName='Content')] [double] $Width,
        [Parameter(ParameterSetName='Content')] [double] $MinWidth,
        [Parameter(ParameterSetName='Content')] [double] $MaxWidth,
        [Parameter(ParameterSetName='Content')] [double] $Height,
        [Parameter(ParameterSetName='Content')] [double] $MinHeight,
        [Parameter(ParameterSetName='Content')] [double] $MaxHeight,
        [Parameter(ParameterSetName='Content')] [scriptblock] $AddLoaded,
        [Parameter(ParameterSetName='Content')] [scriptblock] $AddClosing,
        [Parameter(ParameterSetName='Content')] [System.Windows.SizeToContent] $SizeToContent,
        [Parameter(ParameterSetName='Content')] [System.Windows.WindowStyle] $WindowStyle,
        [Parameter(ParameterSetName='Content')] [object] $DataContext,
        [Parameter(ParameterSetName='Content')] [hashtable] $AlsoSet
    )
    Process
    {
        if ($Window)
        {
            [void]$Window.Dispatcher.InvokeAsync({ [void]$Window.ShowDialog() }).Wait()
        }
    }
    End
    {
        if ($Window) { return }
        $control = New-Object System.Windows.Window
        [System.Windows.Controls.Grid]::SetIsSharedSizeScope($control, $true)
        Set-UIKnownProperty $control $PSBoundParameters | Out-Null
        [void]$control.Dispatcher.InvokeAsync({ [void]$control.ShowDialog() }).Wait()
    }
}

# ======================================================================================================================
# Generated Functions
# ======================================================================================================================

$Script:NewUIObjectTemplate = [string]{
    [OutputType([Rhodium.UI.ObjectType])]
    Param
    (
        # %%CustomParamBlock%%
        [Parameter()] [double] $Width,
        [Parameter()] [double] $MinWidth,
        [Parameter()] [double] $MaxWidth,
        [Parameter()] [double] $Height,
        [Parameter()] [double] $MinHeight,
        [Parameter()] [double] $MaxHeight,
        [Parameter()] [double[]] $Margin,
        [Parameter()] [Rhodium.UI.Align] $Align,
        [Parameter()] [int] $GridRow,
        [Parameter()] [int] $GridRowSpan,
        [Parameter()] [int] $GridCol,
        [Parameter()] [int] $GridColSpan,
        [Parameter()] [System.Windows.Controls.Dock] $Dock,
        [Parameter()] [object] $LayoutTransform,
        [Parameter()] [object] $ContextMenu,
        [Parameter()] [hashtable] $AlsoSet,
        [Parameter()] [object] $DataContext,
        [Parameter()] [object] $Tag,
        [Parameter()] [object] $Style,
        [Parameter()] [switch] $AsFactory
    )

    $control = New-Object Rhodium.UI.ObjectType
    # %%SetScript%%
}

$Script:NewUIObjectBareTemplate = [string]{
    [OutputType([Rhodium.UI.ObjectType])]
    Param
    (
        # %%CustomParamBlock%%
        [Parameter()] [hashtable] $AlsoSet,
        [Parameter()] [object] $DataContext,
        [Parameter()] [object] $Tag
    )

    $control = New-Object Rhodium.UI.ObjectType
    # %%SetScript%%
}

$Script:FunctionList = New-Object System.Collections.Generic.List[PSObject]

Function New-UIFunction
{
    Param
    (
        [Parameter(Mandatory=$true,Position=0)] [string] $ObjectName,
        [Parameter(Mandatory=$true,Position=1)] [type] $ObjectType,
        [Parameter(Mandatory=$true,Position=2)] [string] $ParamBlock,
        [Parameter()] [string] $CustomScript,
        [Parameter()] [switch] $BareTemplate,
        [Parameter()] [string[]] $PrivateParameters
    )
    $script = $CustomScript
    if (!$CustomScript) { $script = 'Set-UIKnownProperty $control $PSBoundParameters' }

    $Script:Function = [pscustomobject][ordered]@{
        ObjectName = $ObjectName
        ObjectType = $ObjectType
        ParamBlock = $ParamBlock
        Script = $script
        BareTemplate = $BareTemplate.IsPresent
        PrivateParameters = $PrivateParameters
    }
    $Script:FunctionList.Add($Script:Function)
}

# -------------------------------------------------------
# Containers
# -------------------------------------------------------

New-UIFunction Window ([System.Windows.Window]) {
        [Parameter(Position=0)] [object] $Content,
        [Parameter()] [string] $Title,
        [Parameter()] [System.Windows.SizeToContent] $SizeToContent,
        [Parameter()] [System.Windows.WindowStyle] $WindowStyle,
        [Parameter()] [scriptblock] $AddLoaded,
        [Parameter()] [scriptblock] $AddClosing
} -CustomScript {
    $control = New-Object System.Windows.Window
    [System.Windows.Controls.Grid]::SetIsSharedSizeScope($control, $true)
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction Border ([System.Windows.Controls.Border]) {
    [Parameter(Position=0)] [object] $Child,
    [Parameter()] [System.Windows.Media.Brush] $BorderBrush,
    [Parameter()] [System.Windows.Media.Brush] $Background,
    [Parameter()] [double[]] $BorderThickness,
    [Parameter()] [double[]] $CornerRadius
}

New-UIFunction ContentControl ([System.Windows.Controls.ContentControl]) {
    [Parameter(Position=0)] [object] $Content,
    [Parameter()] [string] $BindContentTo
}

New-UIFunction DockPanel ([System.Windows.Controls.DockPanel]) {
    [Parameter(Position=0)] [object] $Children
}

New-UIFunction Grid ([System.Windows.Controls.Grid]) {
    [Parameter(Position=0)] [object] $Children,
    [Parameter()] [string[]] $RowDef,
    [Parameter()] [string[]] $RowDefGroup,
    [Parameter()] [string[]] $ColDef,
    [Parameter()] [string[]] $ColDefGroup
} -PrivateParameters RowDef, RowDefGroup, ColDef, ColDefGroup -CustomScript {
    foreach ($def in $RowDef)
    {
        $row = New-Object System.Windows.Controls.RowDefinition
        if ($def -eq 'auto') { $row.Height = [System.Windows.GridLength]::Auto }
        elseif ($def -eq '*') { $row.Height = New-Object System.Windows.GridLength 1, Star }
        elseif ($def -match '(\d+)\*') { $row.Height = New-Object System.Windows.GridLength $Matches[1], Star }
        else { $row.Height = New-Object System.Windows.GridLength $def }
        if ($RowDefGroup) { $row.SharedSizeGroup = $RowDefGroup[$control.RowDefinitions.Count] }
        $control.RowDefinitions.Add($row)
    }
    foreach ($def in $ColDef)
    {
        $col = New-Object System.Windows.Controls.ColumnDefinition
        if ($def -eq 'auto') { $col.Width = [System.Windows.GridLength]::Auto }
        elseif ($def -eq '*') { $col.Width = New-Object System.Windows.GridLength 1, Star }
        elseif ($def -match '(\d+)\*') { $col.Width = New-Object System.Windows.GridLength $Matches[1], Star }
        else { $col.Width = New-Object System.Windows.GridLength $def }
        if ($ColDefGroup) { $col.SharedSizeGroup = $ColDefGroup[$control.ColumnDefinitions.Count] }
        $control.ColumnDefinitions.Add($col)
    }
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction GridSplitter ([System.Windows.Controls.GridSplitter]) {
    [Parameter()] [System.Windows.Media.Brush] $Background
}

New-UIFunction GroupBox ([System.Windows.Controls.GroupBox]) {
    [Parameter(Position=0)] [string] $Header,
    [Parameter(Position=1)] [object] $Content
}

New-UIFunction ItemsControl ([System.Windows.Controls.ItemsControl]) {
    [Parameter(Position=0)] [scriptblock] $ItemTemplate,
    [Parameter()] [string] $BindItemsSourceTo
} -PrivateParameters ItemTemplate -CustomScript {
    if ($ItemTemplate)
    {
        $defaultParameterValues = New-Object System.Management.Automation.DefaultParameterDictionary @{"New-UI*:AsFactory"=$true}
        $dataTemplate = New-Object System.Windows.DataTemplate
        $dataTemplate.VisualTree = $ItemTemplate.InvokeWithContext($null, (New-Object PSVariable PSDefaultParameterValues, $defaultParameterValues), $null)[0]
        $control.ItemTemplate = $dataTemplate
    }
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction ScrollViewer ([System.Windows.Controls.ScrollViewer]) {
    [Parameter(Position=0)] [object] $Content,
    [Parameter()] [System.Windows.Controls.ScrollBarVisibility] $VerticalScrollBarVisibility,
    [Parameter()] [System.Windows.Controls.ScrollBarVisibility] $HorizontalScrollBarVisibility
}

New-UIFunction StackPanel ([System.Windows.Controls.StackPanel]) {
    [Parameter(Position=0)] [object] $Children,
    [Parameter()] [System.Windows.Controls.Orientation] $Orientation
}

New-UIFunction TabControl ([System.Windows.Controls.TabControl]) {
    [Parameter(Position=0)] [object] $Items,
    [Parameter()] [int] $SelectedIndex
}

New-UIFunction TabItem ([System.Windows.Controls.TabItem]) {
    [Parameter(Position=0)] [object] $Header,
    [Parameter(Position=1)] [object] $Content
}

New-UIFunction TreeView ([System.Windows.Controls.TreeView]) {
    [Parameter(Position=0)] [object] $Children,
    [Parameter()] [scriptblock] $AddSelectedItemChanged
}

New-UIFunction TreeViewItem ([System.Windows.Controls.TreeViewItem]) {
    [Parameter(Position=0)] [string] $Header,
    [Parameter(Position=1)] [object] $Children,
    [Parameter()] [bool] $IsExpanded
}

New-UIFunction UniformGrid ([System.Windows.Controls.Primitives.UniformGrid]) {
    [Parameter(Position=0)] [object] $Children,
    [Parameter()] [int] $Rows,
    [Parameter()] [int] $Columns
}

New-UIFunction Viewbox ([System.Windows.Controls.Viewbox]) {
    [Parameter(Position=0)] [object] $Child,
    [Parameter()] [System.Windows.Media.Stretch] $Stretch
}

New-UIFunction WrapPanel ([System.Windows.Controls.WrapPanel]) {
    [Parameter(Position=0)] [object] $Children,
    [Parameter()] [System.Windows.Controls.Orientation] $Orientation
}

New-UIFunction ContextMenu ([System.Windows.Controls.ContextMenu]) -BareTemplate {
    [Parameter(Position=0)] [object] $Children
}

New-UIFunction Menu ([System.Windows.Controls.Menu]) {
    [Parameter(Position=0)] [object] $Children
}

New-UIFunction MenuItem ([System.Windows.Controls.MenuItem]) {
    [Parameter(Position=0)] [string] $Header,
    [Parameter(Position=1)] [object] $Children,
    [Parameter()] [string] $BindIsCheckedTo,
    [Parameter()] [bool] $IsCheckable,
    [Parameter()] [scriptblock] $AddClick
}

# -------------------------------------------------------
# Elements
# -------------------------------------------------------

New-UIFunction Button ([System.Windows.Controls.Button]) {
    [Parameter(Position=0)] [object] $Content,
    [Parameter()] [scriptblock] $AddClick,
    [Parameter()] [double[]] $Padding
}

New-UIFunction CheckBox ([System.Windows.Controls.CheckBox]) {
    [Parameter(Position=0)] [object] $Content,
    [Parameter()] [string] $BindIsCheckedTo
}

New-UIFunction ComboBox ([System.Windows.Controls.ComboBox]) {
    [Parameter()] [object[]] $ItemsSource,
    [Parameter()] [string] $DisplayMemberPath,
    [Parameter()] [string] $SelectedValuePath,
    [Parameter()] [string] $BindItemsSourceTo,
    [Parameter()] [string] $BindSelectedValueTo
}

New-UIFunction DataGrid ([System.Windows.Controls.DataGrid]) {
    [Parameter()] [object[]] $Columns,
    [Parameter()] [object[]] $ItemsSource,
    [Parameter()] [System.Windows.Controls.SelectionMode] $SelectionMode,
    [Parameter()] [string] $BindItemsSourceTo,
    [Parameter()] [string] $BindSelectedItemTo
} -CustomScript {
    if ($Columns)
    {
        $control.AutoGenerateColumns = $false
        foreach ($column in $Columns)
        {
            $dataGridColumn = New-Object System.Windows.Controls.DataGridTextColumn
            $dataGridColumn.Header = $column
            $dataGridColumn.Binding = New-Object System.Windows.Data.Binding $column
            $control.Columns.Add($dataGridColumn)
        }
        [void]$PSBoundParameters.Remove('Columns')
    }
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction DatePicker ([System.Windows.Controls.DatePicker]) {
    [Parameter()] [string] $BindSelectedDateTo
}

New-UIFunction Ellipse ([System.Windows.Shapes.Ellipse]) {
    [Parameter()] [System.Windows.Media.Brush] $Fill,
    [Parameter()] [System.Windows.Media.Brush] $Stroke,
    [Parameter()] [double] $StrokeThickness
}

New-UIFunction GridViewColumn ([System.Windows.Controls.GridViewColumn]) {
    [Parameter(Position=0)] [object] $Header,
    [Parameter(Position=1)] [object] $CellTemplate
} -PrivateParameters CellTemplate -CustomScript {
    if ($CellTemplate -is [string])
    {
        $control.DisplayMemberBinding = New-Object System.Windows.Data.Binding $CellTemplate
    }
    elseif ($CellTemplate)
    {
        if ($CellTemplate -is [scriptblock])
        {
            $defaultParameterValues = New-Object System.Management.Automation.DefaultParameterDictionary @{"New-UI*:AsFactory"=$true}
            $CellTemplate = $CellTemplate.InvokeWithContext($null, (New-Object PSVariable PSDefaultParameterValues, $defaultParameterValues), $null)[0]
        }
        $dataTemplate = New-Object System.Windows.DataTemplate
        $dataTemplate.VisualTree = $CellTemplate
        $control.CellTemplate = $dataTemplate
    }
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction Label ([System.Windows.Controls.Label]) {
    [Parameter(Position=0)] [object] $Content
}

New-UIFunction Line ([System.Windows.Shapes.Line]) {
    [Parameter()] [double] $X1,
    [Parameter()] [double] $Y1,
    [Parameter()] [double] $X2,
    [Parameter()] [double] $Y2,
    [Parameter()] [double] $StrokeThickness,
    [Parameter()] [System.Windows.Media.Brush] $Stroke
}

New-UIFunction ListView ([System.Windows.Controls.ListView]) {
    [Parameter()] [object[]] $Columns,
    [Parameter()] [object[]] $ItemsSource,
    [Parameter()] [System.Windows.Controls.SelectionMode] $SelectionMode,
    [Parameter()] [string] $BindItemsSourceTo,
    [Parameter()] [string] $BindSelectedItemTo
} -CustomScript {
    if ($Columns)
    {
        $view = New-Object System.Windows.Controls.GridView
        $columnList = foreach ($column in $Columns)
        {
            if ($column -is [string])
            {
                $gridViewColumn = New-Object System.Windows.Controls.GridViewColumn
                $gridViewColumn.Header = $column
                $gridViewColumn.DisplayMemberBinding = New-Object System.Windows.Data.Binding $column
                $gridViewColumn
                continue
            }
            & $column
        }
        foreach ($column in $columnList) { $view.Columns.Add($column) }
        $control.View = $view
        [void]$PSBoundParameters.Remove('Columns') # Otherwise Set-UIKnownProperty will mess this up
    }
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction PasswordBox ([System.Windows.Controls.PasswordBox]) {
    
}

New-UIFunction Polyline ([System.Windows.Shapes.Polyline]) {
    [Parameter(Mandatory=$true)] [double[]] $Points,
    [Parameter()] [double] $StrokeThickness,
    [Parameter()] [System.Windows.Media.Brush] $Stroke
} -CustomScript {
    for ($i = 0; $i -lt $Points.Count; $i+=2)
    {
        $point = New-Object System.Windows.Point $Points[$i], $Points[$i+1]
        $control.Points.Add($point)
    }
    [void]$PSBoundParameters.Remove('Points')
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction ProgressBar ([System.Windows.Controls.ProgressBar]) {
    [Parameter()] [double] $Minimum,
    [Parameter()] [double] $Maximum,
    [Parameter()] [string] $BindMaximumTo,
    [Parameter()] [string] $BindValueTo
}

New-UIFunction RadioButton ([System.Windows.Controls.RadioButton]) {
    [Parameter(Position=0)] [object] $Content,
    [Parameter()] [string] $BindIsCheckedTo
}

New-UIFunction Rectangle ([System.Windows.Shapes.Rectangle]) {
    [Parameter()] [System.Windows.Media.Brush] $Fill,
    [Parameter()] [System.Windows.Media.Brush] $Stroke,
    [Parameter()] [double] $StrokeThickness
}

New-UIFunction RichTextBox ([System.Windows.Controls.RichTextBox]) {
    
}

New-UIFunction Slider ([System.Windows.Controls.Slider]) {
    [Parameter()] [double] $Minimum,
    [Parameter()] [double] $Maximum,
    [Parameter()] [string] $BindValueTo,
    [Parameter()] [System.Windows.Controls.Orientation] $Orientation,
    [Parameter()] [System.Windows.Controls.Primitives.TickPlacement] $TickPlacement,
    [Parameter()] [double] $TickFrequency,
    [Parameter()] [double[]] $Ticks,
    [Parameter()] [System.Windows.Media.Brush] $Foreground
}

New-UIFunction TextBlock ([System.Windows.Controls.TextBlock]) {
    [Parameter(Position=0)] [string] $Text,
    [Parameter()] [double] $FontSize,
    [Parameter()] [object] $FontWeight,
    [Parameter()] [object] $FontStyle,
    [Parameter()] [object] $FontFamily,
    [Parameter()] [System.Windows.TextAlignment] $TextAlignment,
    [Parameter()] [System.Windows.Media.Brush] $Foreground,
    [Parameter()] [string] $BindTextTo
}

New-UIFunction TextBox ([System.Windows.Controls.TextBox]) {
    [Parameter()] [double] $FontSize,
    [Parameter()] [object] $FontWeight,
    [Parameter()] [object] $FontStyle,
    [Parameter()] [object] $FontFamily,
    [Parameter()] [string] $BindTextTo,
    [Parameter()] [bool] $AcceptsReturn,
    [Parameter()] [bool] $IsReadOnly,
    [Parameter()] [int] $MinLines,
    [Parameter()] [System.Windows.Controls.ScrollBarVisibility] $VerticalScrollBarVisibility
}

New-UIFunction RotateTransform ([System.Windows.Media.RotateTransform]) -BareTemplate {
    [Parameter()] [double] $Angle
}

New-UIFunction ScaleTransform ([System.Windows.Media.ScaleTransform]) -BareTemplate {
    [Parameter()] [double] $Scale
} -PrivateParameters Scale -CustomScript {
    if ($Scale) { $control.ScaleX = $Scale; $control.ScaleY = $Scale }
    Set-UIKnownProperty $control $PSBoundParameters
}

foreach ($function in $Script:FunctionList)
{
    if ($function.BareTemplate) { $functionText = $Script:NewUIObjectBareTemplate }
    else { $functionText = $Script:NewUIObjectTemplate }
    $functionText = $functionText.Replace('Rhodium.UI.ObjectType', $function.ObjectType.FullName)
    if (![String]::IsNullOrWhiteSpace($function.ParamBlock))
    {
        $functionText = $functionText.Replace("# %%CustomParamBlock%%", $function.ParamBlock + ",")
    }
    $functionText = $functionText.Replace("# %%SetScript%%", $function.Script)
    $functionScript = [ScriptBlock]::Create($functionText)
    New-Item -Path "Function:\New-UI$($function.ObjectName)" -Value $functionScript -Force

    $bindRegex = [regex]"\ABind(.+)To\Z"
    $eventRegex = [regex]"\AAdd(.+)\Z"
    $parameterDict = (Get-Command -Name "New-UI$($function.ObjectName)").Parameters
    foreach ($parameter in $parameterDict.Keys)
    {
        if ($Script:ProcessedParameterDict[$parameter] -or $Script:ReservedParameterDict[$parameter]) { continue }
        if ($parameter -in $function.PrivateParameters) { continue }
        $Script:ProcessedParameterDict[$parameter] = $true

        $bindMatch = $bindRegex.Match($parameter)
        if ($bindMatch.Success -and $parameterDict[$parameter].ParameterType -eq [string])
        {
            $Script:BindPropertyDict[$parameter] = $bindMatch.Groups[1].Value
            continue
        }

        $eventMatch = $eventRegex.Match($parameter)
        if ($eventMatch.Success -and $parameterDict[$parameter].ParameterType -eq [scriptblock])
        {
            $Script:EventPropertyDict[$parameter] = $eventMatch.Groups[1].Value
            continue
        }

        $Script:SimplePropertyDict[$parameter] = $true
    }
}