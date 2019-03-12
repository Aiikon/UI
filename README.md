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

## How to enhance it
The module comes with cmdlets and parameters for the most common UI elements and properties I use on a daily basis. Adding more is relatively straightforward.

### Adding an additional parameter
First you'll have to add the parameter to Set-UIKnownProperty.

* If it's a simple property (i.e. you just copy the value in the Parameter to the Property of the WPF control without modifying it), add it to the $simplePropertyList variable at the top of Set-UIKnownProperty.
* If it's a data binding property, i.e. Bind\<PropertyName\>To, add \<PropertyName\> to $bindPropertyList.
* If it's an event, i.e. Add\<EventName\>, add \<EventName\> to $eventPropertyList.
* If it's a more complicated property, use some of the other lines in Set-UIKnownProperty for an example, such as Margin, ContextMenu or Dock depending on the type of functionality you want to use.

Second, scroll down to the Generated Functions section and find the New-UIFunction corresponding to the type you want to add the parameter to. Add an extra Parameter definition for your new parameter (use the existing Parameter blocks as examples). To add the parameter to all New-UI\* cmdlets, add it in $Script:NewUIObjectTemplate instead.

### Adding an additional New-UI\<Control\> cmdlet
Scroll down to the Generated Function section and find a New-UIFunction definition. Duplicate it and change the name, type and parameters for your own control. Don't forget to add any additional parameters to Set-UIKnownProperty if they're not defined there yet. If your cmdlet requires some extra processing beyond setting properties, bindings and events, use the -CustomScript parameter (use ListView as an example). Don't forget to modify UI.psd1 to include the new function.
