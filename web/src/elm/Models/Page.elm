module Models.Page exposing (Page(..))

import Graphql.Enum.Diagram as DiagramType
import Page.Tags as Tags
import Types.Size exposing (Size)


type Page
    = Main
    | New
    | Help
    | List
    | Tags Tags.Model
    | Settings
    | Embed DiagramType.Diagram String (Maybe Size)
    | NotFound
