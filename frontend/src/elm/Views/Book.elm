module Views.Book exposing (main)

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
import Diagram.SequenceDiagram.View as SequenceDiagram
import Diagram.SiteMap.View as SiteMap
import Diagram.StartStopContinue.View as StartStopContinue
import Diagram.Table.View as Table
import Diagram.UseCaseDiagram.View as UseCaseDiagram
import Diagram.UserPersona.View as UserPersona
import Diagram.UserStoryMap.View as UserStoryMap
import ElmBook exposing (Book)
import ElmBook.ComponentOptions
import Views.Diagram.Card as Card
import Views.Diagram.ContextMenu as ContextMenu
import Views.Diagram.Path as Path
import Views.Diagram.Search as Search
import Views.Diagram.Toolbar as Toolbar
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
            , ElmBook.ComponentOptions.fullWidth True
            , ElmBook.ComponentOptions.displayBlock
            ]
        |> ElmBook.withChapterGroups
            [ ( "Views"
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
