module GraphQL.Request exposing (bookmark, delete, item, items, save)

import Data.DiagramItem exposing (DiagramItem)
import Data.IdToken as IdToken exposing (IdToken)
import GraphQL.Mutation as Mutation
import GraphQL.Query as Query
import Graphql.Http as Http
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Task exposing (Task)
import TextUSM.InputObject exposing (InputItem)
import Url.Builder exposing (crossOrigin)


type alias RequestInfo =
    { idToken : Maybe IdToken
    , url : String
    }


graphQLUrl : RequestInfo -> String
graphQLUrl req =
    crossOrigin req.url [ "/graphql" ] []


item : RequestInfo -> String -> Task (Http.Error DiagramItem) DiagramItem
item req id =
    Query.item id
        |> Http.queryRequest (graphQLUrl req)
        |> headers req.idToken
        |> Http.toTask


items : RequestInfo -> ( Int, Int ) -> Bool -> Bool -> Task (Http.Error (List (Maybe DiagramItem))) (List (Maybe DiagramItem))
items req ( offset, limit ) isBookmark isPublic =
    Query.items ( offset, limit ) isBookmark isPublic
        |> Http.queryRequest (graphQLUrl req)
        |> headers req.idToken
        |> Http.toTask


save : RequestInfo -> InputItem -> Task (Http.Error DiagramItem) DiagramItem
save req input =
    Mutation.save input
        |> Http.mutationRequest (graphQLUrl req)
        |> headers req.idToken
        |> Http.toTask


delete : RequestInfo -> String -> Task (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem)
delete req itemID =
    Mutation.delete itemID
        |> Http.mutationRequest (graphQLUrl req)
        |> headers req.idToken
        |> Http.toTask


bookmark : RequestInfo -> String -> Bool -> Task (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem)
bookmark req itemID isBookmark =
    Mutation.bookmark itemID isBookmark
        |> Http.mutationRequest (graphQLUrl req)
        |> headers req.idToken
        |> Http.toTask


headers : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
headers idToken =
    Http.withHeader "Authorization" (idToken |> Maybe.withDefault (IdToken.fromString "dummy") |> IdToken.unwrap)
