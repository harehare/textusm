module Route exposing (Route(..), toRoute)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, parse, s, string)


type Route
    = Home
    | Share String String
    | View String


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Share (s "share" </> string </> string)
        , map View (s "view" </> string)
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault Home (parse parser url)
