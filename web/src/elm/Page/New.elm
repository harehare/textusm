module Page.New exposing (view)

import Data.DiagramType as DiagramType
import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (class, href, src, style)
import Route
import TextUSM.Enum.Diagram exposing (Diagram(..))


type alias NewItem =
    { name : String
    , imagePath : String
    , url : String
    }


newItems : List NewItem
newItems =
    [ NewItem "User Story Map" "/images/diagram/usm.svg" (Route.toString <| Route.Edit <| DiagramType.toString UserStoryMap)
    , NewItem "Mind Map" "/images/diagram/mmp.svg" (Route.toString <| Route.Edit <| DiagramType.toString MindMap)
    , NewItem "Impact Map" "/images/diagram/imm.svg" (Route.toString <| Route.Edit <| DiagramType.toString ImpactMap)
    , NewItem "Empathy Map" "/images/diagram/emm.svg" (Route.toString <| Route.Edit <| DiagramType.toString EmpathyMap)
    , NewItem "Site Map" "/images/diagram/smp.svg" (Route.toString <| Route.Edit <| DiagramType.toString SiteMap)
    , NewItem "Business Model Canvas" "/images/diagram/bmc.svg" (Route.toString <| Route.Edit <| DiagramType.toString BusinessModelCanvas)
    , NewItem "Opportunity Canvas" "/images/diagram/opc.svg" (Route.toString <| Route.Edit <| DiagramType.toString OpportunityCanvas)
    , NewItem "User Persona" "/images/diagram/persona.svg" (Route.toString <| Route.Edit <| DiagramType.toString UserPersona)
    , NewItem "Markdown" "/images/diagram/md.svg" (Route.toString <| Route.Edit <| DiagramType.toString Markdown)
    , NewItem "Gantt Chart" "/images/diagram/gct.svg" (Route.toString <| Route.Edit <| DiagramType.toString GanttChart)
    , NewItem "ER Diagram" "/images/diagram/erd.svg" (Route.toString <| Route.Edit <| DiagramType.toString ErDiagram)
    , NewItem "Kanban" "/images/diagram/kanban.svg" (Route.toString <| Route.Edit <| DiagramType.toString Kanban)
    , NewItem "4Ls" "/images/diagram/4ls.svg" (Route.toString <| Route.Edit <| DiagramType.toString Fourls)
    , NewItem "Start, Stop, Continue" "/images/diagram/ssc.svg" (Route.toString <| Route.Edit <| DiagramType.toString StartStopContinue)
    , NewItem "KPT" "/images/diagram/kpt.svg" (Route.toString <| Route.Edit <| DiagramType.toString Kpt)
    , NewItem "Table" "/images/diagram/table.svg" (Route.toString <| Route.Edit <| DiagramType.toString Table)
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
        (List.map
            (\item ->
                a [ href item.url, class "new-item-container" ]
                    [ div [ class "new-item" ]
                        [ img [ src item.imagePath, class "new-item-image" ] []
                        , div
                            [ class "new-item-text"
                            ]
                            [ text item.name ]
                        ]
                    ]
            )
            newItems
        )
