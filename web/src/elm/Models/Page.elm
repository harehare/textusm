module Models.Page exposing (Page(..))

import Graphql.Enum.Diagram as DiagramType
import Types.Size exposing (Size)


type Page
    = Main
    | New
    | Help
    | List
    | Settings
    | Embed DiagramType.Diagram String (Maybe Size)
    | NotFound
