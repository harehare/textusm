module Models.User exposing (User, getIdToken)

import Models.IdToken as IdToken exposing (IdToken)


type alias User =
    { displayName : String
    , email : String
    , photoURL : String
    , idToken : String
    , id : String
    }


getIdToken : User -> IdToken
getIdToken user =
    IdToken.fromString user.idToken
