module Views.Book exposing (main)

import ElmBook exposing (Book)
import ElmBook.ComponentOptions
import Views.DropDownList as DropDownList
import Views.Footer as Footer
import Views.Header as Header
import Views.Loading as Loading
import Views.Logo as Logo
import Views.Menu as Menu
import Views.Notification as Notification
import Views.Progress as Progress
import Views.Snackbar as Snackbar
import Views.Spinner as Spinner
import Views.SplitWindow as SplitWindow
import Views.Switch as Switch
import Views.SwitchWindow as SwitchWindow
import Views.Tooltip as Tooltip


main : Book ()
main =
    ElmBook.book "Views"
        |> ElmBook.withComponentOptions
            [ ElmBook.ComponentOptions.background "#273037"
            , ElmBook.ComponentOptions.hiddenLabel True
            , ElmBook.ComponentOptions.fullWidth True
            , ElmBook.ComponentOptions.displayBlock
            ]
        |> ElmBook.withChapters
            [ Tooltip.docs
            , Notification.docs
            , Progress.docs
            , Snackbar.docs
            , Footer.docs
            , Loading.docs
            , Spinner.docs
            , Logo.docs
            , Header.docs
            , Menu.docs
            , DropDownList.docs
            , SwitchWindow.docs
            , SplitWindow.docs
            , Switch.docs
            ]
