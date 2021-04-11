module Data.IpAddressTests exposing (..)

import Data.IpAddress as IpAddress
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "IpAddress test"
        [ describe "fromString test"
            [ test "valid IP" <|
                \() ->
                    Expect.equal (IpAddress.fromString "1.1.1.1" |> Maybe.withDefault IpAddress.localhost |> IpAddress.toString) "1.1.1.1"
            , test "valid IP with CIDR" <|
                \() ->
                    Expect.equal (IpAddress.fromString "10.1.1.1/32" |> Maybe.withDefault IpAddress.localhost |> IpAddress.toString) "10.1.1.1/32"
            , test "invalid IP" <|
                \() ->
                    Expect.equal (IpAddress.fromString "256.0.0.1" |> Maybe.withDefault IpAddress.localhost |> IpAddress.toString) "127.0.0.1"
            , test "invalid IP with CIDR" <|
                \() ->
                    Expect.equal (IpAddress.fromString "255.0.0.1/33" |> Maybe.withDefault IpAddress.localhost |> IpAddress.toString) "255.0.0.1"
            ]
        ]
