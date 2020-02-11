module Components.Diagram exposing (init, update, view)

import Basics exposing (max)
import Browser.Dom as Dom
import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import List
import List.Extra exposing (getAt, scanl, unique)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import Parser
import Result exposing (andThen)
import String
import Svg exposing (Svg, defs, g, svg, text)
import Svg.Attributes exposing (class, height, id, viewBox, width)
import Svg.Events exposing (onClick)
import Svg.Lazy exposing (lazy, lazy2)
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Utils
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.CustomerJourneyMap as CustomerJourneyMap
import Views.Diagram.EmpathyMap as EmpathyMap
import Views.Diagram.FourLs as FourLs
import Views.Diagram.GanttChart as GanttChart
import Views.Diagram.ImpactMap as ImpactMap
import Views.Diagram.Kpt as Kpt
import Views.Diagram.Markdown as Markdown
import Views.Diagram.MindMap as MindMap
import Views.Diagram.OpportunityCanvas as OpportunityCanvas
import Views.Diagram.SiteMap as SiteMap
import Views.Diagram.StartStopContinue as StartStopContinue
import Views.Diagram.UserPersona as UserPersona
import Views.Diagram.UserStoryMap as UserStoryMap
import Views.Empty as Empty
import Views.Icon as Icon


init : Settings -> ( Model, Cmd Msg )
init settings =
    ( { items = []
      , hierarchy = 0
      , width = 0
      , height = 0
      , svg =
            { width = 0
            , height = 0
            , scale = 1.0
            }
      , countByHierarchy = []
      , countByTasks = []
      , moveStart = False
      , x = 0
      , y = 20
      , moveX = 0
      , moveY = 0
      , fullscreen = False
      , showZoomControl = True
      , touchDistance = Nothing
      , settings = settings
      , error = Nothing
      , diagramType = UserStoryMap
      , labels = []
      , text = Nothing
      , matchParent = False
      , windowWidth = 0
      , selectedItem = Nothing
      }
    , Cmd.none
    )


getItemType : String -> Int -> ItemType
getItemType text indent =
    if text |> String.trim |> String.startsWith "#" then
        Comments

    else
        case indent of
            0 ->
                Activities

            1 ->
                Tasks

            _ ->
                Stories (indent - 1)


loadText : Diagram -> Int -> Int -> String -> Result String ( List Int, List Item )
loadText diagramType lineNo indent input =
    let
        splited =
            case diagramType of
                MindMap ->
                    Parser.parseLinesIgnoreError indent input

                SiteMap ->
                    Parser.parseLinesIgnoreError indent input

                ImpactMap ->
                    Parser.parseLinesIgnoreError indent input

                _ ->
                    Parser.parseLines indent input
    in
    case splited of
        Ok ( x :: xs, xxs ) ->
            loadText diagramType (lineNo + 1) (indent + 1) (String.join "\n" xs)
                |> Result.andThen
                    (\( indents, items ) ->
                        loadText diagramType
                            (lineNo + List.length (x :: xs))
                            indent
                            (String.join "\n" xxs)
                            |> Result.andThen
                                (\( indents2, tailItems ) ->
                                    Ok
                                        ( indent :: indents ++ indents2
                                        , { lineNo = lineNo
                                          , text = x
                                          , itemType = getItemType x indent
                                          , children = Item.fromItems items
                                          }
                                            :: tailItems
                                            |> List.filter (\item -> item.itemType /= Comments)
                                        )
                                )
                    )

        Ok _ ->
            Ok ( [ indent ], [] )

        Err err ->
            Err err


load : Diagram -> String -> Result String ( Int, List Item )
load diagramType text =
    if String.isEmpty text then
        Ok ( 0, [] )

    else
        let
            result =
                loadText diagramType 0 0 text
        in
        case result of
            Ok ( i, loadedItems ) ->
                Ok
                    ( i
                        |> List.maximum
                        |> Maybe.map (\x -> x - 1)
                        |> Maybe.withDefault 0
                    , loadedItems
                    )

            Err e ->
                Err e


