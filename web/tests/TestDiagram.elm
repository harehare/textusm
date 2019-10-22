module TestDiagram exposing (updateTest)

import Components.Diagram exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Models.Diagram exposing (..)
import Models.Item as Item exposing (..)
import Test exposing (..)


defaultSettings : Settings
defaultSettings =
    { font = "apple-system, BlinkMacSystemFont, Helvetica Neue, Hiragino Kaku Gothic ProN, 游ゴシック Medium, YuGothic, YuGothicM, メイリオ, Meiryo, sans-serif"
    , size =
        { width = 140
        , height = 65
        }
    , backgroundColor = "#F5F5F6"
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


updateTest : Test
updateTest =
    describe "update test"
        [ test "load only activity item" <|
            \() ->
                update (OnChangeText "test1") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , itemType = Activities
                          , lineNo = 0
                          , children = Item.empty
                          }
                        ]
        , test "load activity items" <|
            \() ->
                update (OnChangeText "test1\ntest2") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , itemType = Activities
                          , lineNo = 0
                          , children = Item.empty
                          }
                        , { text = "test2"
                          , itemType = Activities
                          , lineNo = 1
                          , children = Item.empty
                          }
                        ]
        , test "load task item" <|
            \() ->
                update (OnChangeText "test1\n    test2") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , itemType = Activities
                          , lineNo = 0
                          , children =
                                Item.fromItems
                                    [ { text = "    test2"
                                      , itemType = Tasks
                                      , children = Item.empty
                                      , lineNo = 1
                                      }
                                    ]
                          }
                        ]
        , test "load task items" <|
            \() ->
                update (OnChangeText "test1\n    test2\n    test3") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , itemType = Activities
                          , lineNo = 0
                          , children =
                                Item.fromItems
                                    [ { text = "    test2"
                                      , itemType = Tasks
                                      , lineNo = 1
                                      , children = Item.empty
                                      }
                                    , { text = "    test3"
                                      , itemType = Tasks
                                      , lineNo = 2
                                      , children = Item.empty
                                      }
                                    ]
                          }
                        ]
        , test "load story item" <|
            \() ->
                update (OnChangeText "test1\n    test2\n        test3") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , itemType = Activities
                          , lineNo = 0
                          , children =
                                Item.fromItems
                                    [ { text = "    test2"
                                      , itemType = Tasks
                                      , lineNo = 1
                                      , children =
                                            Item.fromItems
                                                [ { text = "        test3"
                                                  , itemType = Stories 1
                                                  , children = Item.empty
                                                  , lineNo = 2
                                                  }
                                                ]
                                      }
                                    ]
                          }
                        ]
        , test "load story items" <|
            \() ->
                update (OnChangeText "test1\n    test2\n        test3\n        test4") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , itemType = Activities
                          , lineNo = 0
                          , children =
                                Item.fromItems
                                    [ { text = "    test2"
                                      , itemType = Tasks
                                      , lineNo = 1
                                      , children =
                                            Item.fromItems
                                                [ { text = "        test3"
                                                  , itemType = Stories 1
                                                  , lineNo = 2
                                                  , children = Item.empty
                                                  }
                                                , { text = "        test4"
                                                  , itemType = Stories 1
                                                  , lineNo = 3
                                                  , children = Item.empty
                                                  }
                                                ]
                                      }
                                    ]
                          }
                        ]
        ]
