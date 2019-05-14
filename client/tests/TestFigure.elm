module TestFigure exposing (updateTest)

import Components.Figure exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Models.Figure exposing (..)
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
        , comment =
            { color = "#000000"
            , backgroundColor = "#F1B090"
            }
        , line = "#434343"
        , label = "#8C9FAE"
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
                          , comment = Nothing
                          , itemType = Activities
                          , children = Children []
                          }
                        ]
        , test "load activity items" <|
            \() ->
                update (OnChangeText "test1\ntest2") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , comment = Nothing
                          , itemType = Activities
                          , children = Children []
                          }
                        , { text = "test2"
                          , comment = Nothing
                          , itemType = Activities
                          , children = Children []
                          }
                        ]
        , test "load task item" <|
            \() ->
                update (OnChangeText "test1\n    test2") defInit
                    |> .items
                    |> Expect.equal
                        [ { text = "test1"
                          , comment = Nothing
                          , itemType = Activities
                          , children =
                                Children
                                    [ { text = "test2"
                                      , comment = Nothing
                                      , itemType = Tasks
                                      , children = Children []
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
                          , comment = Nothing
                          , itemType = Activities
                          , children =
                                Children
                                    [ { text = "test2"
                                      , comment = Nothing
                                      , itemType = Tasks
                                      , children = Children []
                                      }
                                    , { text = "test3"
                                      , comment = Nothing
                                      , itemType = Tasks
                                      , children = Children []
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
                          , comment = Nothing
                          , itemType = Activities
                          , children =
                                Children
                                    [ { text = "test2"
                                      , comment = Nothing
                                      , itemType = Tasks
                                      , children =
                                            Children
                                                [ { text = "test3"
                                                  , comment = Nothing
                                                  , itemType = Stories 1
                                                  , children = Children []
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
                          , comment = Nothing
                          , itemType = Activities
                          , children =
                                Children
                                    [ { text = "test2"
                                      , comment = Nothing
                                      , itemType = Tasks
                                      , children =
                                            Children
                                                [ { text = "test3"
                                                  , comment = Nothing
                                                  , itemType = Stories 1
                                                  , children = Children []
                                                  }
                                                , { text = "test4"
                                                  , comment = Nothing
                                                  , itemType = Stories 1
                                                  , children = Children []
                                                  }
                                                ]
                                      }
                                    ]
                          }
                        ]
        ]
