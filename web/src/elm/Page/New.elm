module Page.New exposing (view)

import Asset exposing (Asset)
import Attributes
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
import Html.Styled exposing (Html, a, div, img, text)
import Html.Styled.Attributes exposing (attribute, class, css, href)
import Models.DiagramType as DiagramType exposing (DiagramType(..))
import Route
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


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
                    a [ href item.url, attribute "aria-label" <| DiagramType.toLongString item.type_ ]
                        [ div
                            [ class "new-item"
                            , newItemStyle
                            , Attributes.dataTest <| "new-" ++ DiagramType.toString item.type_
                            ]
                            [ img [ Asset.src item.image, css [ property "object-fit" "contain", Style.widthFull, height <| px 100 ] ] []
                            , div
                                [ css [ Text.sm, Font.fontSemiBold ]
                                ]
                                [ text <| DiagramType.toLongString item.type_ ]
                            ]
                        ]
                )
                newItems
        ]


type alias NewItem =
    { type_ : DiagramType
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
    [ NewItem DiagramType.UserStoryMap Asset.userStoryMap (Route.toString <| Route.Edit UserStoryMap)
    , NewItem DiagramType.MindMap Asset.mindMap (Route.toString <| Route.Edit MindMap)
    , NewItem DiagramType.ImpactMap Asset.impactMap (Route.toString <| Route.Edit ImpactMap)
    , NewItem DiagramType.EmpathyMap Asset.empathyMap (Route.toString <| Route.Edit EmpathyMap)
    , NewItem DiagramType.SiteMap Asset.siteMap (Route.toString <| Route.Edit SiteMap)
    , NewItem DiagramType.BusinessModelCanvas Asset.businessModelCanvas (Route.toString <| Route.Edit BusinessModelCanvas)
    , NewItem DiagramType.OpportunityCanvas Asset.opportunityCanvas (Route.toString <| Route.Edit OpportunityCanvas)
    , NewItem DiagramType.UserPersona Asset.userPersona (Route.toString <| Route.Edit UserPersona)
    , NewItem DiagramType.GanttChart Asset.ganttChart (Route.toString <| Route.Edit GanttChart)
    , NewItem DiagramType.ErDiagram Asset.erDiagram (Route.toString <| Route.Edit ErDiagram)
    , NewItem DiagramType.SequenceDiagram Asset.sequenceDiagram (Route.toString <| Route.Edit SequenceDiagram)
    , NewItem DiagramType.UseCaseDiagram Asset.useCaseDiagram (Route.toString <| Route.Edit UseCaseDiagram)
    , NewItem DiagramType.Kanban Asset.kanban (Route.toString <| Route.Edit Kanban)
    , NewItem DiagramType.Fourls Asset.fourLs (Route.toString <| Route.Edit Fourls)
    , NewItem DiagramType.StartStopContinue Asset.startStopContinue (Route.toString <| Route.Edit StartStopContinue)
    , NewItem DiagramType.Kpt Asset.kpt (Route.toString <| Route.Edit Kpt)
    , NewItem DiagramType.Table Asset.table (Route.toString <| Route.Edit Table)
    , NewItem DiagramType.Freeform Asset.freeform (Route.toString <| Route.Edit Freeform)
    ]
