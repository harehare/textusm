module Views.Diagram.UseCaseDiagram exposing (view)

import Data.FontSize as FontSize exposing (FontSize)
import Data.Item as Item exposing (Item)
import Data.Position exposing (Position)
import Dict exposing (Dict)
import Html
import Html.Attributes as Attr
import List.Extra as ListEx
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Views.UseCaseDiagram as UseCaseDiagram
    exposing
        ( Actor(..)
        , Relation(..)
        , UseCase(..)
        , UseCaseDiagram(..)
        , UseCaseRelation
        )
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Views.Empty as Empty


actorSize : Int
actorSize =
    20


actorPosition : Int
actorPosition =
    actorSize * 12


useCaseSize : Int
useCaseSize =
    40


type alias UseCasePosition =
    Dict String Position


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.UseCaseDiagram (UseCaseDiagram actors relation) ->
            let
                useCases =
                    List.map (\(Actor _ a) -> List.map (\(UseCase u) -> u) a) actors
                        |> List.concat
                        |> ListEx.uniqueBy Item.getText

                ( actorPositions, actorViews ) =
                    actorInfo model.settings actors

                ( useCasePositions, useCaseViews ) =
                    useCaseInfo model.settings 1 relation useCases
            in
            Svg.g [] <| arrowView model.settings :: (actorViews ++ useCaseViews)

        _ ->
            Empty.view


actorInfo : Settings -> List Actor -> ( UseCasePosition, List (Svg Msg) )
actorInfo settings actors =
    let
        a =
            List.indexedMap
                (\i (Actor item _) ->
                    let
                        p =
                            ( actorSize * 2, actorPosition * i )
                    in
                    ( ( Item.getText item, p )
                    , actorView settings
                        (Item.getFontSize item)
                        (Item.getText item)
                        p
                    )
                )
                actors
    in
    ( Dict.fromList <| List.map Tuple.first a, List.map Tuple.second a )


useCasePosition : Int -> Int -> Int -> ( Int, Int )
useCasePosition hierarchy number index =
    ( useCaseSize * 4 * hierarchy
    , useCaseSize * number * 2 * index
    )


useCaseInfo : Settings -> Int -> UseCaseRelation -> List Item -> ( UseCasePosition, List (Svg Msg) )
useCaseInfo settings hierarchy relation useCases =
    let
        a =
            List.indexedMap
                (\i useCaseItem ->
                    let
                        name =
                            Item.getText useCaseItem

                        position =
                            useCasePosition hierarchy
                                (max
                                    (UseCaseDiagram.relationCount useCaseItem relation // 2)
                                    1
                                )
                                i

                        relationUseCases =
                            case UseCaseDiagram.getRelations useCaseItem relation of
                                Just relationItems ->
                                    List.indexedMap
                                        (\j relationItem ->
                                            let
                                                relationName =
                                                    UseCaseDiagram.getRelationName relationItem

                                                p =
                                                    useCasePosition (hierarchy + 1) j i
                                            in
                                            ( ( relationName, p )
                                            , [ relationLineView settings position p relationItem
                                              , useCaseView settings
                                                    settings.color.activity
                                                    FontSize.default
                                                    relationName
                                                    p
                                              ]
                                            )
                                        )
                                        relationItems

                                Nothing ->
                                    []
                                        |> Debug.log "aa"
                    in
                    ( ( name, position )
                    , [ useCaseView settings
                            settings.color.activity
                            FontSize.default
                            name
                            position
                      ]
                    )
                        :: relationUseCases
                )
                useCases
    in
    ( a |> List.concat |> List.map Tuple.first |> Dict.fromList
    , a |> List.concat |> List.map Tuple.second |> List.concat
    )


arrowView : Settings -> Svg Msg
arrowView settings =
    Svg.g []
        [ Svg.marker
            [ SvgAttr.id "arrow"
            , SvgAttr.viewBox "0 0 10 10"
            , SvgAttr.markerWidth "10"
            , SvgAttr.markerHeight "10"
            , SvgAttr.refX "5"
            , SvgAttr.refY "5"
            , SvgAttr.orient "auto-start-reverse"
            ]
            [ Svg.polygon
                [ SvgAttr.points "0,0 0,10 10,5"
                , SvgAttr.fill settings.color.line
                ]
                []
            ]
        ]


relationToString : Relation -> String
relationToString r =
    case r of
        UseCaseDiagram.Extend _ ->
            "extend"

        UseCaseDiagram.Include _ ->
            "include"


relationLineView : Settings -> Position -> Position -> Relation -> Svg Msg
relationLineView settings ( fromX, fromY ) ( toX, toY ) r =
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 <| String.fromInt <| fromX
            , SvgAttr.y1 <| String.fromInt <| fromY
            , SvgAttr.x2 <| String.fromInt <| toX
            , SvgAttr.y2 <| String.fromInt <| toY
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            , SvgAttr.strokeDasharray "15 5"
            , SvgAttr.markerEnd "url(#arrow)"
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x <| String.fromInt fromX
            , SvgAttr.y <| String.fromInt fromY
            , SvgAttr.fill "transparent"
            , SvgAttr.width "1"
            , SvgAttr.height "1"
            , SvgAttr.style "overflow: visible"
            ]
            [ Html.div
                [ Attr.style "display" "inline-block"
                , Attr.style "padding" "16px 32px"
                , Attr.style "font-family" <| Diagram.fontStyle settings
                , Attr.style "word-wrap" "break-word"
                , Attr.style "border-radius" "50%"
                , Attr.style "background-color" "transparent"
                ]
                [ Html.div
                    [ Attr.style "color" <| Diagram.getTextColor settings.color
                    , FontSize.htmlFontSize FontSize.default
                    ]
                    [ Html.text <| "<<" ++ relationToString r ++ ">>" ]
                ]
            ]
        ]


