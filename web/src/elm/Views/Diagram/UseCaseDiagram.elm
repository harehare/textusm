module Views.Diagram.UseCaseDiagram exposing (view)

import Data.FontSize as FontSize
import Data.Position exposing (Position)
import Html
import Html.Attributes as Attr
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Views.UseCaseDiagram exposing (UseCase(..), UseCaseDiagram(..), UseCaseItem(..))
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Views.Empty as Empty


actorSize : Int
actorSize =
    20


actorPosition : Int
actorPosition =
    actorSize * 9


useCaseSize : Int
useCaseSize =
    40


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.UseCaseDiagram (UseCaseDiagram u) ->
            Svg.g [] <|
                List.indexedMap
                    (\i item ->
                        case item of
                            Actor name names ->
                                actorView model.settings name ( actorSize, actorSize + actorPosition * i )

                            UseCaseItem useCases ->
                                Svg.g [] <|
                                    List.indexedMap
                                        (\j useCase ->
                                            case useCase of
                                                UseCase name ->
                                                    useCaseView model.settings name ( useCaseSize * 5, (useCaseSize * 3) * j )

                                                Extend name useCaseName ->
                                                    Svg.g [] []

                                                Include name useCaseName ->
                                                    Svg.g [] []
                                        )
                                        useCases
                    )
                    u

        _ ->
            Empty.view


useCaseView : Settings -> String -> Position -> Svg Msg
useCaseView settings name ( x, y ) =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt x
        , SvgAttr.y <| String.fromInt y
        , SvgAttr.width "250"
        , SvgAttr.height "100"
        ]
        [ Html.div
            [ Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , Attr.style "justify-content" "center"
            , Attr.style "padding" "8px"
            , Attr.style "font-family" <| Diagram.fontStyle settings
            , Attr.style "word-wrap" "break-word"
            , Attr.style "border-radius" "50%"
            , Attr.style "border-radius" "50%"
            , Attr.style "width" "100%"
            , Attr.style "height" "100%"
            , Attr.style "background-color" settings.color.activity.backgroundColor
            ]
            [ Html.div
                [ Attr.style "color" settings.color.activity.color
                ]
                [ Html.text name ]
            ]
        ]


actorView : Settings -> String -> Position -> Svg Msg
actorView settings name ( x, y ) =
    let
        actirHalfSize =
            actorSize // 2
    in
    Svg.g []
        [ Svg.circle
            [ SvgAttr.cx <| String.fromInt (x + actorSize)
            , SvgAttr.cy <| String.fromInt (y + actorSize)
            , SvgAttr.r "15"
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "2"
            ]
            []

        -- body
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 2 - 6)
            , SvgAttr.x2 <| String.fromInt (x + actorSize)
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 4)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "2"
            ]
            []

        -- arm
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x - actorSize + 10)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 2 + actirHalfSize)
            , SvgAttr.x2 <| String.fromInt (x + actorSize * 3 - actirHalfSize)
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 2 + actirHalfSize)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "2"
            ]
            []

        -- leg
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 4)
            , SvgAttr.x2 <| String.fromInt x
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 6)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "2"
            ]
            []

        -- leg
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 4)
            , SvgAttr.x2 <| String.fromInt (x + actorSize * 2)
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 6)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "2"
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x <| String.fromInt x
            , SvgAttr.y <| String.fromInt (y + actorSize * 7)
            , SvgAttr.width <| String.fromInt <| actorSize * 2
            , SvgAttr.height <| String.fromInt <| actorSize
            ]
            [ Html.div
                [ Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "padding" "8px"
                , Attr.style "font-family" <| Diagram.fontStyle settings
                , Attr.style "word-wrap" "break-word"
                , Attr.style "width" "100%"
                , Attr.style "height" "100%"
                , Attr.style "text-align" "center"
                ]
                [ Html.div
                    [ Attr.style "color" <| Diagram.getTextColor settings.color
                    ]
                    [ Html.text name ]
                ]
            ]
        ]
