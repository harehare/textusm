module Utils.Date exposing (extractDateValues, intToMonth, millisToString, monthToInt, stringToPosix)

import List.Extra exposing (getAt)
import Time exposing (Month(..), Posix, Zone, toDay, toHour, toMinute, toMonth, toSecond, toYear, utc)
import Time.Extra exposing (Interval(..), Parts, partsToPosix)


millisToString : Zone -> Posix -> String
millisToString timezone posix =
    String.fromInt (toYear timezone posix)
        ++ "-"
        ++ (monthToInt (toMonth timezone posix) |> String.fromInt |> String.padLeft 2 '0')
        ++ "-"
        ++ (toDay timezone posix |> String.fromInt |> String.padLeft 2 '0')
        ++ " "
        ++ (toHour timezone posix |> String.fromInt |> String.padLeft 2 '0')
        ++ ":"
        ++ (toMinute timezone posix |> String.fromInt |> String.padLeft 2 '0')
        ++ ":"
        ++ (toSecond timezone posix |> String.fromInt |> String.padLeft 2 '0')


intToMonth : Int -> Month
intToMonth month =
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


stringToPosix : String -> Maybe Posix
stringToPosix str =
    let
        tokens =
            String.split "-" str

        year =
            getAt 0 tokens
                |> Maybe.andThen
                    (\v ->
                        if String.length v == 4 then
                            String.toInt v

                        else
                            Nothing
                    )

        month =
            getAt 1 tokens
                |> Maybe.andThen
                    (\v ->
                        if String.length v == 2 then
                            String.toInt v
                                |> Maybe.andThen
                                    (\vv ->
                                        Just <| intToMonth vv
                                    )

                        else
                            Nothing
                    )

        day =
            getAt 2 tokens
                |> Maybe.andThen
                    (\v ->
                        if String.length v == 2 then
                            String.toInt v

                        else
                            Nothing
                    )
    in
    year
        |> Maybe.andThen
            (\yearValue ->
                month
                    |> Maybe.andThen
                        (\monthValue ->
                            day
                                |> Maybe.andThen
                                    (\dayValue ->
                                        Just <| partsToPosix utc (Parts yearValue monthValue dayValue 0 0 0 0)
                                    )
                        )
            )


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


extractDateValues : String -> Maybe ( Posix, Posix )
extractDateValues s =
    let
        rangeValues =
            String.split " " (String.trim s)

        fromDate =
            getAt 0 rangeValues
                |> Maybe.andThen
                    (\vv ->
                        stringToPosix (String.trim vv)
                    )

        toDate =
            getAt 1 rangeValues
                |> Maybe.andThen
                    (\vv ->
                        stringToPosix (String.trim vv)
                    )
    in
    fromDate
        |> Maybe.andThen
            (\from ->
                toDate
                    |> Maybe.andThen
                        (\to ->
                            Just ( from, to )
                        )
            )
