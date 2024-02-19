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
import Diagram.Types.Type as DiagramType exposing (DiagramType(..))
import Html.Styled as Html exposing (Attribute, Html)
import Html.Styled.Attributes as Attr
import Route
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


view : Html msg
view =
    Html.div [ Attr.css [ Style.full ] ]
        [ Html.div
            [ Attr.css
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
                    Html.a [ Attr.href item.url, Attr.attribute "aria-label" <| DiagramType.toLongString item.type_ ]
                        [ Html.div
                            [ Attr.class "new-item"
                            , newItemStyle
                            , Attributes.dataTest <| "new-" ++ DiagramType.toString item.type_
                            ]
                            [ Html.img [ Asset.src item.image, Attr.css [ property "object-fit" "contain", Style.widthFull, height <| px 100 ] ] []
                            , Html.div
                                [ Attr.css [ Text.sm, Font.fontSemiBold ]
                                ]
                                [ Html.text <| DiagramType.toLongString item.type_ ]
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


newItemStyle : Attribute msg
newItemStyle =
    Attr.css
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
    [ NewItem DiagramType.UserStoryMap Asset.userStoryMap (Route.toString <| Route.Edit UserStoryMap Nothing Nothing)
    , NewItem DiagramType.MindMap Asset.mindMap (Route.toString <| Route.Edit MindMap Nothing Nothing)
    , NewItem DiagramType.ImpactMap Asset.impactMap (Route.toString <| Route.Edit ImpactMap Nothing Nothing)
    , NewItem DiagramType.EmpathyMap Asset.empathyMap (Route.toString <| Route.Edit EmpathyMap Nothing Nothing)
    , NewItem DiagramType.SiteMap Asset.siteMap (Route.toString <| Route.Edit SiteMap Nothing Nothing)
    , NewItem DiagramType.BusinessModelCanvas Asset.businessModelCanvas (Route.toString <| Route.Edit BusinessModelCanvas Nothing Nothing)
    , NewItem DiagramType.OpportunityCanvas Asset.opportunityCanvas (Route.toString <| Route.Edit OpportunityCanvas Nothing Nothing)
    , NewItem DiagramType.UserPersona Asset.userPersona (Route.toString <| Route.Edit UserPersona Nothing Nothing)
    , NewItem DiagramType.GanttChart Asset.ganttChart (Route.toString <| Route.Edit GanttChart Nothing Nothing)
    , NewItem DiagramType.ErDiagram Asset.erDiagram (Route.toString <| Route.Edit ErDiagram Nothing Nothing)
    , NewItem DiagramType.SequenceDiagram Asset.sequenceDiagram (Route.toString <| Route.Edit SequenceDiagram Nothing Nothing)
    , NewItem DiagramType.UseCaseDiagram Asset.useCaseDiagram (Route.toString <| Route.Edit UseCaseDiagram Nothing Nothing)
    , NewItem DiagramType.Kanban Asset.kanban (Route.toString <| Route.Edit Kanban Nothing Nothing)
    , NewItem DiagramType.Fourls Asset.fourLs (Route.toString <| Route.Edit Fourls Nothing Nothing)
    , NewItem DiagramType.StartStopContinue Asset.startStopContinue (Route.toString <| Route.Edit StartStopContinue Nothing Nothing)
    , NewItem DiagramType.Kpt Asset.kpt (Route.toString <| Route.Edit Kpt Nothing Nothing)
    , NewItem DiagramType.Table Asset.table (Route.toString <| Route.Edit Table Nothing Nothing)
    , NewItem DiagramType.Freeform Asset.freeform (Route.toString <| Route.Edit Freeform Nothing Nothing)
    , NewItem DiagramType.KeyboardLayout Asset.keyboardLayout (Route.toString <| Route.Edit KeyboardLayout Nothing Nothing)
    ]
