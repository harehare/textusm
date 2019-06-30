module TestExportApi exposing (createRequestTest)

import Api.Export exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Models.Diagram exposing (..)
import Models.Item as Item exposing (Children, Item, ItemType(..))
import Test exposing (..)


createRequestTest : Test
createRequestTest =
    describe "createRequestTest test"
        [ test "No tasks" <|
            \() ->
                createRequest "token"
                    (Just "code")
                    Nothing
                    1
                    [ ( "RELEASE1", "" ) ]
                    "board"
                    [ { text = "text1"
                      , comment = Just "comment1"
                      , itemType = Activities
                      , children = Item.fromItems []
                      , lineNo = 0
                      }
                    ]
                    |> .tasks
                    |> Expect.equal
                        []
        , test "1 tasks" <|
            \() ->
                createRequest "token"
                    (Just "code")
                    Nothing
                    1
                    [ ( "RELEASE1", "" ) ]
                    "board"
                    [ { text = "text1"
                      , comment = Just "comment1"
                      , itemType = Activities
                      , lineNo = 0
                      , children =
                            Item.fromItems
                                [ { text = "text2"
                                  , comment = Just "comment2"
                                  , itemType = Tasks
                                  , children = Item.fromItems []
                                  , lineNo = 0
                                  }
                                ]
                      }
                    ]
                    |> .tasks
                    |> Expect.equal
                        [ { name = "text2"
                          , comment = Just "comment2"
                          , stories = []
                          }
                        ]
        , test "1 tasks, 1 stories" <|
            \() ->
                createRequest "token"
                    (Just "code")
                    Nothing
                    2
                    [ ( "RELEASE1", "" ), ( "RELEASE2", "" ) ]
                    "board"
                    [ { text = "text1"
                      , comment = Just "comment1"
                      , itemType = Activities
                      , lineNo = 0
                      , children =
                            Item.fromItems
                                [ { text = "text2"
                                  , comment = Just "comment2"
                                  , itemType = Tasks
                                  , lineNo = 0
                                  , children =
                                        Item.fromItems
                                            [ { text = "text3"
                                              , comment = Just "comment3"
                                              , itemType = Stories 1
                                              , children = Item.fromItems []
                                              , lineNo = 0
                                              }
                                            ]
                                  }
                                ]
                      }
                    ]
                    |> .tasks
                    |> Expect.equal
                        [ { name = "text2"
                          , comment = Just "comment2"
                          , stories =
                                [ { name = "text3"
                                  , comment = Just "comment3"
                                  , release = 1
                                  }
                                ]
                          }
                        ]
        , test "2 tasks, 2 stories" <|
            \() ->
                createRequest "token"
                    (Just "code")
                    Nothing
                    2
                    [ ( "RELEASE1", "" ), ( "RELEASE2", "" ) ]
                    "board"
                    [ { text = "text1"
                      , comment = Just "comment1"
                      , itemType = Activities
                      , lineNo = 0
                      , children =
                            Item.fromItems
                                [ { text = "text2"
                                  , comment = Just "comment2"
                                  , itemType = Tasks
                                  , lineNo = 0
                                  , children =
                                        Item.fromItems
                                            [ { text = "text3"
                                              , comment = Just "comment3"
                                              , itemType = Stories 2
                                              , children = Item.fromItems []
                                              , lineNo = 0
                                              }
                                            ]
                                  }
                                ]
                      }
                    , { text = "1text1"
                      , comment = Just "1comment1"
                      , itemType = Activities
                      , lineNo = 0
                      , children =
                            Item.fromItems
                                [ { text = "1text2"
                                  , comment = Just "1comment2"
                                  , itemType = Tasks
                                  , lineNo = 0
                                  , children =
                                        Item.fromItems
                                            [ { text = "1text3"
                                              , comment = Just "1comment3"
                                              , itemType = Stories 3
                                              , children = Item.fromItems []
                                              , lineNo = 0
                                              }
                                            ]
                                  }
                                ]
                      }
                    ]
                    |> .tasks
                    |> Expect.equal
                        [ { name = "1text2"
                          , comment = Just "1comment2"
                          , stories =
                                [ { name = "1text3"
                                  , comment = Just "1comment3"
                                  , release = 3
                                  }
                                ]
                          }
                        , { name = "text2"
                          , comment = Just "comment2"
                          , stories =
                                [ { name = "text3"
                                  , comment = Just "comment3"
                                  , release = 2
                                  }
                                ]
                          }
                        ]
        ]
