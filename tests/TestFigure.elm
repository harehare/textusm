module TestFigure exposing (updateTest)

import Components.Figure exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Models.Figure exposing (..)
import Test exposing (..)


updateTest : Test
updateTest =
    describe "update test"
        [ test "load only activity item" <|
            \() ->
                update (OnChangeText "test1") init
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
                update (OnChangeText "test1\ntest2") init
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
                update (OnChangeText "test1\n    test2") init
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
                update (OnChangeText "test1\n    test2\n    test3") init
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
                update (OnChangeText "test1\n    test2\n        test3") init
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
                                                  , itemType = Stories
                                                  , children = Children []
                                                  }
                                                ]
                                      }
                                    ]
                          }
                        ]
        , test "load story items" <|
            \() ->
                update (OnChangeText "test1\n    test2\n        test3\n        test4") init
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
                                                  , itemType = Stories
                                                  , children = Children []
                                                  }
                                                , { text = "test4"
                                                  , comment = Nothing
                                                  , itemType = Stories
                                                  , children = Children []
                                                  }
                                                ]
                                      }
                                    ]
                          }
                        ]
        ]
