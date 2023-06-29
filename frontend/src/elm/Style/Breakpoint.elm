module Style.Breakpoint exposing (Breakpoint, large, small, style)

import Css
import Css.Media as Media exposing (withMedia)


type Breakpoint
    = Small (List Css.Style)
    | Large (List Css.Style)


large : List Css.Style -> Breakpoint
large s =
    Large s


small : List Css.Style -> Breakpoint
small s =
    Small s


style : List Css.Style -> List Breakpoint -> Css.Style
style base responsive =
    Css.batch <|
        Css.batch base
            :: List.map
                (\r ->
                    case r of
                        Small s ->
                            withMedia [ Media.all [ Media.minWidth (Css.px 640) ] ] s

                        Large s ->
                            withMedia [ Media.all [ Media.minWidth (Css.px 1024) ] ] s
                )
                responsive
