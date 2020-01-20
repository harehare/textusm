module GraphQL.Models exposing (Item)

import Graphql.OptionalArgument exposing (OptionalArgument(..))
import TextUSM.Enum.Diagram
import TextUSM.Scalar exposing (Id(..))
import TextUSM.ScalarCodecs


type alias Item =
    { id : TextUSM.ScalarCodecs.Id
    , text : String
    , diagram : TextUSM.Enum.Diagram.Diagram
    , title : String
    , thumbnail : Maybe String
    , isPublic : Bool
    , isBookmark : Bool
    , createdAt : TextUSM.ScalarCodecs.Time
    , updatedAt : TextUSM.ScalarCodecs.Time
    }
