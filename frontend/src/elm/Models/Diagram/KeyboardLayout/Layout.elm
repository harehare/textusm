module Models.Diagram.KeyboardLayout.Layout exposing (Layout(..), fromString)


type Layout
    = RowStaggered
    | ColumnStaggered
    | OrthoLinear


fromString : String -> Layout
fromString layout =
    case layout of
        "column-staggered" ->
            ColumnStaggered

        "ortho-linear" ->
            OrthoLinear

        _ ->
            RowStaggered
