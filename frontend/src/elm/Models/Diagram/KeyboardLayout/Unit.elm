module Models.Diagram.KeyboardLayout.Unit exposing (Unit, fromString, toFloat, u1, zero)


type Unit
    = Unit Float


u1 : Unit
u1 =
    Unit 1.0


zero : Unit
zero =
    Unit 0.0


toFloat : Unit -> Float
toFloat (Unit f) =
    f


fromString : String -> Maybe Unit
fromString unit =
    case String.toLower <| unit of
        "7u" ->
            Just <| Unit 7.0

        "6.25u" ->
            Just <| Unit 6.25

        "6u" ->
            Just <| Unit 6

        "5u" ->
            Just <| Unit 5

        "4u" ->
            Just <| Unit 4

        "3u" ->
            Just <| Unit 3

        "2.75u" ->
            Just <| Unit 2.75

        "2.5u" ->
            Just <| Unit 2.5

        "2.25u" ->
            Just <| Unit 2.25

        "2u" ->
            Just <| Unit 2

        "1.75u" ->
            Just <| Unit 1.75

        "1.5u" ->
            Just <| Unit 1.5

        "1.25u" ->
            Just <| Unit 1.25

        "0.75u" ->
            Just <| Unit 0.75

        "0.5u" ->
            Just <| Unit 0.5

        "0.25u" ->
            Just <| Unit 0.25

        _ ->
            Nothing
