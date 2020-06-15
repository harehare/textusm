module Page.New exposing (view)

import Asset exposing (Asset)
import Data.DiagramType as DiagramType
import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (class, href, src, style)
import Route
import TextUSM.Enum.Diagram exposing (Diagram(..))


type alias NewItem =
    { name : String
    , image : Asset
    , url : String
    }


newItems : List NewItem
newItems =
    [ NewItem "User Story Map" Asset.userStoryMap (Route.toString <| Route.Edit <| DiagramType.toString UserStoryMap)
    , NewItem "Mind Map" Asset.mindMap (Route.toString <| Route.Edit <| DiagramType.toString MindMap)
    , NewItem "Impact Map" Asset.impactMap (Route.toString <| Route.Edit <| DiagramType.toString ImpactMap)
    , NewItem "Empathy Map" Asset.empathyMap (Route.toString <| Route.Edit <| DiagramType.toString EmpathyMap)
    , NewItem "Site Map" Asset.siteMap (Route.toString <| Route.Edit <| DiagramType.toString SiteMap)
    , NewItem "Business Model Canvas" Asset.businessModelCanvas (Route.toString <| Route.Edit <| DiagramType.toString BusinessModelCanvas)
    , NewItem "Opportunity Canvas" Asset.opportunityCanvas (Route.toString <| Route.Edit <| DiagramType.toString OpportunityCanvas)
    , NewItem "User Persona" Asset.userPersona (Route.toString <| Route.Edit <| DiagramType.toString UserPersona)
    , NewItem "Markdown" Asset.markdown (Route.toString <| Route.Edit <| DiagramType.toString Markdown)
    , NewItem "Gantt Chart" Asset.ganttChart (Route.toString <| Route.Edit <| DiagramType.toString GanttChart)
    , NewItem "ER Diagram" Asset.erDiagram (Route.toString <| Route.Edit <| DiagramType.toString ErDiagram)
    , NewItem "Kanban" Asset.kanban (Route.toString <| Route.Edit <| DiagramType.toString Kanban)
    , NewItem "4Ls" Asset.fourLs (Route.toString <| Route.Edit <| DiagramType.toString Fourls)
    , NewItem "Start, Stop, Continue" Asset.startStopContinue (Route.toString <| Route.Edit <| DiagramType.toString StartStopContinue)
    , NewItem "KPT" Asset.kpt (Route.toString <| Route.Edit <| DiagramType.toString Kpt)
    , NewItem "Table" Asset.table (Route.toString <| Route.Edit <| DiagramType.toString Table)
    ]


view : Html msg
view =
    div
        [ class "diagram-list"
        , style "margin" "16px"
        , style "display" "flex"
        , style "flex-wrap" "wrap"
        , style "overflow-y" "scroll"
        ]
    <|
        List.map
            (\item ->
                a [ href item.url, class "new-item-container" ]
                    [ div [ class "new-item" ]
                        [ img [ Asset.src item.image, class "new-item-image" ] []
                        , div
                            [ class "new-item-text"
                            ]
                            [ text item.name ]
                        ]
                    ]
            )
            newItems
