module View.Book exposing (main)

import Diagram.BusinessModelCanvas.View as BusinessModelCanvas
import Diagram.ER.View as ER
import Diagram.EmpathyMap.View as EmpathyMap
import Diagram.FourLs.View as FourLs
import Diagram.FreeForm.View as FreeForm
import Diagram.GanttChart.View as GanttChart
import Diagram.Kanban.View as Kanban
import Diagram.KeyboardLayout.View as KeyboardLayout
import Diagram.Kpt.View as Kpt
import Diagram.MindMap.View as MindMap
import Diagram.OpportunityCanvas.View as OpportunityCanvas
import Diagram.Search.View as Search
import Diagram.SequenceDiagram.View as SequenceDiagram
import Diagram.SiteMap.View as SiteMap
import Diagram.StartStopContinue.View as StartStopContinue
import Diagram.Table.View as Table
import Diagram.UseCaseDiagram.View as UseCaseDiagram
import Diagram.UserPersona.View as UserPersona
import Diagram.UserStoryMap.View as UserStoryMap
import Diagram.View.Card as Card
import Diagram.View.ContextMenu as ContextMenu
import Diagram.View.Path as Path
import Diagram.View.Toolbar as Toolbar
import ElmBook exposing (Book)
import ElmBook.ComponentOptions
import View.DropDownList as DropDownList
import View.Footer as Footer
import View.Header as Header
import View.Loading as Loading
import View.Logo as Logo
import View.Menu as Menu
import View.Notification as Notification
import View.Progress as Progress
import View.Snackbar as Snackbar
import View.Spinner as Spinner
import View.SplitWindow as SplitWindow
import View.Switch as Switch
import View.SwitchWindow as SwitchWindow
import View.Tooltip as Tooltip


main : Book ()
main =
    ElmBook.book "View"
        |> ElmBook.withComponentOptions
            [ ElmBook.ComponentOptions.background "#273037"
            , ElmBook.ComponentOptions.fullWidth True
            , ElmBook.ComponentOptions.displayBlock
            ]
        |> ElmBook.withChapterGroups
            [ ( "View"
              , [ Tooltip.docs
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
              )
            , ( "Diagram"
              , [ BusinessModelCanvas.docs
                , Kpt.docs
                , OpportunityCanvas.docs
                , StartStopContinue.docs
                , EmpathyMap.docs
                , UserPersona.docs
                , FreeForm.docs
                , UserStoryMap.docs
                , MindMap.docs
                , SiteMap.docs
                , GanttChart.docs
                , Kanban.docs
                , ER.docs
                , Table.docs
                , SequenceDiagram.docs
                , Search.docs
                , Path.docs
                , Card.docs
                , ContextMenu.docs
                , UseCaseDiagram.docs
                , Toolbar.docs
                , FourLs.docs
                , KeyboardLayout.docs
                ]
              )
            ]
