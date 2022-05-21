module Models.IpAddress exposing (IpAddress, fromString, localhost, toString)

import Parser exposing ((|.), (|=), Parser, end, oneOf, symbol)
import Utils.Parser exposing (byte, intRange)


type IpAddress
    = IpAddress Int Int Int Int Int


fromString : String -> Maybe IpAddress
fromString s =
    Result.toMaybe <|
        Parser.run ipParser s


localhost : IpAddress
localhost =
    IpAddress 127 0 0 1 32


toString : IpAddress -> String
toString (IpAddress p1 p2 p3 p4 cidr) =
    String.fromInt p1 ++ "." ++ String.fromInt p2 ++ "." ++ String.fromInt p3 ++ "." ++ String.fromInt p4 ++ "/" ++ String.fromInt cidr


ipParser : Parser IpAddress
ipParser =
    Parser.succeed IpAddress
        |= byte
        |. symbol "."
        |= byte
        |. symbol "."
        |= byte
        |. symbol "."
        |= byte
        |= oneOf
            [ Parser.map (\_ -> 32) end
            , Parser.succeed identity
                |. symbol "/"
                |= intRange 0 32
                |. end
            ]
