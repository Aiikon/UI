# UI

A user interface module built around WPF and reusable code for a clean, common sense, XAML-like layout script.

## How to use it
Write the UI layout like you would XAML:
```powershell
Show-UIWindow -Width 400 -Height 200 -Content {
    New-UIButton "Click Me" -Margin 4 -AddClick {
        "Clicked" | Show-UIMessageBox
    }
}
```

Or for a more complex example:
```powershell
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
```

The module expects you to use data binding to set/retrieve most values and provides a New-UIObject cmdlet to create objects that implement INotifyPropertyChanged to create responsive interfaces. For example, the progress bar, slider and textbox in this example are all bound to a common value. Note the DataContext set on Show-UIWindow and the -Bind\*To parameters:
```powershell
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
```

The cmdlets will use the same names and structure as XAML as often as possible. Check the Tests.ps1 file for more layout examples.
