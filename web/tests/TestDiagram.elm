module TestDiagram exposing (businessModelCanvasRenderTest, changeTextTest, moveStartTest, moveStopTest, moveTest, moveToTest, noOpTest, toggleFullscreenText, userStoryMapRenderTest)

import Browser.Dom exposing (Viewport)
import Components.Diagram exposing (init, update, view)
import Data.Item as Item exposing (ItemType(..))
import Data.Position as Position
import Expect
import Models.Diagram exposing (Model, Msg(..), Settings)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (tag)
import TextUSM.Enum.Diagram exposing (Diagram(..))


defaultSettings : Settings
defaultSettings =
    { font = "apple-system, BlinkMacSystemFont, Helvetica Neue, Hiragino Kaku Gothic ProN, 游ゴシック Medium, YuGothic, YuGothicM, メイリオ, Meiryo, sans-serif"
    , size =
        { width = 140
        , height = 65
        }
    , backgroundColor = "#F5F5F6"
    , zoomControl = Just True
    , color =
        { activity =
            { color = "#FFFFFF"
            , backgroundColor = "#266B9A"
            }
        , task =
            { color = "#FFFFFF"
            , backgroundColor = "#3E9BCD"
            }
        , story =
            { color = "#000000"
            , backgroundColor = "#FFFFFF"
            }
        , line = "#434343"
        , label = "#8C9FAE"
        , text = Just "#111111"
        }
    }


defInit : Model
defInit =
    init defaultSettings
        |> Tuple.first


defViewport : Viewport
defViewport =
    { scene =
        { width = 0
        , height = 0
        }
    , viewport =
        { x = 0
        , y = 0
        , width = 0
        , height = 0
        }
    }


noOpTest : Test
noOpTest =
    describe "no op test"
        [ test "no op" <|
            \() ->
                update NoOp defInit
                    |> Tuple.first
                    |> Expect.equal defInit
        ]


moveStartTest : Test
moveStartTest =
    describe "move start test"
        [ test "Move start" <|
            \() ->
                let
                    newModel =
                        update (Start ( 10, 20 )) defInit
                            |> Tuple.first
                in
                Expect.equal newModel { newModel | moveStart = True, movePosition = ( 10, 20 ) }
        ]


moveStopTest : Test
moveStopTest =
    describe "move stop test"
        [ test "move stop " <|
            \() ->
                let
                    newModel =
                        update Stop defInit
                            |> Tuple.first
                in
                Expect.equal newModel { newModel | moveStart = False, movePosition = ( 0, 0 ), touchDistance = Nothing }
        ]


moveTest : Test
moveTest =
    describe "move test"
        [ test "Did not move" <|
            \() ->
                let
                    newModel =
                        update (Move ( 10, 20 )) defInit
                            |> Tuple.first
                in
                Expect.equal defInit newModel
        , test "Same as previous position" <|
            \() ->
                let
                    newModel =
                        update (Move ( 0, 0 )) defInit
                            |> Tuple.first
                in
                Expect.equal defInit newModel
        , test "Moved" <|
            \() ->
                let
                    newModel =
                        update (Start ( 0, 0 )) defInit
                            |> Tuple.first

                    moveModel =
                        update (Move ( 10, 20 )) newModel
                            |> Tuple.first
                in
                Expect.equal moveModel { newModel | position = ( Position.getX newModel.position + 10, Position.getY newModel.position + 20 ), movePosition = ( 10, 20 ) }
        ]


moveToTest : Test
moveToTest =
    describe "move to test"
        [ test "Move to specified position" <|
            \() ->
                let
                    newModel =
                        update (MoveTo ( 10, 20 )) defInit
                            |> Tuple.first
                in
                Expect.equal newModel { defInit | position = ( 10, 20 ) }
        ]


toggleFullscreenText : Test
toggleFullscreenText =
    describe "Toggle fullscreen"
        [ test "Fullscreen" <|
            \() ->
                let
                    newModel =
                        update ToggleFullscreen defInit
                            |> Tuple.first
                in
                Expect.equal newModel { defInit | fullscreen = True }
        , test "Exit fullscreen" <|
            \() ->
                let
                    newModel =
                        update ToggleFullscreen defInit
                            |> Tuple.first
                            |> update ToggleFullscreen
                            |> Tuple.first
                in
                Expect.equal newModel { defInit | fullscreen = False }
        ]


