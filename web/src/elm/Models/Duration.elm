module Models.Duration exposing (Duration, seconds, toInt)


type Duration
    = Duration Int


seconds : Int -> Duration
seconds sec =
    if sec < 0 then
        Duration 0

    else
        Duration sec


toInt : Duration -> Int
toInt (Duration s) =
    s
