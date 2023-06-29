module Views.Diagram.UseCaseDiagram exposing (docs, view)

import Css exposing (backgroundColor, color, hex, padding4, px, transparent, zero)
import Dict exposing (Dict)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Events
import Html.Styled as Html
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Lazy as Lazy
import List.Extra as ListEx
import Models.Color as Color
import Models.Diagram exposing (SelectedItemInfo)
import Models.Diagram.Data as DiagramData
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType
import Models.Diagram.UseCaseDiagram as UseCaseDiagram
    exposing
        ( Actor(..)
        , Relation
        , UseCase(..)
        , UseCaseDiagram(..)
        , UseCaseRelation
        )
import Models.FontSize as FontSize exposing (FontSize)
import Models.Item as Item exposing (Item)
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Set exposing (Set)
import State exposing (Step(..))
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Empty as Empty


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , property : Property
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
view { data, settings, property, onSelect } =
    case data of
        DiagramData.UseCaseDiagram (UseCaseDiagram actors relation) ->
            let
                actorLine : List (Svg msg)
                actorLine =
                    List.concatMap
                        (\(Actor a ul) ->
                            let
                                maybeActorPosition : Maybe Position
                                maybeActorPosition =
                                    Dict.get (UseCaseDiagram.getName a) actorMargins

                                useCaseCount : Int
                                useCaseCount =
                                    List.length ul // 2
                            in
                            List.indexedMap
                                (\i (UseCase u) ->
                                    let
                                        maybeUseCasePosition : Maybe Position
                                        maybeUseCasePosition =
                                            Dict.get (UseCaseDiagram.getName u) useCasePositions
                                    in
                                    case ( maybeActorPosition, maybeUseCasePosition ) of
                                        ( Just ap, Just up ) ->
                                            let
                                                fromPosition : Position
                                                fromPosition =
                                                    Tuple.mapBoth
                                                        (\x -> x + actorSize3)
                                                        (\y -> y + (actorHeight // 2 + (i - useCaseCount) * actorHalfSize))
                                                        ap

                                                toPosition : Position
                                                toPosition =
                                                    Tuple.mapBoth
                                                        (\x -> x + actorBaseSize)
                                                        (\y -> y + actorBaseSize)
                                                        up
                                            in
                                            useCaseLineView { settings = settings, from = fromPosition, to = toPosition }

                                        _ ->
                                            Svg.g [] []
                                )
                                ul
                        )
                        actors

                ( actorMargins, actorViews ) =
                    actorsView settings property actors

                ( useCasePositions, useCaseViews ) =
                    useCasesView
                        { settings = settings
                        , basePosition = ( 0, -50 )
                        , baseHierarchy = 1
                        , relation = relation
                        , useCases = useCases
                        , allUseCaseName = useCases |> List.map (\v -> Item.getText v |> String.trim) |> Set.fromList
                        , property = property
                        , onSelect = onSelect
                        }

                useCases : List Item
                useCases =
                    List.concatMap (\(Actor _ a) -> List.map (\(UseCase u) -> u) a) actors
                        |> ListEx.uniqueBy Item.getText
            in
            Svg.g [] <|
                arrowView settings
                    :: (actorLine ++ actorViews ++ useCaseViews)

        _ ->
            Empty.view


actorBaseSize : Int
actorBaseSize =
    20


actorHalfSize : Int
actorHalfSize =
    actorBaseSize // 2


actorHeight : Int
actorHeight =
    actorBaseSize * 7


actorMargin : Int
actorMargin =
    actorBaseSize * 12


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


actorView : DiagramSettings.Settings -> Property -> FontSize -> String -> Position -> Svg msg
actorView settings property fontSize name ( x, y ) =
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
                , Attr.style "font-family" <| DiagramSettings.fontStyle settings
                , Attr.style "word-wrap" "break-word"
                , Attr.style "width" "160px"
                , Attr.style "height" "100%"
                , Attr.style "text-align" "center"
                ]
                [ Html.div
                    [ Attr.style "color" <| Color.toString <| DiagramSettings.getTextColor settings property
                    , Attr.style "padding" "8px"
                    , Attr.style "font-size" <| String.fromInt (FontSize.unwrap fontSize) ++ "px"
                    ]
                    [ Html.text name ]
                ]
            ]
        ]


actorsView : DiagramSettings.Settings -> Property -> List Actor -> ( UseCasePosition, List (Svg msg) )
actorsView settings property actors =
    let
        a : List ( ( String, ( Int, Int ) ), Svg msg )
        a =
            List.indexedMap
                (\i (Actor item _) ->
                    let
                        p : Position
                        p =
                            ( actorSize2, actorMargin * i )
                    in
                    ( ( UseCaseDiagram.getName item, p )
                    , Lazy.lazy5 actorView
                        settings
                        property
                        (Item.getFontSizeWithProperty item property)
                        (UseCaseDiagram.getName item)
                        p
                    )
                )
                actors
    in
    ( Dict.fromList <| List.map Tuple.first a, List.map Tuple.second a )


