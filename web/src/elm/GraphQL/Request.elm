module GraphQL.Request exposing (delete, item, items, save)

import GraphQL.Models.DiagramItem exposing (DiagramItem)
import GraphQL.Mutation as Mutation
import GraphQL.Query as Query
import Graphql.Http as Http
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Models.IdToken as IdToken exposing (IdToken)
import Task exposing (Task)
import TextUSM.InputObject exposing (InputItem)


graphQLUrl : String -> String
graphQLUrl url =
    url ++ "/graphql"


item : String -> Maybe IdToken -> String -> Task (Http.Error DiagramItem) DiagramItem
item url idToken id =
    Query.item id
        |> Http.queryRequest (graphQLUrl url)
        |> headers idToken
        |> Http.toTask


items : String -> Maybe IdToken -> ( Int, Int ) -> Bool -> Bool -> Task (Http.Error (List (Maybe DiagramItem))) (List (Maybe DiagramItem))
items url idToken ( offset, limit ) isBookmark isPublic =
    Query.items ( offset, limit ) isBookmark isPublic
        |> Http.queryRequest (graphQLUrl url)
        |> headers idToken
        |> Http.toTask


save : InputItem -> String -> Maybe IdToken -> Task (Http.Error DiagramItem) DiagramItem
save input url idToken =
    Mutation.save input
        |> Http.mutationRequest (graphQLUrl url)
        |> headers idToken
        |> Http.toTask


delete : String -> String -> Maybe IdToken -> Task (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem)
delete itemID url idToken =
    Mutation.delete itemID
        |> Http.mutationRequest (graphQLUrl url)
        |> headers idToken
        |> Http.toTask


headers : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
headers idToken =
    Http.withHeader "Authorization" (idToken |> Maybe.withDefault (IdToken.fromString "dummy") |> IdToken.unwrap)
