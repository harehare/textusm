module Utils.Parser exposing (byte, intRange)

import Parser exposing (Parser, andThen, problem, succeed)


digit : Parser String
digit =
    Parser.getChompedString <| isDigit


byte : Parser Int
byte =
    andThen (parseInt 0 255) <| digit


intRange : Int -> Int -> Parser Int
intRange start end =
    andThen (parseInt start end) <| digit


isDigit : Parser ()
isDigit =
    Parser.chompWhile Char.isDigit


parseInt : Int -> Int -> String -> Parser Int
parseInt start end s =
    case Maybe.andThen (withinRange start end) <| String.toInt s of
        Just x ->
            succeed x

        Nothing ->
            problem "Invalid value"


withinRange : Int -> Int -> Int -> Maybe Int
withinRange start end x =
    if start <= x && x <= end then
        Just x

    else
        Nothing
