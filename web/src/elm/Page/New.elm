module Page.New exposing (view)

import Asset exposing (Asset)
import Graphql.Enum.Diagram exposing (Diagram(..))
import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (attribute, class, href, style)
import Route


type alias NewItem =
    { name : String
    , image : Asset
    , url : String
    }


newItems : List NewItem
newItems =
    [ NewItem "User Story Map" Asset.userStoryMap (Route.toString <| Route.Edit UserStoryMap)
    , NewItem "Mind Map" Asset.mindMap (Route.toString <| Route.Edit MindMap)
    , NewItem "Impact Map" Asset.impactMap (Route.toString <| Route.Edit ImpactMap)
    , NewItem "Empathy Map" Asset.empathyMap (Route.toString <| Route.Edit EmpathyMap)
    , NewItem "Site Map" Asset.siteMap (Route.toString <| Route.Edit SiteMap)
    , NewItem "Business Model Canvas" Asset.businessModelCanvas (Route.toString <| Route.Edit BusinessModelCanvas)
    , NewItem "Opportunity Canvas" Asset.opportunityCanvas (Route.toString <| Route.Edit OpportunityCanvas)
    , NewItem "User Persona" Asset.userPersona (Route.toString <| Route.Edit UserPersona)
    , NewItem "Gantt Chart" Asset.ganttChart (Route.toString <| Route.Edit GanttChart)
    , NewItem "ER Diagram" Asset.erDiagram (Route.toString <| Route.Edit ErDiagram)
    , NewItem "Sequence Diagram" Asset.sequenceDiagram (Route.toString <| Route.Edit SequenceDiagram)
    , NewItem "Use Case Diagram" Asset.useCaseDiagram (Route.toString <| Route.Edit UseCaseDiagram)
    , NewItem "Kanban" Asset.kanban (Route.toString <| Route.Edit Kanban)
    , NewItem "4Ls" Asset.fourLs (Route.toString <| Route.Edit Fourls)
    , NewItem "Start, Stop, Continue" Asset.startStopContinue (Route.toString <| Route.Edit StartStopContinue)
    , NewItem "KPT" Asset.kpt (Route.toString <| Route.Edit Kpt)
    , NewItem "Table" Asset.table (Route.toString <| Route.Edit Table)
    , NewItem "Freeform" Asset.freeform (Route.toString <| Route.Edit Freeform)
    ]


view : Html msg
view =
    div
        [ class "grid new"
        , style "margin" "16px"
        ]
    <|
        List.map
            (\item ->
                a [ href item.url, attribute "aria-label" item.name ]
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
