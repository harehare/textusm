module Views.Book exposing (main)

import ElmBook exposing (Book)
import ElmBook.ComponentOptions
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.Card as Card
import Views.Diagram.ContextMenu as ContextMenu
import Views.Diagram.ER as ER
import Views.Diagram.EmpathyMap as EmpathyMap
import Views.Diagram.FreeForm as FreeForm
import Views.Diagram.GanttChart as GanttChart
import Views.Diagram.Kanban as Kanban
import Views.Diagram.Kpt as Kpt
import Views.Diagram.MindMap as MindMap
import Views.Diagram.OpportunityCanvas as OpportunityCanvas
import Views.Diagram.Path as Path
import Views.Diagram.Search as Search
import Views.Diagram.SequenceDiagram as SequenceDiagram
import Views.Diagram.SiteMap as SiteMap
import Views.Diagram.StartStopContinue as StartStopContinue
import Views.Diagram.Table as Table
import Views.Diagram.UserPersona as UserPersona
import Views.Diagram.UserStoryMap as UserStoryMap
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
                ]
              )
            ]