changeTextTest : Test
changeTextTest =
    describe "changeText"
        [ test "load only activity item" <|
            \() ->
                update (OnChangeText "test1") defInit
                    |> Tuple.first
                    |> .items
                    |> Expect.equal
                        (Item.fromList
                            [ { text = "test1"
                              , itemType = Activities
                              , lineNo = 0
                              , children = Item.emptyChildren
                              }
                            ]
                        )
        , test "load activity items" <|
            \() ->
                update (OnChangeText "test1\ntest2") defInit
                    |> Tuple.first
                    |> .items
                    |> Expect.equal
                        (Item.fromList
                            [ { text = "test1"
                              , itemType = Activities
                              , lineNo = 0
                              , children = Item.emptyChildren
                              }
                            , { text = "test2"
                              , itemType = Activities
                              , lineNo = 1
                              , children = Item.emptyChildren
                              }
                            ]
                        )
        , test "load task item" <|
            \() ->
                update (OnChangeText "test1\n    test2") defInit
                    |> Tuple.first
                    |> .items
                    |> Expect.equal
                        (Item.fromList
                            [ { text = "test1"
                              , itemType = Activities
                              , lineNo = 0
                              , children =
                                    Item.childrenFromItems
                                        (Item.fromList
                                            [ { text = "    test2"
                                              , itemType = Tasks
                                              , children = Item.emptyChildren
                                              , lineNo = 1
                                              }
                                            ]
                                        )
                              }
                            ]
                        )
        , test "load task items" <|
            \() ->
                update (OnChangeText "test1\n    test2\n    test3") defInit
                    |> Tuple.first
                    |> .items
                    |> Expect.equal
                        (Item.fromList
                            [ { text = "test1"
                              , itemType = Activities
                              , lineNo = 0
                              , children =
                                    Item.childrenFromItems
                                        (Item.fromList
                                            [ { text = "    test2"
                                              , itemType = Tasks
                                              , lineNo = 1
                                              , children = Item.emptyChildren
                                              }
                                            , { text = "    test3"
                                              , itemType = Tasks
                                              , lineNo = 2
                                              , children = Item.emptyChildren
                                              }
                                            ]
                                        )
                              }
                            ]
                        )
        , test "load story item" <|
            \() ->
                update (OnChangeText "test1\n    test2\n        test3") defInit
                    |> Tuple.first
                    |> .items
                    |> Expect.equal
                        (Item.fromList
                            [ { text = "test1"
                              , itemType = Activities
                              , lineNo = 0
                              , children =
                                    Item.childrenFromItems
                                        (Item.fromList
                                            [ { text = "    test2"
                                              , itemType = Tasks
                                              , lineNo = 1
                                              , children =
                                                    Item.childrenFromItems
                                                        (Item.fromList
                                                            [ { text = "        test3"
                                                              , itemType = Stories 1
                                                              , children = Item.emptyChildren
                                                              , lineNo = 2
                                                              }
                                                            ]
                                                        )
                                              }
                                            ]
                                        )
                              }
                            ]
                        )
        , test "load story items" <|
            \() ->
                update (OnChangeText "test1\n    test2\n        test3\n        test4") defInit
                    |> Tuple.first
                    |> .items
                    |> Expect.equal
                        (Item.fromList
                            [ { text = "test1"
                              , itemType = Activities
                              , lineNo = 0
                              , children =
                                    Item.childrenFromItems
                                        (Item.fromList
                                            [ { text = "    test2"
                                              , itemType = Tasks
                                              , lineNo = 1
                                              , children =
                                                    Item.childrenFromItems
                                                        (Item.fromList
                                                            [ { text = "        test3"
                                                              , itemType = Stories 1
                                                              , lineNo = 2
                                                              , children = Item.emptyChildren
                                                              }
                                                            , { text = "        test4"
                                                              , itemType = Stories 1
                                                              , lineNo = 3
                                                              , children = Item.emptyChildren
                                                              }
                                                            ]
                                                        )
                                              }
                                            ]
                                        )
                              }
                            ]
                        )
        ]


userStoryMapRenderTest : Test
userStoryMapRenderTest =
    let
        ( initModel, _ ) =
            init defaultSettings

        ( model_, _ ) =
            update (Init defaultSettings defViewport "test\n    test\n    test\n        test\n            test\ntest\n    test\n    test\n        test") initModel
    in
    describe "User Story Map Rendering"
        [ test "User Story Map rect count" <|
            \() ->
                view model_
                    |> Query.fromHtml
                    |> Query.findAll [ tag "rect" ]
                    |> Query.count (Expect.equal 9)
        , test "User Story Map label count" <|
            \() ->
                view model_
                    |> Query.fromHtml
                    |> Query.findAll [ tag "foreignObject" ]
                    |> Query.count (Expect.equal 5)
        , test "User Story Map line count" <|
            \() ->
                view model_
                    |> Query.fromHtml
                    |> Query.findAll [ tag "line" ]
                    |> Query.count (Expect.equal 2)
        ]


businessModelCanvasRenderTest : Test
businessModelCanvasRenderTest =
    let
        ( initModel, _ ) =
            init defaultSettings

        ( model_, _ ) =
            update (Init defaultSettings defViewport "👥 Key Partners\n📊 Customer Segments\n🎁 Value Proposition\n✅ Key Activities\n🚚 Channels\n💰 Revenue Streams\n🏷️ Cost Structure\n💪 Key Resources\n💙 Customer Relationships") { initModel | diagramType = BusinessModelCanvas }
    in
    describe "Business Model Canvas Rendering"
        [ test "Business Model Canvas rect count" <|
            \() ->
                view model_
                    |> Query.fromHtml
                    |> Query.findAll [ tag "rect" ]
                    |> Query.count (Expect.equal 9)
        ]
