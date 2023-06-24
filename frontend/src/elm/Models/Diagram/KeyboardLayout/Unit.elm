module Models.Diagram.KeyboardLayout.Unit exposing (Unit, fromString, toFloat, u1)


type Unit
    = Unit Float


u1 : Unit
u1 =
    Unit 1.0


toFloat : Unit -> Float
toFloat (Unit f) =
    f


fromString : String -> Unit
fromString unit =
    case unit of
        "7" ->
            Unit 7.0

        "6.25" ->
            Unit 6.25

        "6" ->
            Unit 6

        "5" ->
            Unit 5

        "4" ->
            Unit 4

        "3" ->
            Unit 3

        "2.75" ->
            Unit 2.75

        "2.5" ->
            Unit 2.5

        "2.25" ->
            Unit 2.25

        "2" ->
            Unit 2

        "1.75" ->
            Unit 1.75

        "1.5" ->
            Unit 1.5

        "1.25" ->
            Unit 1.25

        _ ->
            Unit 1.0
