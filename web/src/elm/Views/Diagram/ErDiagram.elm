module Views.Diagram.ErDiagram exposing (view)

import Constants
import List.Extra exposing (getAt)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.ER.Item as ER exposing (Column, ColumnType(..), Index, IndexType(..), Relationship, Table)
import Models.Item as Item exposing (ItemType(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, transform)
import Utils
import Views.Diagram.Views as Views exposing (Position)


view : Model -> Svg Msg
view model =
    let
        erItems =
            ER.itemsToErDiagram model.items
                |> Debug.log "a"
    in
    g [] []


tableView : Settings -> Table -> Position -> Svg Msg
tableView settings table ( posX, posY ) =
    g [] []
