module Views.Diagram.UseCaseDiagram exposing (view)

import Data.FontSize as FontSize exposing (FontSize)
import Data.Item as Item exposing (Item)
import Data.Position as Position exposing (Position)
import Dict exposing (Dict)
import Html
import Html.Attributes as Attr
import Html.Lazy as Lazy
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
import State as State exposing (Step(..))
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Views.Empty as Empty


actorBaseSize : Int
actorBaseSize =
    20


actorHalfSize : Int
actorHalfSize =
    actorBaseSize // 2


actorSize2 : Int
actorSize2 =
    actorBaseSize * 2


actorSize3 : Int
actorSize3 =
    actorBaseSize * 3


actorSize4 : Int
actorSize4 =
    actorBaseSize * 4


actorSize6 : Int
actorSize6 =
    actorBaseSize * 6


actorHeight : Int
actorHeight =
    actorBaseSize * 7


actorMargin : Int
actorMargin =
    actorBaseSize * 12


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

                ( actorMargins, actorViews ) =
                    actorsView model.settings actors

                ( useCasePositions, useCaseViews ) =
                    useCasesView
                        { settings = model.settings
                        , basePosition = ( useCaseSize, 0 )
                        , baseHierarchy = 1
                        , relation = relation
                        , useCases = useCases
                        }

                actorLine =
                    List.map
                        (\(Actor a ul) ->
                            let
                                maybeActorPosition =
                                    Dict.get (UseCaseDiagram.getName a) actorMargins

                                useCaseCount =
                                    List.length ul // 2

                                lines =
                                    List.indexedMap
                                        (\i (UseCase u) ->
                                            let
                                                maybeUseCasePosition =
                                                    Dict.get (UseCaseDiagram.getName u) useCasePositions
                                            in
                                            case ( maybeActorPosition, maybeUseCasePosition ) of
                                                ( Just ap, Just up ) ->
                                                    let
                                                        fromPosition =
                                                            Tuple.mapBoth
                                                                (\x -> x + actorSize3)
                                                                (\y -> y + (actorHeight // 2 + (i - useCaseCount) * actorHalfSize))
                                                                ap

                                                        toPosition =
                                                            Tuple.mapBoth
                                                                (\x -> x + actorBaseSize)
                                                                (\y -> y + actorBaseSize)
                                                                up
                                                    in
                                                    useCaseLineView { settings = model.settings, from = fromPosition, to = toPosition }

                                                _ ->
                                                    Svg.g [] []
                                        )
                                        ul
                            in
                            lines
                        )
                        actors
                        |> List.concat
            in
            Svg.g [] <|
                arrowView model.settings
                    :: (actorLine ++ actorViews ++ useCaseViews)

        _ ->
            Empty.view


actorsView : Settings -> List Actor -> ( UseCasePosition, List (Svg Msg) )
actorsView settings actors =
    let
        a =
            List.indexedMap
                (\i (Actor item _) ->
                    let
                        p =
                            ( actorSize2, actorMargin * i )
                    in
                    ( ( UseCaseDiagram.getName item, p )
                    , Lazy.lazy4 actorView
                        settings
                        (Item.getFontSize item)
                        (UseCaseDiagram.getName item)
                        p
                    )
                )
                actors
    in
    ( Dict.fromList <| List.map Tuple.first a, List.map Tuple.second a )


useCasePosition : { hierarchy : Int, relationCount : Int, nextPosition : Position } -> Position
useCasePosition { hierarchy, relationCount, nextPosition } =
    ( useCaseSize * 7 * hierarchy
    , Position.getY nextPosition + (useCaseSize + actorSize2) * relationCount
    )


useCasesView :
    { settings : Settings
    , basePosition : Position
    , baseHierarchy : Int
    , relation : UseCaseRelation
    , useCases : List Item
    }
    -> ( UseCasePosition, List (Svg Msg) )
useCasesView { settings, basePosition, baseHierarchy, relation, useCases } =
    let
        loop { hierarchy, nextPosition, index, result, head, tail } =
            let
                name =
                    UseCaseDiagram.getName head

                relationCount =
                    max (UseCaseDiagram.relationCount head relation) 1

                position =
                    useCasePosition
                        { hierarchy = hierarchy
                        , relationCount = max (relationCount // 2) 1
                        , nextPosition = nextPosition
                        }

                newPosition =
                    useCasePosition
                        { hierarchy = hierarchy
                        , relationCount = relationCount
                        , nextPosition = nextPosition
                        }

                relationUseCases =
                    case UseCaseDiagram.getRelations head relation of
                        Just relationItems ->
                            List.indexedMap
                                (\i relationItem ->
                                    let
                                        relationName =
                                            UseCaseDiagram.getRelationName relationItem

                                        ri =
                                            UseCaseDiagram.getRelationItem relationItem

                                        subPosition =
                                            useCasePosition
                                                { hierarchy = hierarchy + 1
                                                , relationCount = (i + 1) - max (relationCount // 2) 1
                                                , nextPosition = position
                                                }

                                        subRelations =
                                            UseCaseDiagram.getRelations ri relation
                                                |> Maybe.withDefault []

                                        ( subPositions, subUseCases ) =
                                            useCasesView
                                                { settings = settings
                                                , basePosition =
                                                    useCasePosition
                                                        { hierarchy = hierarchy + 1
                                                        , relationCount =
                                                            max
                                                                (UseCaseDiagram.relationCount
                                                                    (UseCaseDiagram.getRelationItem relationItem)
                                                                    relation
                                                                )
                                                                1
                                                        , nextPosition = nextPosition
                                                        }
                                                , baseHierarchy = hierarchy + 2
                                                , relation = relation
                                                , useCases = subRelations |> List.map UseCaseDiagram.getRelationItem
                                                }

                                        subLines =
                                            List.map
                                                (\v ->
                                                    relationLineView
                                                        { settings = settings
                                                        , from = subPosition
                                                        , to =
                                                            Dict.get (UseCaseDiagram.getRelationName v) subPositions
                                                                |> Maybe.withDefault Position.zero
                                                        , relation = v
                                                        }
                                                )
                                                subRelations
                                    in
                                    ( ( relationName, subPosition )
                                    , subLines
                                        ++ subUseCases
                                        ++ [ Lazy.lazy relationLineView
                                                { settings = settings
                                                , from = position
                                                , to = subPosition
                                                , relation = relationItem
                                                }
                                           , Lazy.lazy useCaseView
                                                { settings = settings
                                                , color = settings.color.task
                                                , fontSize = FontSize.default
                                                , name = relationName
                                                , position = subPosition
                                                }
                                           ]
                                    )
                                )
                                relationItems

                        Nothing ->
                            []

                r =
                    relationUseCases
                        ++ [ ( ( name, position )
                             , [ Lazy.lazy useCaseView
                                    { settings = settings
                                    , color = settings.color.activity
                                    , fontSize = FontSize.default
                                    , name = name
                                    , position = position
                                    }
                               ]
                             )
                           ]
            in
            Loop
                { nextPosition = newPosition
                , hierarchy = hierarchy
                , index = index + 1
                , result = result ++ r
                , restUseCases = tail
                }

        go { nextPosition, hierarchy, index, result, restUseCases } =
            case restUseCases of
                x :: [] ->
                    loop
                        { nextPosition = nextPosition
                        , hierarchy = hierarchy
                        , index = index
                        , result = result
                        , head = x
                        , tail = []
                        }

                x :: xs ->
                    loop
                        { nextPosition = nextPosition
                        , hierarchy = hierarchy
                        , index = index
                        , result = result
                        , head = x
                        , tail = xs
                        }

                _ ->
                    Done result

        a =
            State.tailRec go
                { nextPosition = basePosition
                , hierarchy = baseHierarchy
                , index = 0
                , result = []
                , restUseCases = useCases
                }
    in
    ( a |> List.map Tuple.first |> Dict.fromList
    , a |> List.map Tuple.second |> List.concat
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


relationLineView : { settings : Settings, from : Position, to : Position, relation : Relation } -> Svg Msg
relationLineView { settings, from, to, relation } =
    let
        ( fromX, fromY ) =
            ( Position.getX from + useCaseSize, Position.getY from + useCaseSize // 2 + actorHalfSize )

        ( toX, toY ) =
            ( Position.getX to - 2, Position.getY to + useCaseSize // 2 + actorHalfSize )

        ( centerX, centerY ) =
            ( fromX + (toX - fromX) // 5 * 3, fromY + (toY - fromY) // 5 * 3 - actorHalfSize )
    in
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
            [ SvgAttr.x <| String.fromInt <| centerX - useCaseSize
            , SvgAttr.y <| String.fromInt <| centerY - useCaseSize
            , SvgAttr.fill "transparent"
            , SvgAttr.width "1"
            , SvgAttr.height "1"
            , SvgAttr.style "overflow: visible"
            ]
            [ Html.div
                [ Attr.style "padding" "32px"
                , Attr.style "font-family" <| Diagram.fontStyle settings
                , Attr.style "background-color" "transparent"
                ]
                [ Html.div
                    [ Attr.style "color" <| Diagram.getTextColor settings.color
                    , FontSize.htmlFontSize FontSize.xs
                    ]
                    [ Html.text <| "<<" ++ relationToString relation ++ ">>" ]
                ]
            ]
        ]


useCaseLineView : { settings : Settings, from : Position, to : Position } -> Svg Msg
useCaseLineView { settings, from, to } =
    Svg.line
        [ SvgAttr.x1 <| String.fromInt <| Position.getX from
        , SvgAttr.y1 <| String.fromInt <| Position.getY from
        , SvgAttr.x2 <| String.fromInt <| Position.getX to
        , SvgAttr.y2 <| String.fromInt <| Position.getY to + actorBaseSize
        , SvgAttr.stroke settings.color.line
        , SvgAttr.strokeWidth "1"
        ]
        []


useCaseView : { settings : Settings, color : Diagram.Color, fontSize : FontSize, name : String, position : Position } -> Svg Msg
useCaseView { settings, color, fontSize, name, position } =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX position
        , SvgAttr.y <| String.fromInt <| Position.getY position
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
            , Attr.style "min-width" "150px"
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
    Svg.g []
        [ Svg.circle
            [ SvgAttr.cx <| String.fromInt (x + actorBaseSize)
            , SvgAttr.cy <| String.fromInt (y + actorBaseSize)
            , SvgAttr.r "15"
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

        -- body
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorBaseSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize2 - 6)
            , SvgAttr.x2 <| String.fromInt (x + actorBaseSize)
            , SvgAttr.y2 <| String.fromInt (y + actorSize4)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

        -- arm
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x - actorBaseSize + actorHalfSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize2 + actorHalfSize)
            , SvgAttr.x2 <| String.fromInt (x + actorSize3 - actorHalfSize)
            , SvgAttr.y2 <| String.fromInt (y + actorSize2 + actorHalfSize)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

        -- leg
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorBaseSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize4)
            , SvgAttr.x2 <| String.fromInt x
            , SvgAttr.y2 <| String.fromInt (y + actorSize6)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

        -- leg
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt (x + actorBaseSize)
            , SvgAttr.y1 <| String.fromInt (y + actorSize4)
            , SvgAttr.x2 <| String.fromInt (x + actorSize2)
            , SvgAttr.y2 <| String.fromInt (y + actorSize6)
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x <| String.fromInt <| x - actorSize3
            , SvgAttr.y <| String.fromInt (y + actorHeight)
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
