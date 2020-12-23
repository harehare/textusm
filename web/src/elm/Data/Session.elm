module Data.Session exposing (Session, User, getIdToken, getUser, guest, isGuest, isSignedIn, signIn, updateIdToken)

import Data.IdToken as IdToken exposing (IdToken)


type Session
    = SignedIn User
    | Guest


type alias User =
    { displayName : String
    , email : String
    , photoURL : String
    , idToken : String
    , id : String
    }


isGuest : Session -> Bool
isGuest session =
    case session of
        SignedIn _ ->
            False

        Guest ->
            True


isSignedIn : Session -> Bool
isSignedIn session =
    case session of
        SignedIn _ ->
            True

        Guest ->
            False


guest : Session
guest =
    Guest


signIn : User -> Session
signIn user =
    SignedIn user


getUser : Session -> Maybe User
getUser session =
    case session of
        SignedIn u ->
            Just u

        Guest ->
            Nothing


getIdToken : Session -> Maybe IdToken
getIdToken session =
    case session of
        SignedIn user ->
            Just <| IdToken.fromString user.idToken

        Guest ->
            Nothing


updateIdToken : Session -> IdToken -> Session
updateIdToken session idToken =
    case session of
        SignedIn user ->
            SignedIn { user | idToken = IdToken.unwrap idToken }

        Guest ->
            Guest
