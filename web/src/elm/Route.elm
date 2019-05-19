module Route exposing (Route(..), toRoute)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, string)
import Url.Parser.Query as Query


type Route
    = Home
    | MindMap
    | Share String String
    | View String
    | CallbackTrello (Maybe String) (Maybe String)


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Share (s "share" </> string </> string)
        , map View (s "view" </> string)
        , map CallbackTrello (s "callback" <?> Query.string "oauth_token" <?> Query.string "oauth_verifier")
        , map MindMap (s "mindmap")
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault Home (parse parser url)
