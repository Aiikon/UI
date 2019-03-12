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
        New-UITextBlock -BindTextTo "Sample" -DataContext ([pscustomobject]@{Sample='Data Binding Works'})
    }
}

$mbtMaster = New-UIObject
$mbtMaster.Value = [double]20
Show-UIWindow -Width 600 -Height 300 -Title "Multiple Binding Tests" -DataContext $mbtMaster {
    New-UIStackPanel {
        New-UIProgressBar -Margin 4 -Minimum 0 -Maximum 100 -BindValueTo Value -Height 20
        New-UISlider -Margin 4 -Minimum 0 -Maximum 100 -BindValueTo Value -Orientation Horizontal -Foreground Black -TickPlacement BottomRight
        New-UIStackPanel -Orientation Horizontal -Margin 4 {
            New-UITextBlock "Value:"
            New-UITextBox -Width 50 -BindTextTo Value -Margin 4,0,0,0
        }
    }
}
