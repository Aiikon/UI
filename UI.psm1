[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')

Add-Type @'
namespace Rhodium.UI
{
    public enum Align
    {
        TopLeft, TopRight, TopCenter, TopStretch,
            BottomLeft, BottomRight, BottomCenter, BottomStretch,
            CenterLeft, CenterRight, Center, CenterStretch,
            StretchLeft, StretchRight, StretchCenter, Stretch
    };
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

        $simplePropertyList = 'Width', 'MinWidth', 'MaxWidth', 'Height', 'MinHeight', 'MaxHeight', # Size Properties
            'DataContext', 'Tag', 'ItemsSource', # Data Properties
            'Text', 'Header', 'SelectedIndex', # Value Properties
            'FontSize', 'FontWeight', 'FontStyle', 'FontFamily', # Font Properties
            'Orientation', 'Stretch', 'VerticalScrollBarVisiblity', 'HorizontalScrollBarVisibility', 'Angle', 'Rows', 'Columns', # Layout Properties
            'BorderBrush', 'Background', 'Foreground', # Color Properties
            'DisplayMemberPath', 'SelectedValuePath', # Path Properties
            'IsCheckable', 'IsExpanded', 'Minimum', 'Maximum', 'TickPlacement', 'TickFrequency', 'Ticks', 'SelectionMode' # Other Properties

        $bindPropertyList = 'Text', 'IsChecked', 'ItemsSource', 'SelectedValue', 'SelectedDate', 'Maximum', 'Value', 'Content'

        $eventPropertyList = 'Click', 'SelectedItemChanged'

        foreach ($property in $simplePropertyList)
        {
            if ($Properties.Contains($property)) { $Control.$property = $Properties[$property] }
        }

        foreach ($binding in $bindPropertyList)
        {
            if ($Properties.Contains("Bind${binding}To"))
            {
                [void]$Control.SetBinding($controlType::"${binding}Property", $Properties["Bind${binding}To"])
            }
        }

        foreach ($event in $eventPropertyList)
        {
            if ($Properties.Contains("Add$event"))
            {
                $Control."Add_$event"($Properties["Add$event"])
            }
        }
        
        if ($Properties.Contains('Content')) { $children = $Properties['Content'] }
        elseif ($Properties.Contains('Children')) { $children = $Properties['Children'] }
        elseif ($Properties.Contains('Child')) { $children = $Properties['Child'] }
        elseif ($Properties.Contains('Items')) { $children = $Properties['Items'] }
        else { $children = $null }
        if ($children -is [scriptblock]) { $children = & $children }
        if ($children) { foreach ($child in $children) { $Control.AddChild($child) } }
        
        if ($Properties.Contains('Margin')) { $Control.Margin = New-Object System.Windows.Thickness $Properties['Margin'] }
        if ($Properties.Contains('Padding')) { $Control.Padding = New-Object System.Windows.Thickness $Properties['Padding'] }
        if ($Properties.Contains('BorderThickness')) { $Control.BorderThickness = New-Object System.Windows.Thickness $Properties['BorderThickness'] }
        if ($Properties.Contains('CornerRadius')) { $Control.CornerRadius = New-Object System.Windows.Thickness $Properties['CornerRadius'] }
        
        if ($Properties.Contains('GridRow')) { [System.Windows.Controls.Grid]::SetRow($Control, $Properties['GridRow']) }
        if ($Properties.Contains('GridRowSpan')) { [System.Windows.Controls.Grid]::SetRowSpan($Control, $Properties['GridRowSpan']) }
        if ($Properties.Contains('GridCol')) { [System.Windows.Controls.Grid]::SetColumn($Control, $Properties['GridCol']) }
        if ($Properties.Contains('GridColSpan')) { [System.Windows.Controls.Grid]::SetColumnSpan($Control, $Properties['GridColSpan']) }
        if ($Properties.Contains('Dock')) { [System.Windows.Controls.DockPanel]::SetDock($Control, $Properties['Dock']) }
        
        if ($Properties.Contains('LayoutTransform'))
        {
            $transform = $Properties['LayoutTransform']
            if ($transform -is [scriptblock]) { $transform = & $transform }
            $Control.LayoutTransform = $transform
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

        $Control
    }
}

Function Add-UIBinding
{
    Param
    (
        [Parameter(ValueFromPipeline=$true)] [object] $Control,
        [Parameter(Mandatory=$true,Position=0)] [string] $Property,
        [Parameter(Mandatory=$true,Position=1)] [string] $Path
    )
    Process
    {
        if (!$Control) { return }
        $type = $Control.GetType()
        $dp = $type::"${Property}Property"
        if (!$dp)
        {
            Write-Error "Property '$Property' is not avaialble for '$($type.Name)'."
            $Control
            return
        }

        $binding = New-Object System.Windows.Data.Binding $Path
        [void][System.Windows.Data.BindingOperations]::SetBinding($Control, $dp, $binding)
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
            Add-Type -TypeDefinition $text
            Update-TypeData -TypeName "Rhodium.UI.UIObject" -TypeAdapter "Rhodium.UI.UIObjectAdapter"
        }
        New-Object Rhodium.UI.UIObject
    }
}

