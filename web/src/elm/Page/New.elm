module Page.New exposing (view)

import Asset exposing (Asset)
import Css
    exposing
        ( border3
        , borderBox
        , boxSizing
        , column
        , cursor
        , flexDirection
        , height
        , hover
        , overflowY
        , padding
        , pointer
        , property
        , px
        , scroll
        , solid
        , transparent
        )
import Graphql.Enum.Diagram exposing (Diagram(..))
import Html.Styled exposing (Html, a, div, img, text)
import Html.Styled.Attributes exposing (attribute, class, css, href)
import Route
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


type alias NewItem =
    { name : String
    , image : Asset
    , url : String
    }


newItemStyle : Html.Styled.Attribute msg
newItemStyle =
    css
        [ Style.flexCenter
        , flexDirection column
        , cursor pointer
        , Color.bgLight
        , Color.textMain
        , Style.roundedSm
        , border3 (px 3) solid transparent
        , boxSizing borderBox
        , hover
            [ Color.textAccent ]
        ]


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
    div [ css [ Style.full ] ]
        [ div
            [ css
                [ Breakpoint.style
                    [ Style.widthScreen
                    , Style.hMobileContent
                    , Color.bgDefault
                    , overflowY scroll
                    , padding <| px 8
                    , property "display" "grid"
                    , property "grid-column-gap" "16px"
                    , property "grid-row-gap" "16px"
                    , property "grid-template-columns" "repeat(auto-fit, minmax(45%, 1fr))"
                    , property "grid-auto-rows" "120px"
                    ]
                    [ Breakpoint.small
                        [ property "grid-template-columns" "repeat(auto-fit, minmax(240px, 1fr))"
                        , property "grid-auto-rows" "150px"
                        , Style.full
                        ]
                    ]
                ]
            ]
          <|
            List.map
                (\item ->
                    a [ href item.url, attribute "aria-label" item.name ]
                        [ div
                            [ class "new-item"
                            , newItemStyle
                            ]
                            [ img [ Asset.src item.image, css [ property "object-fit" "contain", Style.widthFull, height <| px 100 ] ] []
                            , div
                                [ css [ Text.sm, Font.fontSemiBold ]
                                ]
                                [ text item.name ]
                            ]
                        ]
                )
                newItems
        ]
