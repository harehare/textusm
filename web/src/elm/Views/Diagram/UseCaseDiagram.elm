module Views.Diagram.UseCaseDiagram exposing (view)

import Data.FontSize as FontSize exposing (FontSize)
import Data.Position exposing (Position)
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Views.UseCaseDiagram exposing (UseCaseDiagram(..), UseCaseItem(..))
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Views.Empty as Empty


actorSize : Int
actorSize =
    20


actorPosition : Int
actorPosition =
    actorSize * 9


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

                            _ ->
                                Svg.g [] []
                    )
                    u

        _ ->
            Empty.view


useCaseView : Settings -> String -> Position -> Svg Msg
useCaseView settings name ( x, y ) =
    Svg.g [] []


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
            , SvgAttr.r "20"
            , SvgAttr.stroke settings.color.line
            ]
            []

        -- body
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 2)
            , SvgAttr.x2 <| String.fromInt (x + actorSize)
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 4)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

        -- arm
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x - actorSize + 10)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 2 + actirHalfSize)
            , SvgAttr.x2 <| String.fromInt (x + actorSize * 3 - actirHalfSize)
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 2 + actirHalfSize)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

        -- leg
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 4)
            , SvgAttr.x2 <| String.fromInt x
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 5)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

        -- leg
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize * 4)
            , SvgAttr.x2 <| String.fromInt (x + actorSize * 2)
            , SvgAttr.y2 <| String.fromInt (y + actorSize * 5)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []
        , Svg.text_
            [ SvgAttr.x <| String.fromInt <| x - actirHalfSize
            , SvgAttr.y <| String.fromInt (y + actorSize * 6)
            , SvgAttr.fill <| Diagram.getTextColor settings.color
            , SvgAttr.fontFamily <| Diagram.fontStyle settings
            , FontSize.svgFontSize FontSize.default
            , SvgAttr.class "select-none"
            ]
            [ Svg.text name ]
        ]