Function New-UIPowerShell
{
    Param
    (
        [Parameter()] [string[]] $ImportVariables
    )
    End
    {
        New-UIObject | Out-Null # To load the types

        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $typeData = New-Object System.Management.Automation.Runspaces.TypeData ([Rhodium.UI.UIObject])
        $typeData.TypeAdapter = [Rhodium.UI.UIObjectAdapter]
        $typeEntry = New-Object System.Management.Automation.Runspaces.SessionStateTypeEntry $typeData, $false
        $iss.Types.Add($typeEntry)

        $runspace = [RunSpaceFactory]::CreateRunspace($iss)
        $runspace.ApartmentState = "STA"
        $runspace.ThreadOptions = "ReuseThread"
        $runspace.Open()

        foreach ($varName in $ImportVariables)
        {
            $var = $PSCmdlet.SessionState.PSVariable.Get($varName)
            $runspace.SessionStateProxy.SetVariable($var.Name, $var.Value)
        }

        $powershell = [PowerShell]::Create()
        $powershell.Runspace = $runspace

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

# ======================================================================================================================
# Manual Functions
# ======================================================================================================================

Function Show-UIWindow
{
    Param
    (
        [Parameter(Position=0)] [object] $Content,
        [Parameter()] [string] $Title,
        [Parameter()] [double] $Width,
        [Parameter()] [double] $MinWidth,
        [Parameter()] [double] $MaxWidth,
        [Parameter()] [double] $Height,
        [Parameter()] [double] $MinHeight,
        [Parameter()] [double] $MaxHeight,
        [Parameter()] [object] $DataContext,
        [Parameter()] [hashtable] $AlsoSet,
        [Parameter()] [hashtable] $AddEvents
    )
    $control = New-Object System.Windows.Window
    if ($Title) { $control.Title = $Title }
    [System.Windows.Controls.Grid]::SetIsSharedSizeScope($control, $true)
    foreach ($event in $AddEvents.Keys)
    {
        $Content."Add_$event"($AddEvents[$event])
    }
    Set-UIKnownProperty $control $PSBoundParameters | Out-Null
    [void]$control.Dispatcher.InvokeAsync({ [void]$control.ShowDialog() }).Wait()
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
        [Parameter()] [hashtable] $AlsoSet,
        [Parameter()] [object] $DataContext,
        [Parameter()] [object] $Tag
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
        [Parameter()] [switch] $BareTemplate
    )
    $script = $CustomScript
    if (!$CustomScript) { $script = 'Set-UIKnownProperty $control $PSBoundParameters' }

    $Script:Function = [pscustomobject][ordered]@{
        ObjectName = $ObjectName
        ObjectType = $ObjectType
        ParamBlock = $ParamBlock
        Script = $script
        BareTemplate = $BareTemplate.IsPresent
    }
    $Script:FunctionList.Add($Script:Function)
}

# -------------------------------------------------------
# Containers
# -------------------------------------------------------

New-UIFunction Border ([System.Windows.Controls.Border]) {
    [Parameter(Position=0)] [object] $Child,
    [Parameter()] [System.Windows.Media.Brush] $BorderBrush,
    [Parameter()] [double[]] $BorderThickness,
    [Parameter()] [double[]] $BorderRadius
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
} -CustomScript {
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
    [Parameter(Position=0)] [string] $Header,
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
    [Parameter()] [int[]] $Rows,
    [Parameter()] [int[]] $Columns
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

New-UIFunction Label ([System.Windows.Controls.Label]) {
    [Parameter(Position=0)] [object] $Content
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
        foreach ($column in $Columns)
        {
            $gridViewColumn = New-Object System.Windows.Controls.GridViewColumn
            $gridViewColumn.Header = $column
            $gridViewColumn.DisplayMemberBinding = New-Object System.Windows.Data.Binding $column
            $view.Columns.Add($gridViewColumn)
        }
        $control.View = $view
        [void]$PSBoundParameters.Remove('Columns')
    }
    Set-UIKnownProperty $control $PSBoundParameters
}

New-UIFunction PasswordBox ([System.Windows.Controls.PasswordBox]) {
    
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
    [Parameter()] [string] $BindTextTo
}

New-UIFunction TextBox ([System.Windows.Controls.TextBox]) {
    [Parameter()] [double] $FontSize,
    [Parameter()] [object] $FontWeight,
    [Parameter()] [object] $FontStyle,
    [Parameter()] [object] $FontFamily,
    [Parameter()] [string] $BindTextTo,
    [Parameter()] [System.Windows.Controls.ScrollBarVisibility] $VerticalScrollBarVisibility
}

New-UIFunction RotateTransform ([System.Windows.Media.RotateTransform]) -BareTemplate {
    [Parameter()] [double] $Angle
}

New-UIFunction ScaleTransform ([System.Windows.Media.ScaleTransform]) -BareTemplate {
    [Parameter()] [double] $Scale
} -CustomScript {
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

    New-Item -Path "Function:\New-UI$($function.ObjectName)" -Value ([ScriptBlock]::Create($functionText))
}