useCaseLineView : Settings -> Position -> Position -> Svg Msg
useCaseLineView settings src dest =
    Svg.g [] []


useCaseView : Settings -> Diagram.Color -> FontSize -> String -> Position -> Svg Msg
useCaseView settings color fontSize name ( x, y ) =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt x
        , SvgAttr.y <| String.fromInt y
        , SvgAttr.fill "transparent"
        , SvgAttr.width "1"
        , SvgAttr.height "1"
        , SvgAttr.style "overflow: visible"
        ]
        [ Html.div
            [ Attr.style "display" "inline-block"
            , Attr.style "padding" "16px 32px"
            , Attr.style "font-family" <| Diagram.fontStyle settings
            , Attr.style "word-wrap" "break-word"
            , Attr.style "border-radius" "50%"
            , Attr.style "max-width" "320px"
            , Attr.style "background-color" color.backgroundColor
            ]
            [ Html.div
                [ Attr.style "color" color.color
                , Attr.style "font-size" <| String.fromInt (FontSize.unwrap fontSize) ++ "px"
                ]
                [ Html.text <| String.trim <| name ]
            ]
        ]


actorView : Settings -> FontSize -> String -> Position -> Svg Msg
actorView settings fontSize name ( x, y ) =
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
            [ SvgAttr.x <| String.fromInt <| x - (actorSize * 3)
            , SvgAttr.y <| String.fromInt (y + actorSize * 7)
            , SvgAttr.fill "transparent"
            , SvgAttr.width "1"
            , SvgAttr.height "1"
            , SvgAttr.style "overflow: visible"
            ]
            [ Html.div
                [ Attr.style "display" "flex"
                , Attr.style "align-items" "center"
                , Attr.style "justify-content" "center"
                , Attr.style "padding" "8px"
                , Attr.style "font-family" <| Diagram.fontStyle settings
                , Attr.style "word-wrap" "break-word"
                , Attr.style "width" "160px"
                , Attr.style "height" "100%"
                , Attr.style "text-align" "center"
                ]
                [ Html.div
                    [ Attr.style "color" <| Diagram.getTextColor settings.color
                    , Attr.style "padding" "8px"
                    , Attr.style "font-size" <| String.fromInt (FontSize.unwrap fontSize) ++ "px"
                    ]
                    [ Html.text name ]
                ]
            ]
        ]
