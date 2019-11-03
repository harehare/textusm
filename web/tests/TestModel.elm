module TestModel exposing (canWriteTest)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Models.DiagramItem exposing (..)
import Models.Model exposing (..)
import Models.User exposing (..)
import Test exposing (..)


testDiagram : DiagramItem
testDiagram =
    { diagramPath = ""
    , id = Nothing
    , ownerId = Nothing
    , text = ""
    , thumbnail = Nothing
    , title = ""
    , isRemote = False
    , isPublic = False
    , users = Nothing
    , updatedAt = Nothing
    }


testUser : User
testUser =
    { displayName = "test"
    , email = "test@textusm.com"
    , photoURL = "https://foo.bar"
    , idToken = "BBBBBB"
    , id = "FFFFFF"
    }


testDiagramUser : DiagramUser
testDiagramUser =
    { id = ""
    , name = ""
    , photoURL = ""
    , role = ""
    , mail = ""
    }


canWriteTest =
    describe "canWrite test"
        [ test "If not save diagram then can write." <|
            \() ->
                canWrite Nothing (Just testUser)
                    |> Expect.equal True
        , test "If Diagram is save to local then can write." <|
            \() ->
                canWrite (Just { testDiagram | isRemote = False }) (Just testUser)
                    |> Expect.equal True
        , test "If login user is diagram owner then can write." <|
            \() ->
                canWrite (Just { testDiagram | ownerId = Just "XXXXXX" }) (Just { testUser | id = "XXXXXX" })
                    |> Expect.equal True
        , test "If login user is not diagram owner then can not write." <|
            \() ->
                canWrite (Just { testDiagram | isRemote = True, ownerId = Just "XXXXXX" }) (Just { testUser | id = "FFFFFF" })
                    |> Expect.equal False
        , test "If login user is diagram editor then can write." <|
            \() ->
                canWrite
                    (Just
                        { testDiagram
                            | users =
                                Just
                                    [ { testDiagramUser | id = "FFFFFF", role = "Editor" }
                                    ]
                        }
                    )
                    (Just { testUser | id = "FFFFFF" })
                    |> Expect.equal True
        , test "If login user is not diagram editor then can not write." <|
            \() ->
                canWrite
                    (Just
                        { testDiagram
                            | isRemote = True
                            , users =
                                Just
                                    [ { testDiagramUser | id = "FFFFFF", role = "Viewer" }
                                    ]
                        }
                    )
                    (Just { testUser | id = "FFFFFF" })
                    |> Expect.equal False
        , test "If login user is not diagram user then can not write." <|
            \() ->
                canWrite
                    (Just
                        { testDiagram
                            | isRemote = True
                            , users =
                                Just
                                    [ { testDiagramUser | id = "XXXXXX", role = "Editor" }
                                    ]
                        }
                    )
                    (Just { testUser | id = "FFFFFF" })
                    |> Expect.equal False
        ]
