module Components.Diagram exposing (init, update, view)

import Basics exposing (max)
import Browser.Dom as Dom
import Data.Item as Item exposing (ItemType(..), Items)
import Data.Size exposing (Size)
import Data.Text as Text
import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import Html5.DragDrop as DragDrop
import List
import List.Extra exposing (getAt, scanl)
import Maybe.Extra exposing (isNothing)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Parser
import Result exposing (andThen)
import String
import Svg exposing (Svg, defs, feComponentTransfer, feFuncA, feGaussianBlur, feMerge, feMergeNode, feOffset, filter, g, svg, text)
import Svg.Attributes exposing (class, dx, dy, height, id, in_, result, slope, stdDeviation, type_, viewBox, width)
import Svg.Events exposing (onClick)
import Svg.Lazy exposing (lazy, lazy2)
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Utils
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.CustomerJourneyMap as CustomerJourneyMap
import Views.Diagram.ER as ER
import Views.Diagram.EmpathyMap as EmpathyMap
import Views.Diagram.FourLs as FourLs
import Views.Diagram.GanttChart as GanttChart
import Views.Diagram.ImpactMap as ImpactMap
import Views.Diagram.Kanban as Kanban
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


type alias Hierarchy =
    Int


init : Settings -> ( Model, Cmd Msg )
init settings =
    ( { items = Item.empty
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
      , diagramType = UserStoryMap
      , labels = []
      , text = Text.empty
      , matchParent = False
      , selectedItem = Nothing
      , dragDrop = DragDrop.init
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


loadText : Diagram -> Int -> Int -> String -> ( List Hierarchy, Items )
loadText diagramType lineNo indent input =
    case Parser.parse indent input of
        ( x :: xs, other ) ->
            let
                ( xsIndent, xsItems ) =
                    loadText diagramType (lineNo + 1) (indent + 1) (String.join "\n" xs)

                ( otherIndents, otherItems ) =
                    loadText diagramType (lineNo + List.length (x :: xs)) indent (String.join "\n" other)
            in
            ( indent :: xsIndent ++ otherIndents
            , Item.cons
                { lineNo = lineNo
                , text = x
                , itemType = getItemType x indent
                , children = Item.childrenFromItems xsItems
                }
                (Item.filter (\item -> item.itemType /= Comments) otherItems)
            )

        ( [], _ ) ->
            ( [ indent ], Item.empty )


load : Diagram -> String -> ( Hierarchy, Items )
load diagramType text =
    if String.isEmpty text then
        ( 0, Item.empty )

    else
        let
            ( indentList, loadedItems ) =
                loadText diagramType 0 0 text
        in
        ( indentList
            |> List.maximum
            |> Maybe.map (\x -> x - 1)
            |> Maybe.withDefault 0
        , loadedItems
        )


countUpToHierarchy : Int -> Items -> List Int
countUpToHierarchy hierarchy items =
    let
        countUp : Items -> List (List Int)
        countUp countItems =
            [ countItems
                |> Item.filter (\x -> x.itemType /= Tasks && x.itemType /= Activities)
                |> Item.length
            ]
                :: (countItems
                        |> Item.map
                            (\it ->
                                let
                                    results =
                                        countUp (Item.unwrapChildren it.children)
                                            |> Utils.transpose
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
                |> Utils.transpose
                |> List.map
                    (\it ->
                        List.maximum it |> Maybe.withDefault 0
                    )
           )


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

        ErDiagram ->
            ER.view

        Kanban ->
            Kanban.view


scaleAdjustment : Diagram -> Float
scaleAdjustment type_ =
    case type_ of
        ErDiagram ->
            0.4

        _ ->
            0.2


svgView : Model -> Svg Msg
svgView model =
    let
        adjustmentValue =
            scaleAdjustment model.diagramType

        svgWidth =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.width model.width)
                    * (model.svg.scale + adjustmentValue)
                    |> round
                    |> String.fromInt

            else
                Basics.toFloat
                    model.width
                    * (model.svg.scale + adjustmentValue)
                    |> round
                    |> String.fromInt

        svgHeight =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.height model.height)
                    * (model.svg.scale + adjustmentValue)
                    |> round
                    |> String.fromInt

            else
                Basics.toFloat
                    model.height
                    * (model.svg.scale + adjustmentValue)
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
        , if isNothing model.selectedItem then
            onDragStart (Utils.isPhone model.width)

          else
            class ""
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
        , defs []
            [ filter [ id "shadow", height "130%" ]
                [ feGaussianBlur [ in_ "SourceAlpha", stdDeviation "3" ] []
                , feOffset [ dx "2", dy "2", result "offsetblur" ] []
                , feComponentTransfer []
                    [ feFuncA [ type_ "linear", slope "0.5" ] []
                    ]
                , feMerge []
                    [ feMergeNode [] []
                    , feMergeNode [ in_ "SourceGraphic" ] []
                    ]
                ]
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


updateDiagram : Size -> Model -> String -> Model
updateDiagram ( width, height ) base text =
    let
        ( hierarchy, items ) =
            load base.diagramType text

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

        newModel =
            { base
                | items = items
                , hierarchy = hierarchy
                , countByTasks = scanl (\it v -> v + Item.length (Item.unwrapChildren it.children)) 0 (Item.unwrap items)
                , countByHierarchy = countByHierarchy
            }

        ( svgWidth, svgHeight ) =
            Utils.getCanvasSize newModel
    in
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
        , labels = labels
        , text = Text.edit base.text text
    }


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

                model_ =
                    updateDiagram ( width, height ) model text
            in
            ( { model_ | settings = settings }, Cmd.none )

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
                model_ =
                    updateDiagram ( model.width, model.height ) model text
            in
            ( model_, Cmd.none )

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
                    | x = model.x + (toFloat x - toFloat model.moveX) * model.svg.scale
                    , y = model.y + (toFloat y - toFloat model.moveY) * model.svg.scale
                    , moveX = x
                    , moveY = y
                }
            , Cmd.none
            )

        MoveTo x y ->
            ( { model
                | x = toFloat x
                , y = toFloat y
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
            ( { model | selectedItem = Just item }
            , Task.attempt (\_ -> NoOp) (Dom.focus "edit-item")
            )

        EditSelectedItem text ->
            ( { model | selectedItem = Maybe.andThen (\i -> Just { i | text = " " ++ String.trimLeft text }) model.selectedItem }
            , Cmd.none
            )

        DeselectItem ->
            ( { model | selectedItem = Nothing }, Cmd.none )

        DragDropMsg msg_ ->
            let
                ( model_, result ) =
                    DragDrop.update msg_ model.dragDrop

                move =
                    Maybe.map (\( fromNo, toNo, _ ) -> ( fromNo, toNo )) result
            in
            case move of
                Just ( fromNo, toNo ) ->
                    ( { model | dragDrop = model_ }, Task.perform MoveItem (Task.succeed ( fromNo, toNo )) )

                Nothing ->
                    ( { model | dragDrop = model_ }, Cmd.none )

        _ ->
            ( model, Cmd.none )
