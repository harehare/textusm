module Utils.Date exposing (millisToDateString, millisToString, millisToTimeString, stringToPosix)

import String exposing (toInt)
import Time exposing (Month(..), Posix, Zone)
import Time.Extra as TimeEx


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


millisToDateString : Zone -> Posix -> String
millisToDateString timezone posix =
    String.fromInt (Time.toYear timezone posix)
        ++ "-"
        ++ (monthToInt (Time.toMonth timezone posix) |> String.fromInt |> String.padLeft 2 '0')
        ++ "-"
        ++ (Time.toDay timezone posix |> String.fromInt |> String.padLeft 2 '0')


millisToTimeString : Zone -> Posix -> String
millisToTimeString timezone posix =
    (Time.toHour timezone posix |> String.fromInt |> String.padLeft 2 '0')
        ++ ":"
        ++ (Time.toMinute timezone posix |> String.fromInt |> String.padLeft 2 '0')


stringToPosix : Zone -> String -> String -> Maybe Posix
stringToPosix zone date time =
    case ( String.split "-" date, String.split ":" time ) of
        ( [ y, m, d ], [ h, mi ] ) ->
            toInt y
                |> Maybe.andThen
                    (\year ->
                        toInt m
                            |> Maybe.andThen
                                (\month ->
                                    toInt d
                                        |> Maybe.andThen
                                            (\day ->
                                                toInt h
                                                    |> Maybe.andThen
                                                        (\hour ->
                                                            toInt mi
                                                                |> Maybe.map
                                                                    (\minute ->
                                                                        TimeEx.partsToPosix
                                                                            zone
                                                                            { year = year
                                                                            , month = toMonth month
                                                                            , day = day
                                                                            , hour = hour
                                                                            , minute = minute
                                                                            , second = 0
                                                                            , millisecond = 0
                                                                            }
                                                                    )
                                                        )
                                            )
                                )
                    )

        _ ->
            Nothing


toMonth : Int -> Month
toMonth month =
    case month of
        1 ->
            Jan

        2 ->
            Feb

        3 ->
            Mar

        4 ->
            Apr

        5 ->
            May

        6 ->
            Jun

        7 ->
            Jul

        8 ->
            Aug

        9 ->
            Sep

        10 ->
            Oct

        11 ->
            Nov

        12 ->
            Dec

        _ ->
            Jan


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