countUpToHierarchy : Int -> List Item -> List Int
countUpToHierarchy hierarchy items =
    let
        countUp : List Item -> List (List Int)
        countUp countItems =
            -- Do not count activity, task and comment items.
            [ countItems
                |> List.filter (\x -> x.itemType /= Tasks && x.itemType /= Activities)
                |> List.length
            ]
                :: (countItems
                        |> List.map
                            (\it ->
                                let
                                    results =
                                        countUp (Item.unwrapChildren it.children)
                                            |> transpose
                                in
                                if List.length results > hierarchy then
                                    List.map
                                        (\it2 ->
                                            List.maximum it2 |> Maybe.withDefault 0
                                        )
                                        results

                                else
                                    results
                                        |> List.concat
                                        |> List.filter (\x -> x /= 0)
                            )
                   )
    in
    1
        :: 1
        :: (countUp items
                |> transpose
                |> List.map
                    (\it ->
                        List.maximum it |> Maybe.withDefault 0
                    )
           )


transpose ll =
    case ll of
        [] ->
            []

        [] :: xss ->
            transpose xss

        (x :: xs) :: xss ->
            let
                heads =
                    List.filterMap List.head xss
                        |> unique

                tails =
                    List.filterMap List.tail xss
                        |> unique
            in
            (x :: heads) :: transpose (xs :: tails)


zoomControl : Bool -> Float -> Html Msg
zoomControl isFullscreen scale =
    let
        s =
            if 1.0 - scale >= 0 then
                round ((1.0 + (1.0 - scale)) * 100.0)

            else if 1.0 - scale <= 0 then
                round ((1.0 + (1.0 - scale)) * 100.0)

            else
                100
    in
    div
        [ id "zoom-control"
        , Attr.style "position" "absolute"
        , Attr.style "align-items" "center"
        , Attr.style "right" "35px"
        , Attr.style "top" "5px"
        , Attr.style "display" "flex"
        , Attr.style "width" "140px"
        , Attr.style "justify-content" "space-between"
        ]
        [ div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , onClick ZoomOut
            ]
            [ Icon.remove 24
            ]
        , div
            [ Attr.style "font-size" "0.7rem"
            , Attr.style "color" "#8C9FAE"
            , Attr.style "cursor" "pointer"
            , Attr.style "font-weight" "600"
            , class ".select-none"
            ]
            [ text (String.fromInt s ++ "%")
            ]
        , div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , onClick ZoomIn
            ]
            [ Icon.add 24
            ]
        , div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , onClick ToggleFullscreen
            ]
            [ if isFullscreen then
                Icon.fullscreenExit 24

              else
                Icon.fullscreen 24
            ]
        ]



-- View


view : Model -> Html Msg
view model =
    div
        [ Attr.id "usm-area"
        , Attr.style "position" "relative"
        , if model.moveStart then
            Attr.style "cursor" "move"

          else
            Attr.style "cursor" "auto"
        ]
        [ if model.settings.zoomControl |> Maybe.withDefault model.showZoomControl then
            lazy2 zoomControl model.fullscreen model.svg.scale

          else
            Empty.view
        , lazy svgView model
        ]


diagramView : Diagram -> Model -> Svg Msg
diagramView diagramType =
    case diagramType of
        UserStoryMap ->
            UserStoryMap.view

        BusinessModelCanvas ->
            BusinessModelCanvas.view

        OpportunityCanvas ->
            OpportunityCanvas.view

        Fourls ->
            FourLs.view

        StartStopContinue ->
            StartStopContinue.view

        Kpt ->
            Kpt.view

        UserPersona ->
            UserPersona.view

        Markdown ->
            Markdown.view

        MindMap ->
            MindMap.view

        EmpathyMap ->
            EmpathyMap.view

        CustomerJourneyMap ->
            CustomerJourneyMap.view

        SiteMap ->
            SiteMap.view

        GanttChart ->
            GanttChart.view

        ImpactMap ->
            ImpactMap.view