adjustmentLinePosition : Position -> Int -> Position
adjustmentLinePosition position index =
    Tuple.mapBoth (\x -> x - index * 5) (\y -> y + index * 4) position


arrowView : DiagramSettings.Settings -> Svg msg
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


relationLineView : { settings : DiagramSettings.Settings, property : Property, from : Position, to : Position, relation : Relation, reverse : Bool } -> Svg msg
relationLineView { settings, property, from, to, relation, reverse } =
    let
        ( centerX, centerY ) =
            ( fromX + (toX - fromX) // 5 * 3, fromY + (toY - fromY) // 5 * 3 - actorHalfSize )

        diffY : Int
        diffY =
            toY - fromY

        ( fromX, fromY ) =
            ( Position.getX from
                + (if reverse then
                    useCaseSize * 4 - actorBaseSize - 10

                   else
                    useCaseSize * 3 - actorBaseSize
                  )
            , Position.getY from + useCaseSize // 2 + actorHalfSize
            )

        ( toX, toY ) =
            ( Position.getX to - 2
            , Position.getY to + useCaseSize // 2 + actorHalfSize
            )
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
            , if reverse then
                SvgAttr.markerStart "url(#arrow)"

              else
                SvgAttr.markerEnd "url(#arrow)"
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
                [ css
                    [ if diffY < 10 then
                        padding4 (px 32) zero zero zero

                      else
                        padding4 (px 28) zero zero (px 24)
                    , DiagramSettings.fontFamiliy settings
                    , backgroundColor transparent
                    ]
                ]
                [ Html.div
                    [ css
                        [ color <| hex <| Color.toString <| DiagramSettings.getTextColor settings property
                        , FontSize.cssFontSize FontSize.xs
                        ]
                    ]
                    [ Html.text <| "<<" ++ relationToString relation ++ ">>" ]
                ]
            ]
        ]


relationToString : Relation -> String
relationToString r =
    case r of
        UseCaseDiagram.Extend _ ->
            "extend"

        UseCaseDiagram.Include _ ->
            "include"


useCaseLineView : { settings : DiagramSettings.Settings, from : Position, to : Position } -> Svg msg
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


type alias UseCasePosition =
    Dict String Position


useCasePosition : { hierarchy : Int, relationCount : Int, nextPosition : Position } -> Position
useCasePosition { hierarchy, relationCount, nextPosition } =
    ( useCaseSize * 8 * hierarchy
    , Position.getY nextPosition + (useCaseSize + actorSize2) * relationCount
    )


useCaseSize : Int
useCaseSize =
    40


useCaseView :
    { settings : DiagramSettings.Settings
    , item : Item
    , fontSize : FontSize
    , name : String
    , position : Position
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
useCaseView { settings, item, fontSize, name, position, onSelect } =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX position
        , SvgAttr.y <| String.fromInt <| Position.getY position
        , SvgAttr.fill "transparent"
        , SvgAttr.width "130"
        , SvgAttr.height "1"
        , SvgAttr.style "overflow: visible"
        , Events.onClickStopPropagation <|
            onSelect <|
                Just { item = item, position = ( Position.getX position, Position.getY position + 60 ), displayAllMenu = True }
        ]
        [ Html.div
            [ Attr.style "display" "block"
            , Attr.style "padding" "16px 24px"
            , Attr.style "font-family" <| DiagramSettings.fontStyle settings
            , Attr.style "word-wrap" "break-word"
            , Attr.style "border-radius" "50%"
            , Attr.style "max-height" "100px"
            , Attr.style "background-color" <| Color.toString <| Maybe.withDefault Color.background2Defalut <| Item.getBackgroundColor item
            , Attr.style "color" <| Color.toString <| Maybe.withDefault Color.white <| Item.getForegroundColor item
            , Attr.style "line-height" "1.1rem"
            , Attr.style "font-size" <| String.fromInt (FontSize.unwrap fontSize) ++ "px"
            ]
            [ Html.text <| String.trim <| name ]
        ]


useCasesView :
    { settings : DiagramSettings.Settings
    , basePosition : Position
    , baseHierarchy : Int
    , relation : UseCaseRelation
    , useCases : List Item
    , allUseCaseName : Set String
    , property : Property
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> ( UseCasePosition, List (Svg msg) )
useCasesView { settings, basePosition, baseHierarchy, relation, useCases, allUseCaseName, property, onSelect } =
    let
        a : List ( ( String, Position ), List (Svg msg) )
        a =
            State.tailRec go
                { nextPosition = basePosition
                , hierarchy = baseHierarchy
                , index = 0
                , result = []
                , restUseCases = useCases
                }

        go :
            { a
                | nextPosition : Position
                , hierarchy : Int
                , index : Int
                , result : List ( ( String, Position ), List (Svg msg) )
                , restUseCases : List Item
            }
            ->
                Step
                    { nextPosition : Position
                    , hierarchy : Int
                    , index : Int
                    , result : List ( ( String, Position ), List (Svg msg) )
                    , restUseCases : List Item
                    }
                    (List ( ( String, Position ), List (Svg msg) ))
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

        loop :
            { a
                | hierarchy : Int
                , nextPosition : Position
                , index : Int
                , result : List ( ( String, Position ), List (Svg msg) )
                , head : Item
                , tail : f
            }
            ->
                Step
                    { nextPosition : Position
                    , hierarchy : Int
                    , index : Int
                    , result : List ( ( String, Position ), List (Svg msg) )
                    , restUseCases : f
                    }
                    b
        loop { hierarchy, nextPosition, index, result, head, tail } =
            let
                name : String
                name =
                    UseCaseDiagram.getName head

                newPosition : Position
                newPosition =
                    useCasePosition
                        { hierarchy = hierarchy
                        , relationCount = relationCount
                        , nextPosition = nextPosition
                        }

                position : Position
                position =
                    useCasePosition
                        { hierarchy = hierarchy
                        , relationCount = max (relationCount // 2) 1
                        , nextPosition = nextPosition
                        }

                r : List ( ( String, Position ), List (Svg msg) )
                r =
                    relationUseCases
                        ++ [ ( ( name, position )
                             , [ Lazy.lazy useCaseView
                                    { settings = settings
                                    , item = head
                                    , fontSize = FontSize.default
                                    , name = name
                                    , position = position
                                    , onSelect = onSelect
                                    }
                               ]
                             )
                           ]

                relationCount : Int
                relationCount =
                    max (UseCaseDiagram.relationCount head relation) 1

                relationUseCases : List ( ( String, Position ), List (Svg msg) )
                relationUseCases =
                    case UseCaseDiagram.getRelations head relation of
                        Just relationItems ->
                            List.indexedMap
                                (\i relationItem ->
                                    let
                                        relationName : String
                                        relationName =
                                            UseCaseDiagram.getRelationName relationItem

                                        ri : Item
                                        ri =
                                            UseCaseDiagram.getRelationItem relationItem

                                        subLines : List (Svg msg)
                                        subLines =
                                            List.indexedMap
                                                (\j v ->
                                                    relationLineView
                                                        { settings = settings
                                                        , from = adjustmentLinePosition subPosition j
                                                        , to =
                                                            Dict.get (UseCaseDiagram.getRelationName v) subPositions
                                                                |> Maybe.withDefault Position.zero
                                                        , relation = v
                                                        , reverse = not <| Set.member relationName allUseCaseName
                                                        , property = property
                                                        }
                                                )
                                                subRelations

                                        subPosition : Position
                                        subPosition =
                                            useCasePosition
                                                { hierarchy = hierarchy + 1
                                                , relationCount = (i + 1) - max (relationCount // 2) 1
                                                , nextPosition = position
                                                }

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
                                                , allUseCaseName = allUseCaseName
                                                , property = property
                                                , onSelect = onSelect
                                                }

                                        subRelations : List Relation
                                        subRelations =
                                            UseCaseDiagram.getRelations ri relation
                                                |> Maybe.withDefault []
                                    in
                                    ( ( relationName, subPosition )
                                    , subLines
                                        ++ subUseCases
                                        ++ [ Lazy.lazy relationLineView
                                                { settings = settings
                                                , from = adjustmentLinePosition position i
                                                , to = subPosition
                                                , relation = relationItem
                                                , reverse = not <| Set.member name allUseCaseName
                                                , property = property
                                                }
                                           , Lazy.lazy useCaseView
                                                { settings = settings
                                                , item = UseCaseDiagram.getRelationItem relationItem
                                                , fontSize = FontSize.default
                                                , name = relationName
                                                , position = subPosition
                                                , onSelect = onSelect
                                                }
                                           ]
                                    )
                                )
                                relationItems

                        Nothing ->
                            []
            in
            Loop
                { nextPosition = newPosition
                , hierarchy = hierarchy
                , index = index + 1
                , result = result ++ r
                , restUseCases = tail
                }
    in
    ( a |> List.map Tuple.first |> Dict.fromList
    , a |> List.concatMap Tuple.second
    )


docs : Chapter x
docs =
    Chapter.chapter "UseCaseDiagram"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.UseCaseDiagram <|
                            UseCaseDiagram.from <|
                                (DiagramType.defaultText DiagramType.UseCaseDiagram |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    , property = Property.empty
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    }
                ]
                |> Svg.toUnstyled
            )
