module Api.Diagram exposing (item, items, publicItems, remove, save, search)

import Api.Api as Api
import Http exposing (Error(..))
import Json.Decode as D
import Models.DiagramItem as DiagramItem
import Models.IdToken as IdToken exposing (IdToken)
import Task exposing (Task)
import Url.Builder exposing (int, string)


type alias Query =
    String


type alias PageNo =
    Int


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
