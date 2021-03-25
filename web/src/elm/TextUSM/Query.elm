-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module TextUSM.Query exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)
import TextUSM.InputObject
import TextUSM.Interface
import TextUSM.Object
import TextUSM.Scalar
import TextUSM.ScalarCodecs
import TextUSM.Union


type alias ItemOptionalArguments =
    { isPublic : OptionalArgument Bool }


type alias ItemRequiredArguments =
    { id : String }


{-|

  - id -
  - isPublic -

-}
item :
    (ItemOptionalArguments -> ItemOptionalArguments)
    -> ItemRequiredArguments
    -> SelectionSet decodesTo TextUSM.Object.Item
    -> SelectionSet decodesTo RootQuery
item fillInOptionals____ requiredArgs____ object____ =
    let
        filledInOptionals____ =
            fillInOptionals____ { isPublic = Absent }

        optionalArgs____ =
            [ Argument.optional "isPublic" filledInOptionals____.isPublic Encode.bool ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "item" (optionalArgs____ ++ [ Argument.required "id" requiredArgs____.id Encode.string ]) object____ identity


type alias ItemsOptionalArguments =
    { offset : OptionalArgument Int
    , limit : OptionalArgument Int
    , isBookmark : OptionalArgument Bool
    , isPublic : OptionalArgument Bool
    }


{-|

  - offset -
  - limit -
  - isBookmark -
  - isPublic -

-}
items :
    (ItemsOptionalArguments -> ItemsOptionalArguments)
    -> SelectionSet decodesTo TextUSM.Object.Item
    -> SelectionSet (List (Maybe decodesTo)) RootQuery
items fillInOptionals____ object____ =
    let
        filledInOptionals____ =
            fillInOptionals____ { offset = Absent, limit = Absent, isBookmark = Absent, isPublic = Absent }

        optionalArgs____ =
            [ Argument.optional "offset" filledInOptionals____.offset Encode.int, Argument.optional "limit" filledInOptionals____.limit Encode.int, Argument.optional "isBookmark" filledInOptionals____.isBookmark Encode.bool, Argument.optional "isPublic" filledInOptionals____.isPublic Encode.bool ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "items" optionalArgs____ object____ (identity >> Decode.nullable >> Decode.list)


type alias ShareItemRequiredArguments =
    { token : String }


{-|

  - token -

-}
shareItem :
    ShareItemRequiredArguments
    -> SelectionSet decodesTo TextUSM.Object.Item
    -> SelectionSet decodesTo RootQuery
shareItem requiredArgs____ object____ =
    Object.selectionForCompositeField "shareItem" [ Argument.required "token" requiredArgs____.token Encode.string ] object____ identity
