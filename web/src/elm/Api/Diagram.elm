module Api.Diagram exposing (AddUserRequest, AddUserResponse, UpdateUserRequest, UpdateUserResponse, addUser, deleteUser, item, items, publicItems, remove, save, search, updateRole)

import Api.Api as Api
import Http exposing (Error(..))
import Json.Decode as D
import Json.Encode as E
import Models.DiagramItem as DiagramItem exposing (DiagramUser)
import Models.IdToken exposing (IdToken)
import Task exposing (Task)
import Url.Builder exposing (int, string)


type alias Query =
    String


type alias UserID =
    String


type alias PageNo =
    Int


type alias AddUserRequest =
    { diagramID : String
    , mail : String
    }


type alias UpdateUserRequest =
    { diagramID : String
    , role : String
    }


type alias AddUserResponse =
    DiagramUser


type alias UpdateUserResponse =
    { id : String
    , role : String
    }


items : Maybe IdToken -> PageNo -> String -> Task Http.Error (List DiagramItem.DiagramItem)
items idToken pageNo apiRoot =
    Api.get idToken apiRoot [ "diagram", "items" ] [ int "page" pageNo ] (Api.jsonResolver (D.list DiagramItem.decoder))


publicItems : Maybe IdToken -> PageNo -> String -> Task Http.Error (List DiagramItem.DiagramItem)
publicItems idToken pageNo apiRoot =
    Api.get idToken apiRoot [ "diagram", "items", "public" ] [ int "page" pageNo ] (Api.jsonResolver (D.list DiagramItem.decoder))


search : Maybe IdToken -> Query -> PageNo -> String -> Task Http.Error (List DiagramItem.DiagramItem)
search idToken query pageNo apiRoot =
    Api.get idToken apiRoot [ "diagram", "search" ] [ string "q" query, int "page" pageNo ] (Api.jsonResolver (D.list DiagramItem.decoder))


item : Maybe IdToken -> String -> DiagramItem.DiagramId -> Task Http.Error DiagramItem.DiagramItem
item idToken apiRoot diagramId =
    Api.get idToken apiRoot [ "diagram", "items", diagramId ] [] (Api.jsonResolver DiagramItem.decoder)


remove : Maybe IdToken -> String -> DiagramItem.DiagramId -> Task Http.Error ()
remove idToken apiRoot diagramId =
    Api.delete idToken apiRoot [ "diagram", "items", diagramId ] [] Api.emptyResolver


save : Maybe IdToken -> String -> DiagramItem.DiagramItem -> Task Http.Error ()
save idToken apiRoot diagram =
    Api.post idToken apiRoot [ "diagram", "save" ] (Http.jsonBody (DiagramItem.encoder diagram)) Api.emptyResolver


addUser : Maybe IdToken -> String -> AddUserRequest -> Task Http.Error AddUserResponse
addUser idToken apiRoot req =
    Api.post idToken apiRoot [ "diagram", "add", "user" ] (Http.jsonBody (addUserRequestEncoder req)) (Api.jsonResolver DiagramItem.userDecoder)


updateRole : Maybe IdToken -> String -> UserID -> UpdateUserRequest -> Task Http.Error UpdateUserResponse
updateRole idToken apiRoot userID req =
    Api.post idToken apiRoot [ "diagram", "update", "role", userID ] (Http.jsonBody (updateUserRequestEncoder req)) (Api.jsonResolver updateUserResponseDecoder)


deleteUser : Maybe IdToken -> String -> UserID -> String -> Task Http.Error ()
deleteUser idToken apiRoot userID diagramID =
    Api.delete idToken apiRoot [ "diagram", "delete", "user", userID, diagramID ] [] Api.emptyResolver



-- JSON


addUserRequestEncoder : AddUserRequest -> E.Value
addUserRequestEncoder req =
    E.object
        [ ( "diagram_id", E.string req.diagramID )
        , ( "mail", E.string req.mail )
        ]


updateUserRequestEncoder : UpdateUserRequest -> E.Value
updateUserRequestEncoder req =
    E.object
        [ ( "diagram_id", E.string req.diagramID )
        , ( "role", E.string req.role )
        ]


updateUserResponseDecoder : D.Decoder UpdateUserResponse
updateUserResponseDecoder =
    D.map2 UpdateUserResponse
        (D.field "id" D.string)
        (D.field "role" D.string)
