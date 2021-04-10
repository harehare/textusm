module Data.IPAddressTests exposing (..)

import Data.IPAddress as IPAddress
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "IPAddress test"
        [ describe "fromString test"
            [ test "valid IP" <|
                \() ->
                    Expect.equal (IPAddress.fromString "1.1.1.1" |> Maybe.withDefault IPAddress.localhost |> IPAddress.toString) "1.1.1.1"
            , test "valid IP with CIDR" <|
                \() ->
                    Expect.equal (IPAddress.fromString "10.1.1.1/32" |> Maybe.withDefault IPAddress.localhost |> IPAddress.toString) "10.1.1.1/32"
            , test "invalid IP" <|
                \() ->
                    Expect.equal (IPAddress.fromString "256.0.0.1" |> Maybe.withDefault IPAddress.localhost |> IPAddress.toString) "127.0.0.1"
            , test "invalid IP with CIDR" <|
                \() ->
                    Expect.equal (IPAddress.fromString "255.0.0.1/33" |> Maybe.withDefault IPAddress.localhost |> IPAddress.toString) "255.0.0.1"
            ]
        ]
