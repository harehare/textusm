module Data.SessionTests exposing (suite)

import Data.IdToken as IdToken
import Data.Session as Session
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Session test"
        [ describe "isGuest test"
            [ test "guest" <|
                \() ->
                    Expect.equal (Session.isGuest Session.guest) True
            , test "not guest" <|
                \() ->
                    Expect.equal
                        (Session.isGuest <|
                            Session.signIn
                                { displayName = "Test"
                                , email = "test@test.com"
                                , photoURL = "test"
                                , idToken = "test"
                                , id = "test"
                                }
                        )
                        False
            ]
        , describe "isSignedIn test"
            [ test "signedIn" <|
                \() ->
                    Expect.equal (Session.isSignedIn Session.guest) False
            , test "not guest" <|
                \() ->
                    Expect.equal
                        (Session.isSignedIn <|
                            Session.signIn
                                { displayName = "Test"
                                , email = "test@test.com"
                                , photoURL = "test"
                                , idToken = "test"
                                , id = "test"
                                }
                        )
                        True
            ]
        , describe "getIdToken test"
            [ test "guest idtoken is empty" <|
                \() ->
                    Expect.equal (Session.getIdToken Session.guest) Nothing
            , test "signed in idtoken " <|
                \() ->
                    Expect.equal
                        (Session.getIdToken <|
                            Session.signIn
                                { displayName = "Test"
                                , email = "test@test.com"
                                , photoURL = "test"
                                , idToken = "idToken"
                                , id = "test"
                                }
                        )
                        (Just <| IdToken.fromString "idToken")
            ]
        ]
