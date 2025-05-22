Import-Module C:\PSModule\UI -Force


Show-UIWindow -Title "Row, Col, RowSpan and ColSpan Tests" -Width 500 -Height 300 {
    New-UIGrid -RowDef auto, *, 50 -ColDef auto, *, 200 {
        New-UIButton "Row 0, Col 0" -Margin 2
        New-UIButton "Row 0, Col 1" -Margin 2 -GridCol 1
        New-UIButton "Row 1, Col 0" -Margin 2 -GridRow 1
        New-UIButton "Row 1, Col 1" -Margin 2 -GridRow 1 -GridCol 1
        New-UIButton "Row 0+1, Col 2" -Margin 2 -GridRow 0 -GridCol 2 -GridRowSpan 2
        New-UIButton "Row 2, Col 1+2" -Margin 2 -GridRow 2 -GridCol 1 -GridColSpan 2
    }
}


Show-UIWindow -Title "Find-UIParent Close Window Test" -Width 800 -Height 400 {
    New-UIButton -Content "Close Window" -Margin 4 -AddClick {
        Find-UIParent -Type Window | ForEach-Object Close
    }
}


Show-UIWindow -Title "Alignment Tests and Demonstration, UniformGrid" -Width 800 -Height 600 {
    New-UIGrid {
        New-UIUniformGrid {
            foreach ($align in [enum]::GetNames([Rhodium.UI.Align]))
            {
                New-UIButton $align -Margin 4 -Padding 6,2,6,2 -Align $align
            }
        }
        New-UIGrid -RowDef *,*,*,* -ColDef *,*,*,* -AlsoSet @{ShowGridLines=$true}
    }
}


