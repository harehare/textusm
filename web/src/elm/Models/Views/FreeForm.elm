module Models.Views.FreeForm exposing (..)

import Data.Color as Color exposing (Color)
import Data.Item as Item exposing (Item)


type CardGroup
    = CardGroup Color (List Item)


type FreeForm
    = FreeForm CardGroup
