module Route exposing (Route(..), toRoute)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, string)
import Url.Parser.Query as Query


type Route
    = Home
    | BusinessModelCanvas
    | OpportunityCanvas
    | UserStoryMap
    | List
    | Settings
    | Help
    | Share String String String
    | UsmView String
    | View String String
    | CallbackTrello (Maybe String) (Maybe String)


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Share (s "share" </> string </> string </> string)
        , map UsmView (s "view" </> string)
        , map View (s "view" </> string </> string)
        , map CallbackTrello (s "callback" <?> Query.string "oauth_token" <?> Query.string "oauth_verifier")
        , map BusinessModelCanvas (s "bmc")
        , map OpportunityCanvas (s "opc")
        , map UserStoryMap (s "usm")
        , map List (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault Home (parse parser url)
