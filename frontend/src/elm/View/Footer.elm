module View.Footer exposing (Props, docs, view)

import Css
    exposing
        ( alignItems
        , center
        , cursor
        , displayFlex
        , flexEnd
        , height
        , justifyContent
        , marginTop
        , padding
        , pointer
        , position
        , px
        , relative
        , rem
        )
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation exposing (Location)
import Diagram.Types.Type as DiagramType exposing (DiagramType)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Env
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Lazy as Lazy
import Style.Color as ColorStyle
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Types.Color as Color
import Types.Session as Session exposing (Session)
import View.Icon as Icon


type alias Props msg =
    { diagramType : DiagramType
    , currentDiagram : DiagramItem
    , session : Session
    , onChangeDiagramType : DiagramType -> msg
    }


view : Props msg -> Html msg
view props =
    Html.div
        [ Attr.css
            [ height <| rem 2
            , ColorStyle.bgMain
            , Style.widthFull
            , position relative
            , Style.shadowSm
            , displayFlex
            , alignItems center
            , justifyContent flexEnd
            , ColorStyle.bgFooterColor
            ]
        ]
        [ diagramTypeSelect props
        , Lazy.lazy2 viewLocationButton props.session props.currentDiagram.location
        , Html.div [ Attr.css [ padding <| rem 1, cursor pointer, marginTop <| px 6 ] ]
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
            , Css.borderStyle Css.none

            -- , Css.marginBottom <| px 0.25
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


viewLocationButton : Session -> Maybe Location -> Html msg
viewLocationButton session location =
    case ( session, location ) of
        ( Session.SignedIn _, Just DiagramLocation.Remote ) ->
            Html.div
                [ Attr.css [ Style.button ] ]
                [ Icon.cloudOn Color.iconColor 16
                ]

        ( Session.SignedIn _, Just DiagramLocation.Gist ) ->
            Html.div
                [ Attr.css [ Style.button ] ]
                [ Icon.github Color.iconColor 16
                ]

        _ ->
            Html.div
                [ Attr.css [ Style.button ] ]
                [ Icon.cloudOff Color.iconColor 16
                ]


docs : Chapter x
docs =
    Chapter.chapter "Footer"
        |> Chapter.renderComponentList
            [ ( "Footer"
              , view
                    { diagramType = DiagramType.UserStoryMap
                    , onChangeDiagramType = \_ -> Actions.logAction "onChangeDiagramType"
                    , currentDiagram = DiagramItem.empty
                    , session = Session.Guest
                    }
                    |> Html.toUnstyled
              )
            ]
