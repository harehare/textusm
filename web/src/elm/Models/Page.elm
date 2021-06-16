module Models.Page exposing (Page(..))

import Data.Size exposing (Size)
import Page.Tags as Tags
import TextUSM.Enum.Diagram as DiagramType


type Page
    = Main
    | New
    | Help
    | List
    | Tags Tags.Model
    | Settings
    | Embed DiagramType.Diagram String (Maybe Size)
    | NotFound
