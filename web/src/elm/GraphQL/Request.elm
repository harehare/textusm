module GraphQL.Request exposing (bookmark, delete, item, items, publicItem, save, share, shareItem)

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
    crossOrigin req.url [ "graphql" ] []


item : RequestInfo -> String -> Task (Http.Error DiagramItem) DiagramItem
item req id =
    Query.item id False
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


publicItem : RequestInfo -> String -> Task (Http.Error DiagramItem) DiagramItem
publicItem req id =
    Query.item id True
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


items : RequestInfo -> ( Int, Int ) -> { isPublic : Bool, isBookmark : Bool } -> Task (Http.Error (List (Maybe DiagramItem))) (List (Maybe DiagramItem))
items req ( offset, limit ) params =
    Query.items ( offset, limit ) params
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


shareItem : RequestInfo -> String -> Task (Http.Error DiagramItem) DiagramItem
shareItem req id =
    Query.shareItem id
        |> Http.queryRequest (graphQLUrl req)
        |> Http.toTask


save : RequestInfo -> InputItem -> Bool -> Task (Http.Error DiagramItem) DiagramItem
save req input isPublic =
    Mutation.save input isPublic
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


delete : RequestInfo -> String -> Bool -> Task (Http.Error String) String
delete req itemID isPublic =
    Mutation.delete itemID isPublic
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


bookmark : RequestInfo -> String -> Bool -> Task (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem)
bookmark req itemID isBookmark =
    Mutation.bookmark itemID isBookmark
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


share : RequestInfo -> String -> Task (Http.Error String) String
share req itemID =
    Mutation.share itemID
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


authHeaders : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
authHeaders idToken =
    Http.withHeader "Authorization" (idToken |> Maybe.withDefault (IdToken.fromString "dummy") |> IdToken.unwrap)