svgView : Model -> Svg Msg
svgView model =
    let
        svgWidth =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.width model.width)
                    * (model.svg.scale + 0.2)
                    |> round
                    |> String.fromInt

            else
                Basics.toFloat
                    model.width
                    * (model.svg.scale + 0.2)
                    |> round
                    |> String.fromInt

        svgHeight =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.height model.height)
                    * (model.svg.scale + 0.2)
                    |> round
                    |> String.fromInt

            else
                Basics.toFloat
                    model.height
                    * (model.svg.scale + 0.2)
                    |> round
                    |> String.fromInt

        mainSvg =
            lazy (diagramView model.diagramType) model
    in
    svg
        [ Attr.id "usm"
        , width
            (String.fromInt
                (if Utils.isPhone model.width || model.fullscreen then
                    model.width

                 else if model.width - 56 > 0 then
                    model.width - 56

                 else
                    0
                )
            )
        , height
            (String.fromInt <|
                if model.fullscreen then
                    model.height + 56

                else
                    model.height
            )
        , viewBox ("0 0 " ++ svgWidth ++ " " ++ svgHeight)
        , Attr.style "background-color" model.settings.backgroundColor
        , Wheel.onWheel chooseZoom
        , onDragStart (Utils.isPhone model.width)
        , if model.moveStart then
            onDragMove model.touchDistance (Utils.isPhone model.width)

          else
            Attr.style "" ""
        ]
        [ if String.isEmpty model.settings.font then
            g [] []

          else
            defs []
                [ Svg.style
                    []
                    [ text ("@import url('https://fonts.googleapis.com/css?family=" ++ model.settings.font ++ "&display=swap');") ]
                ]
        , mainSvg
        ]


onDragStart : Bool -> Svg.Attribute Msg
onDragStart isPhone =
    if isPhone then
        Touch.onStart
            (\event ->
                if List.length event.changedTouches > 1 then
                    let
                        p1 =
                            getAt 0 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )

                        p2 =
                            getAt 1 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )
                    in
                    StartPinch (Utils.calcDistance p1 p2)

                else
                    let
                        ( x, y ) =
                            touchCoordinates event
                    in
                    Start (round x) (round y)
            )

    else
        Mouse.onDown
            (\event ->
                let
                    ( x, y ) =
                        event.pagePos
                in
                Start (round x) (round y)
            )


onDragMove : Maybe Float -> Bool -> Svg.Attribute Msg
onDragMove distance isPhone =
    if isPhone then
        Touch.onMove
            (\event ->
                if List.length event.changedTouches > 1 then
                    let
                        p1 =
                            getAt 0 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )

                        p2 =
                            getAt 1 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )
                    in
                    case distance of
                        Just x ->
                            let
                                newDistance =
                                    Utils.calcDistance p1 p2
                            in
                            if newDistance / x > 1.0 then
                                PinchIn newDistance

                            else if newDistance / x < 1.0 then
                                PinchOut newDistance

                            else
                                NoOp

                        Nothing ->
                            StartPinch (Utils.calcDistance p1 p2)

                else
                    let
                        ( x, y ) =
                            touchCoordinates event
                    in
                    Move (round x) (round y)
            )

    else
        Mouse.onMove
            (\event ->
                let
                    ( x, y ) =
                        event.pagePos
                in
                Move (round x) (round y)
            )


chooseZoom : Wheel.Event -> Msg
chooseZoom wheelEvent =
    if wheelEvent.deltaY > 0 then
        ZoomOut

    else
        ZoomIn


touchCoordinates : Touch.Event -> ( Float, Float )
touchCoordinates touchEvent =
    List.head touchEvent.changedTouches
        |> Maybe.map .clientPos
        |> Maybe.withDefault ( 0, 0 )



-- Update