Show-UIWindow -Title "ListView Tests" -Width 600 -Height 300 {
    New-UIListView -ItemsSource (Get-Service | Select Name, Status, DisplayName) -Columns Name, Status, DisplayName `
        -SelectionMode Single
}


Show-UIWindow -Title "DataGrid Tests" -Width 600 -Height 300 {
    New-UIDataGrid -ItemsSource (Get-Service | Select Name, Status, DisplayName)
}


Show-UIWindow -Title "Button Content Tests" -Width 400 -Height 200 {
    New-UIButton -Margin 4 {
        New-UIStackPanel {
            New-UITextBlock "Sample Button" -FontWeight Bold
            New-UIButton "Test 2" -Margin 4
        }
    }
}


Show-UIWindow -Width 300 -Height 600 -Title "TextBlock Tests" {
    New-UIStackPanel -Margin 4 {
        New-UITextBlock "Simple Text"
        New-UITextBlock "Bold Text" -FontWeight Bold
        New-UITextBlock "Italic Text" -FontStyle Italic
        New-UITextBlock "Console Text" -FontFamily Consolas
        New-UITextBlock "Bigger Text" -FontSize 20
        New-UITextBlock -BindTextTo "Sample" -DataContext ([pscustomobject]@{Sample='Data Bound Text'})
    }
}


$PbeMaster = New-UIObject
$PbeMaster.CurrentProgress = 25
Show-UIWindow -Width 600 -Height 300 -Title "Progress Binding Example" -DataContext $PbeMaster {
    New-UIStackPanel {
        New-UIProgressBar -Margin 4 -Minimum 0 -Maximum 100 -BindValueTo CurrentProgress -Height 20
        New-UISlider -Margin 4 -Minimum 0 -Maximum 100 -BindValueTo CurrentProgress -Orientation Horizontal -Foreground Black -TickPlacement BottomRight
        New-UIStackPanel -Orientation Horizontal -Margin 4 {
            New-UITextBlock "Value:"
            New-UITextBox -Width 50 -BindTextTo CurrentProgress -Margin 4,0,0,0
        }
    }
}


$MenuTestMaster = New-UIObject
$MenuTestMaster.LeftToRight = $true
$MenuTestMaster.RightToLeft = $false
$MenuTestMaster.Custom = "Test..."
Show-UIWindow -Title "Menu Tests" -Width 500 -Height 200 -DataContext $MenuTestMaster {
    New-UIGrid -RowDef auto, * {
        New-UIMenu {
            New-UIMenuItem _File {
                New-UIMenuItem E_xit -AddClick { Find-UIParent -Type Window | ForEach-Object Close }
            }
            New-UIMenuItem _View {
                New-UIMenuItem _Layout {
                    New-UIMenuItem "_Left to Right" -IsCheckable $true -BindIsCheckedTo LeftToRight
                    New-UIMenuItem "_Right to Left" -IsCheckable $true -BindIsCheckedTo RightToLeft
                }
                New-UIMenuItem _Other
            }
        }
        New-UIButton "Main Content Here" -Margin 4 -GridRow 1
    }
}


$RadioTestMaster = New-UIObject
$RadioTestMaster.OneA = $true
$RadioTestMaster.OneB = $false
$RadioTestMaster.TwoX = $false
$RadioTestMaster.TwoY = $true
$RadioTestMaster.TwoZ = $false
$RadioTestMaster.Three1 = $true
$RadioTestMaster.Three2 = $false

# FYI: Radio Buttons need merely be in different parent containers (i.e. New-UIStackPanel) to be separate
# groups, the GroupBox is merely stylistic
Show-UIWindow -Title "Radio/Check Button Tests" -SizeToContent WidthAndHeight -DataContext $RadioTestMaster {
    New-UIStackPanel {
        New-UIGroupBox "Radio Button Group One" -Margin 4 {
            New-UIStackPanel -Orientation Horizontal {
                New-UIRadioButton "A" -BindIsCheckedTo OneA -Margin 4
                New-UIRadioButton "B" -BindIsCheckedTo OneB -Margin 4
            }
        }
        New-UIGroupBox "Radio Button Group Two" -Margin 4 {
            New-UIStackPanel -Orientation Horizontal {
                New-UIRadioButton "X" -BindIsCheckedTo TwoX -Margin 4
                New-UIRadioButton "Y" -BindIsCheckedTo TwoY -Margin 4
                New-UIRadioButton "Z" -BindIsCheckedTo TwoZ -Margin 4
            }
        }
        New-UIGroupBox "Check Box Group Three" -Margin 4 {
            New-UIStackPanel -Orientation Horizontal {
                New-UICheckBox "1" -BindIsCheckedTo Three1 -Margin 4
                New-UICheckBox "2" -BindIsCheckedTo Three2 -Margin 4
            }
        }
    }
}


$sharedContextMenu = New-UIContextMenu {
    New-UIMenuItem "Click Me" -AddClick {
        Show-UIMessageBox $this.DataContext
    }
}
Show-UIWindow -Title "Context Menu Samples" -Width 300 -Height 200 {
    New-UIGrid -ColDef *, * -RowDef *, * {
        New-UIButton -GridColSpan 2 "Right-Click Me" -Margin 4 -ContextMenu {
            New-UIContextMenu {
                New-UIMenuItem "Choice 1 (Click This)" -AddClick { "You Clicked Choice 1" | Show-UIMessageBox }
                New-UIMenuItem "Choice 2"
                New-UIMenuItem "Other" {
                    New-UIMenuItem "Other A"
                    New-UIMenuItem "Other B"
                }
            }
        }
        New-UIButton -GridRow 1 -GridCol 0 "Left-Click Me 1" -Margin 4,0,4,4 -AddClick {
            $sharedContextMenu.DataContext = "Button 1"
            $sharedContextMenu.IsOpen = $true
        }
        New-UIButton -GridRow 1 -GridCol 1 "Left-Click Me 2" -Margin 0,0,4,4 -AddClick {
            $sharedContextMenu.DataContext = "Button 2"
            $sharedContextMenu.IsOpen = $true
        }
    }
}


# Interactive GUI Example
$PingUI = New-UIObject
$PingUI.ServerList = 'localhost'
$PingUI.Enabled = $true
$PingUI.ResultList = New-UIObjectCollection

$PingUI.Scripts = @{}
$PingUI.Scripts.PingServers = {

    if ([String]::IsNullOrWhiteSpace($PingUI.ServerList))
    {
        Show-UIMessageBox "Enter one or more server names first."
        return
    }
    
    $window = Find-UIParent -Type Window
    $PingUI.Enabled = $false
    $PingUI.ResultList.Clear()

    Invoke-UIPowerShell -SetVariables (Get-Variable PingUI, window) -ScriptBlock {
        trap { $_ | Out-File C:\Users\Justin\Desktop\Errors.txt }
        $serverList = $PingUI.ServerList -split "`r`n" | ForEach-Object Trim | Where-Object { $_ }

        foreach ($server in $serverList)
        {
            $newResult = New-UIObject
            $newResult.ComputerName = $server
            $newResult.IsOnline = Test-Connection -ComputerName $server -Count 1 -Quiet
            $PingUI.ResultList.AddWithDispatcher($newResult, $window.Dispatcher)
        }

        $PingUI.Enabled = $true
    }
}

Show-UIWindow -Title "Server Ping GUI" -Width 600 -Height 500 -DataContext $PingUI {
    New-UIDockPanel {
        New-UIDockPanel -Dock Left {
            New-UITextBlock "Enter Server Names:" -Dock Top -Margin 4,4,4,0
            New-UIButton "Ping Servers" -Padding 4,2,4,2 -Dock Bottom -Margin 4,0,4,4 -AddClick $PingUI.Scripts.PingServers
            New-UITextBox -Margin 4 -Width 150 -AcceptsReturn $true -BindTextTo ServerList
        } |
            Add-UIBinding -Property IsEnabled -Path Enabled

        New-UIListView -Columns ComputerName, IsOnline -BindItemsSourceTo ResultList -Margin 0,4,4,4
    }
}



# Service GUI Example
$ServiceMaster = New-UIObject
$ServiceMaster.ServiceList = Get-Service | Select-Object Name, DisplayName, Status, StartType | New-UIObjectCollection

Show-UIWindow -Width 900 -Height 500 -Title "Service Manager" -DataContext $ServiceMaster {
    New-UITabControl -Margin 4 {
        New-UITabItem "Items Control (Templated)" {
            New-UIScrollViewer {
                New-UIItemsControl -BindItemsSourceTo ServiceList -ItemTemplate {
                    New-UIStackPanel -Margin 2,2,2,12 {
                        New-UIStackPanel -Margin 2 -Orientation Horizontal {
                            New-UITextBlock -FontWeight Bold -Text "Service Name: "
                            New-UITextBlock -BindTextTo Name
                        }
                        New-UIStackPanel -Margin 2 -Orientation Horizontal {
                            New-UITextBlock -FontWeight Bold -Text "Start Type: "
                            New-UIComboBox -ItemsSource ([Enum]::GetValues([System.ServiceProcess.ServiceStartMode])) -BindSelectedValueTo StartType -Width 100
                        }
                    }
                }
            }
        }
        New-UITabItem "List View (Templated)" {
            New-UIListView -Margin 4 -BindItemsSourceTo ServiceList -Columns {
                New-UIGridViewColumn "Service Name" {
                    New-UIStackPanel -Orientation Horizontal {
                        New-UITextBlock -BindTextTo Name
                        New-UITextBlock " ("
                        New-UITextBlock -BindTextTo DisplayName
                        New-UITextBlock ")"
                    }
                }
                New-UIGridViewColumn -Header "Start Mode" {
                    New-UIComboBox -ItemsSource ([Enum]::GetValues([System.ServiceProcess.ServiceStartMode])) -BindSelectedValueTo StartType -Width 100
                }
                New-UIGridViewColumn -Header "Status" {
                    New-UITextBlock -BindTextTo Status
                }
                New-UIGridViewColumn -Header "Actions" {
                    New-UIStackPanel -Orientation Horizontal {
                        New-UIButton -Margin 2,0,2,0 -Padding 4,1,4,1 "Start" -AddClick { $this.DataContext | Start-Service -Verbose }
                        New-UIButton -Margin 2,0,2,0 -Padding 4,1,4,1 "Stop" -AddClick { $this.DataContext | Stop-Service -Verbose }
                    }
                }
            }
        }
        New-UITabItem "List View (Simple)" {
            New-UIListView -Margin 4 -BindItemsSourceTo ServiceList -Columns 'Name', 'Status'
        }
    }
}


# Indicator Sample
Show-UIWindow -SizeToContent Width -Title "Contents of Windows Directory" {

    Function New-UIIndicator($Label, $Color, $Text, $Scale = 16, $Nudge = -0.8)
    {
        New-UIGrid -Margin 1 {
            New-UIEllipse -Fill $Color -Width $scale -Height $scale
            New-UIEllipse -Width ($scale*.85) -Height ($scale*.85) -StrokeThickness ($scale*.06) -Stroke White
            New-UITextBlock -Text $Text -Align Center -Margin 0,$Nudge,0,0 -FontSize ($scale*.6) -Foreground White -TextAlignment Center
        } |
            Add-UIBinding -Property Visibility -Path "${Label}Vis" -FallbackValue Collapsed -Converter BoolToVisibility
    }

    $itemList = Get-ChildItem C:\Windows |
        ForEach-Object {
            $result = $_ | Select-Object Name, LastWriteTime, Length, DirectoryVis, FileVis, ArchiveVis, SystemVis, ReadOnlyVis
            $result.DirectoryVis = $_.Attributes -match "directory"
            $result.FileVis = $_.Attributes -notmatch "directory"
            $result.ArchiveVis = $_.Attributes -match "archive"
            $result.SystemVis = $_.Attributes -match "system"
            $result.ReadOnlyVis = $_.Attributes -match "readonly"
            $result
        }

    New-UIListView -Margin 4 -ItemsSource $itemList -Columns {
        New-UIGridViewColumn -Header "Attr" -CellTemplate {
            New-UIStackPanel -Orientation Horizontal {
                New-UIIndicator Directory Blue "D"
                New-UIIndicator File Purple "F"
                New-UIIndicator Archive DarkCyan "A"
                New-UIIndicator System Red "S"
                New-UIIndicator ReadOnly Orange "R"
            }
        }
        New-UIGridViewColumn -Header "Name" -CellTemplate { New-UITextBlock -BindTextTo Name }
        New-UIGridViewColumn -Header "Last Modified" -CellTemplate { New-UITextBlock -BindTextTo LastWriteTime }
        New-UIGridViewColumn -Header "Size" -Width 100 -CellTemplate { New-UITextBlock -BindTextTo Length }
    }
}


# Style Sample
Show-UIWindow -Width 500 -Height 400 -Title "Style Sample" {
    $textStyle = New-UIStyle {
        New-UITrigger Text "CSC" {
            New-UISetter Foreground Red
        }
        New-UIDataTrigger Attributes Directory {
            New-UISetter FontStyle Italic
        }
    }
    New-UIDockPanel {
        New-UITextBlock -Dock Top -Text "Style Sample" -Margin 4 -Style {
            New-UISetter -Property FontSize -Value 18
        }
        New-UIListView -ItemsSource (Get-ChildItem C:\Windows) -Margin 4 -Columns {
            New-UIGridViewColumn -Header Name -CellTemplate {
                New-UITextBlock -BindTextTo Name -Style $textStyle
            }
            New-UIGridViewColumn -Header Attributes -CellTemplate {
                New-UITextBlock -BindTextTo Attributes -Style $textStyle
            }
        }
    }
}


# Brush Sample
Show-UIWindow -Width 500 -Height 300 -Title "Brush Sample" {
    New-UIUniformGrid {
        $simpleStops = (0, 'Red'),
            (0.5, 'Green'),
            (1, 'Blue')
        $otherStops = (0.2,255,154,56),
            (0.8,100,168,212,179)
        New-UIRectangle -Margin 5 (New-UISolidColorBrush -RGB 150, 110, 20)
        New-UIRectangle -Margin 5 (New-UILinearGradientBrush -StartPoint 0,0 -EndPoint 1,1 -GradientStops $simpleStops)
        New-UIGrid -Margin 5 {
            New-UIViewbox -Margin 5 {
                New-UITextBlock -Align Center "Some Background Text"
            }
            New-UIRectangle (New-UISolidColorBrush -ARGB 150,255,0,0)
        }
        New-UIGrid -Margin 5 {
            New-UIViewbox -Margin 5 {
                New-UITextBlock -Align Center "Some Background Text"
            }
            New-UIRectangle (New-UILinearGradientBrush -StartPoint 0,0 -EndPoint 1,0 -GradientStops $otherStops)
        }
    }
}


# Service Control Sample
$ServiceUI = New-UIObject
$ServiceUI.ServiceList = New-UIObjectCollection

Show-UIWindow -SizeToContent Width -Height 500 -DataContext $ServiceUI {
    New-UIListView -BindItemsSourceTo ServiceList -Columns {
        New-UIGridViewColumn Name DisplayName
        New-UIGridViewColumn State {
            New-UIStackPanel -Orientation Horizontal {
                New-UIEllipse -Margin 2,2,6,2 -Style {
                    New-UISetter Fill Orange
                    New-UIDataTrigger Status 'Running' { New-UISetter Fill Green }
                    New-UIDataTrigger Status 'Stopped' { New-UISetter Fill Red }
                } |
                    Add-UIBinding Width ActualHeight -RelativeSource Self
                New-UITextBlock -BindTextTo Status
            }
        }
        New-UIGridViewColumn "Start Mode" StartType
        New-UIGridViewColumn "Actions" {
            New-UIStackPanel -Orientation Horizontal {
                New-UIButton -Padding 6,0,6,0 -Margin 2,0,2,0 Start -AddClick { Start-Service -Name $this.DataContext.Name }
                New-UIButton -Padding 6,0,6,0 -Margin 0,0,2,0 Stop -AddClick { Stop-Service -Name $this.DataContext.Name -NoWait }
            }
        }
    }
} -AddLoaded {
    
    $serviceList = Get-Service
    $serviceDict = [ordered]@{}
    foreach ($service in $serviceList)
    {
        $serviceDict[$service.Name] = $service | Select-Object DisplayName, Name, Status, StartType | New-UIObject
    }
    $ServiceUI.ServiceList = $serviceDict.Values | New-UIObjectCollection
    $ServiceUI.Thread = Invoke-UIPowerShell -SetVariables (Get-Variable serviceDict) -ScriptBlock {      
        while ($true)
        {
            foreach ($service in (Get-Service))
            {
                $uiService = $serviceDict[$service.Name]
                if ($uiService.Status -ne $service.Status)
                {
                    $uiService.Status = $service.Status
                }
            }
        }
    }
} -AddClosing {
    $ServiceUI.Thread.Runspace.Dispose()
}

# Locked UI with StatusBar Sample
$LockedUI = New-UIObject
$LockedUI.InterfaceEnabled = $true
$LockedUI.StatusText = ''
$LockedUI.ProgressValue = 0

Show-UIWindow -Width 400 -Height 300 -Title "Locked UI with Status Bar" -DataContext $LockedUI {
    New-UIDockPanel {
        New-UIStatusBar -Dock Bottom {
            New-UIStatusBarItem -Dock Right {
                New-UIProgressBar -Width 100 -Height 14 -Maximum 100 -BindValueTo ProgressValue
            }
            New-UISeparator -Dock Right
            New-UIStatusBarItem -Dock Right {
                New-UITextBlock -BindTextTo StatusText -TextAlignment Right
            }
            New-UISeparator -Dock Right

            New-UIStatusBarItem # Fill empty space
        }
        New-UIDockPanel {
            New-UIButton -Margin 4 "Start Operation" -AddClick {
                $LockedUI.Thread = Invoke-UIPowerShell -SetVariables (Get-Variable LockedUI) -ScriptBlock {
                    $LockedUI.InterfaceEnabled = $false
                    $LockedUI.StatusText = 'Operation running...'
                    1..100 | ForEach-Object {
                        Start-Sleep -Milliseconds 50
                        $LockedUI.ProgressValue = $_
                    }
                    $LockedUI.StatusText = 'Operation completed'
                    $LockedUI.InterfaceEnabled = $true
                }
            }
        } | Add-UIBinding IsEnabled InterfaceEnabled
    }
} -AddClosing {
    if ($ServiceUI.Thread)
    {
        $ServiceUI.Thread.Runspace.Dispose()
    }
}

