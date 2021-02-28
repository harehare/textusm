module Utils.Date exposing (millisToString, monthToInt)

import Time exposing (Month(..), Posix, Zone)
import Time.Extra exposing (Interval(..))


millisToString : Zone -> Posix -> String
millisToString timezone posix =
    String.fromInt (Time.toYear timezone posix)
        ++ "-"
        ++ (monthToInt (Time.toMonth timezone posix) |> String.fromInt |> String.padLeft 2 '0')
        ++ "-"
        ++ (Time.toDay timezone posix |> String.fromInt |> String.padLeft 2 '0')
        ++ " "
        ++ (Time.toHour timezone posix |> String.fromInt |> String.padLeft 2 '0')
        ++ ":"
        ++ (Time.toMinute timezone posix |> String.fromInt |> String.padLeft 2 '0')
        ++ ":"
        ++ (Time.toSecond timezone posix |> String.fromInt |> String.padLeft 2 '0')


monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12