updateDiagram : Int -> Int -> Model -> String -> Result String Model
updateDiagram width height base text =
    load base.diagramType text
        |> Result.andThen
            (\( hierarchy, items ) ->
                let
                    labels =
                        Parser.parseComment text
                            |> List.filter
                                (\( k, _ ) ->
                                    k == "labels"
                                )
                            |> List.map Tuple.second
                            |> List.head
                            |> Maybe.andThen
                                (\v ->
                                    Just (String.split "," v)
                                )
                            |> Maybe.withDefault []

                    countByHierarchy =
                        case base.diagramType of
                            UserStoryMap ->
                                countUpToHierarchy (hierarchy - 2) items

                            MindMap ->
                                countUpToHierarchy (hierarchy - 2) items

                            _ ->
                                []

                    countByTasks =
                        scanl (\it v -> v + List.length (Item.unwrapChildren it.children)) 0 items

                    newModel =
                        { base
                            | items = items
                            , hierarchy = hierarchy
                            , countByTasks = countByTasks
                            , countByHierarchy = countByHierarchy
                        }

                    ( svgWidth, svgHeight ) =
                        Utils.getCanvasSize newModel
                in
                Ok
                    { newModel
                        | width = width
                        , height = height
                        , svg =
                            { width = svgWidth
                            , height = svgHeight
                            , scale = base.svg.scale
                            }
                        , moveX = 0
                        , moveY = 0
                        , error = Nothing
                        , labels = labels
                        , text =
                            if String.isEmpty text then
                                Nothing

                            else
                                Just text
                    }
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NoOp ->
            ( model, Cmd.none )

        Init settings window text ->
            let
                width =
                    round window.viewport.width

                height =
                    round window.viewport.height - 50

                result =
                    updateDiagram width height model text
            in
            case result of
                Ok usm ->
                    ( { usm | windowWidth = width, settings = settings, error = Nothing }, Cmd.none )

                Err err ->
                    ( { model | windowWidth = width, error = Just err }, Cmd.none )

        ZoomIn ->
            ( if model.svg.scale >= 0.1 then
                { model
                    | svg =
                        { width = model.svg.width
                        , height = model.svg.height
                        , scale = model.svg.scale - 0.05
                        }
                }

              else
                model
            , Cmd.none
            )

        ZoomOut ->
            ( if model.svg.scale <= 2.0 then
                { model
                    | svg =
                        { width = model.svg.width
                        , height = model.svg.height
                        , scale = model.svg.scale + 0.05
                        }
                }

              else
                model
            , Cmd.none
            )

        PinchIn distance ->
            ( { model | touchDistance = Just distance }, Task.perform identity (Task.succeed ZoomIn) )

        PinchOut distance ->
            ( { model | touchDistance = Just distance }, Task.perform identity (Task.succeed ZoomOut) )

        OnChangeText text ->
            let
                result =
                    updateDiagram model.width model.height model text
            in
            ( case result of
                Ok usm ->
                    { usm | error = Nothing }

                Err err ->
                    { model | error = Just err }
            , Cmd.none
            )

        Start x y ->
            ( { model
                | moveStart = True
                , moveX = x
                , moveY = y
              }
            , Cmd.none
            )

        Stop ->
            ( { model
                | moveStart = False
                , moveX = 0
                , moveY = 0
                , touchDistance = Nothing
              }
            , Cmd.none
            )

        Move x y ->
            ( if not model.moveStart || (x == model.moveX && y == model.moveY) then
                model

              else
                { model
                    | x = model.x + (x - model.moveX)
                    , y = model.y + (y - model.moveY)
                    , moveX = x
                    , moveY = y
                }
            , Cmd.none
            )

        MoveTo x y ->
            ( { model
                | x = x
                , y = y
                , moveX = 0
                , moveY = 0
              }
            , Cmd.none
            )

        ToggleFullscreen ->
            ( { model
                | moveX = 0
                , moveY = 0
                , fullscreen = not model.fullscreen
              }
            , Cmd.none
            )

        OnResize width height ->
            ( { model
                | width = width
                , height = height - 56
                , moveX = 0
                , moveY = 0
              }
            , Cmd.none
            )

        StartPinch distance ->
            ( { model | touchDistance = Just distance }, Cmd.none )

        ItemClick item ->
            ( { model | selectedItem = Just item }, Task.attempt (\_ -> NoOp) (Dom.focus <| "edit-item-" ++ String.fromInt item.lineNo) )

        DeselectItem ->
            ( { model | selectedItem = Nothing }, Cmd.none )

        EditSelectedItem text ->
            ( { model | selectedItem = Maybe.andThen (\i -> Just { i | text = String.trimLeft text }) model.selectedItem }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )
