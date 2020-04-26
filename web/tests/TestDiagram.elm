module TestDiagram exposing (changeTextTest, moveStartTest, moveStopTest, moveTest, moveToTest, noOpTest, toggleFullscreenText, zoomInTest, zoomOutTest)

import Components.Diagram exposing (init, update)
import Data.Item as Item exposing (ItemType(..))
import Expect
import Models.Diagram exposing (Model, Msg(..), Settings)
import Test exposing (Test, describe, test)


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


noOpTest : Test
noOpTest =
    describe "no op test"
        [ test "no op" <|
            \() ->
                update NoOp defInit
                    |> Tuple.first
                    |> Expect.equal defInit
        ]


zoomInTest : Test
zoomInTest =
    describe "zoom in test"
        [ test "Zoom in" <|
            \() ->
                update ZoomIn defInit
                    |> Tuple.first
                    |> .svg
                    |> .scale
                    |> List.singleton
                    |> Expect.equal [ 0.95 ]
        , test "Zoom in limit" <|
            \() ->
                let
                    newModel =
                        { defInit
                            | svg =
                                { width = defInit.svg.width
                                , height = defInit.svg.height
                                , scale = 0.1
                                }
                        }
                in
                update ZoomIn newModel
                    |> Tuple.first
                    |> .svg
                    |> .scale
                    |> List.singleton
                    |> Expect.equal [ 0.05 ]
        ]


zoomOutTest : Test
zoomOutTest =
    describe "zoom out test"
        [ test "Zoom out" <|
            \() ->
                update ZoomOut defInit
                    |> Tuple.first
                    |> .svg
                    |> .scale
                    |> List.singleton
                    |> Expect.equal [ 1.05 ]
        , test "Zoom out limit" <|
            \() ->
                let
                    newModel =
                        { defInit
                            | svg =
                                { width = defInit.svg.width
                                , height = defInit.svg.height
                                , scale = 2.0
                                }
                        }
                in
                update ZoomOut newModel
                    |> Tuple.first
                    |> .svg
                    |> .scale
                    |> List.singleton
                    |> Expect.equal [ 2.05 ]
        ]


moveStartTest : Test
moveStartTest =
    describe "move start test"
        [ test "Move start" <|
            \() ->
                let
                    newModel =
                        update (Start 10 20) defInit
                            |> Tuple.first
                in
                Expect.equal newModel { newModel | moveStart = True, moveX = 10, moveY = 20 }
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
                Expect.equal newModel { newModel | moveStart = False, moveX = 0, moveY = 0, touchDistance = Nothing }
        ]


moveTest : Test
moveTest =
    describe "move test"
        [ test "Did not move" <|
            \() ->
                let
                    newModel =
                        update (Move 10 20) defInit
                            |> Tuple.first
                in
                Expect.equal defInit newModel
        , test "Same as previous position" <|
            \() ->
                let
                    newModel =
                        update (Move 0 0) defInit
                            |> Tuple.first
                in
                Expect.equal defInit newModel
        , test "Moved" <|
            \() ->
                let
                    newModel =
                        update (Start 0 0) defInit
                            |> Tuple.first

                    moveModel =
                        update (Move 10 20) newModel
                            |> Tuple.first
                in
                Expect.equal moveModel { newModel | x = newModel.x + 10, y = newModel.y + 20, moveX = 10, moveY = 20 }
        ]


moveToTest : Test
moveToTest =
    describe "move to test"
        [ test "Move to specified position" <|
            \() ->
                let
                    newModel =
                        update (MoveTo 10 20) defInit
                            |> Tuple.first
                in
                Expect.equal newModel { defInit | x = 10, y = 20 }
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
