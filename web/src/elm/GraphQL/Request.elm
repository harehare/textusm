module GraphQL.Request exposing (delete, item, items, save)

import GraphQL.Models exposing (Item)
import GraphQL.Mutation as Mutation
import GraphQL.Query as Query
import Graphql.Http as Http
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Models.IdToken as IdToken exposing (IdToken)
import Task exposing (Task)
import TextUSM.InputObject exposing (InputItem)


item : String -> Maybe IdToken -> String -> Task (Http.Error Item) Item
item url idToken id =
    Query.item id
        |> Http.queryRequest url
        |> headers idToken
        |> Http.toTask


items : String -> Maybe IdToken -> ( Int, Int ) -> Bool -> Bool -> Task (Http.Error (List (Maybe Item))) (List (Maybe Item))
items url idToken ( offset, limit ) isBookmark isPublic =
    Query.items ( offset, limit ) isBookmark isPublic
        |> Http.queryRequest url
        |> headers idToken
        |> Http.toTask


save : InputItem -> String -> Maybe IdToken -> Task (Http.Error Item) Item
save input url idToken =
    Mutation.save input
        |> Http.mutationRequest url
        |> headers idToken
        |> Http.toTask


delete : String -> String -> Maybe IdToken -> Task (Http.Error (Maybe Item)) (Maybe Item)
delete itemID url idToken =
    Mutation.delete itemID
        |> Http.mutationRequest url
        |> headers idToken
        |> Http.toTask


headers : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
headers idToken =
    Http.withHeader "Authorization" ("Bearer " ++ (idToken |> Maybe.withDefault (IdToken.fromString "dummy") |> IdToken.unwrap))
