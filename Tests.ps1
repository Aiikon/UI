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
