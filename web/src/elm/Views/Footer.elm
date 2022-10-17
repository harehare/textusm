module Views.Footer exposing (view)

import Css
    exposing
        ( alignItems
        , center
        , cursor
        , displayFlex
        , flexEnd
        , height
        , justifyContent
        , padding
        , pointer
        , position
        , relative
        , rem
        )
import Env
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Models.Color as Color
import Models.DiagramType as DiagramType exposing (DiagramType)
import Style.Color as ColorStyle
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Views.Icon as Icon


type alias Props msg =
    { diagramType : DiagramType
    , onChangeDiagramType : DiagramType -> msg
    }


view : Props msg -> Html msg
view props =
    Html.div
        [ Attr.css
            [ height <| rem 2
            , ColorStyle.bgMain
            , Style.widthScreen
            , position relative
            , Style.shadowSm
            , displayFlex
            , alignItems center
            , justifyContent flexEnd
            , Style.borderTop05
            , ColorStyle.bgFooterColor
            ]
        ]
        [ diagramTypeSelect props
        , Html.div [ Attr.css [ padding <| rem 0.5, cursor pointer ] ]
            [ Html.a
                [ Attr.href Env.repoUrl
                , Attr.target "_blank"
                , Attr.rel "noopener noreferrer"
                ]
                [ Icon.github Color.darkIconColor 16 ]
            ]
        , Html.div
            [ Attr.css
                [ ColorStyle.textSecondaryColor
                , Text.xs
                , Font.fontBold
                , Style.paddingRightSm
                ]
            ]
            [ Html.text Env.appVersion ]
        ]


diagramTypeList : List DiagramType
diagramTypeList =
    [ DiagramType.UserStoryMap
    , DiagramType.MindMap
    , DiagramType.ImpactMap
    , DiagramType.EmpathyMap
    , DiagramType.SiteMap
    , DiagramType.BusinessModelCanvas
    , DiagramType.OpportunityCanvas
    , DiagramType.UserPersona
    , DiagramType.GanttChart
    , DiagramType.ErDiagram
    , DiagramType.SequenceDiagram
    , DiagramType.UseCaseDiagram
    , DiagramType.Kanban
    , DiagramType.Fourls
    , DiagramType.StartStopContinue
    , DiagramType.Kpt
    , DiagramType.Table
    , DiagramType.Freeform
    ]


diagramTypeSelect : Props msg -> Html msg
diagramTypeSelect props =
    Html.select
        [ Attr.css
            [ ColorStyle.textSecondaryColor
            , Text.xs
            , Css.fontWeight Css.bold
            ]
        , Events.onChangeStyled
            (\s -> DiagramType.fromString s |> props.onChangeDiagramType)
        ]
        (List.map
            (\d ->
                Html.option
                    [ Attr.value <| DiagramType.toString d
                    , Attr.selected <| d == props.diagramType
                    ]
                    [ Html.text <| DiagramType.toLongString d
                    ]
            )
            diagramTypeList
        )
