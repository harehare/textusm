module Models.FileType exposing
    ( Extension
    , FileType(..)
    , ddl
    , extension
    , html
    , markdown
    , mermaid
    , pdf
    , plainText
    , png
    , svg
    , toString
    )


type alias Extension =
    String


type FileType
    = Png Extension
    | Svg Extension
    | Pdf Extension
    | Html Extension
    | Ddl Extension
    | Markdown Extension
    | PlainText Extension
    | Mermaid Extension


ddl : FileType
ddl =
    Ddl ".sql"


extension : FileType -> Extension
extension fileType =
    case fileType of
        Png ex ->
            ex

        Svg ex ->
            ex

        Pdf ex ->
            ex

        Html ex ->
            ex

        Ddl ex ->
            ex

        Markdown ex ->
            ex

        PlainText ex ->
            ex

        Mermaid ex ->
            ex


html : FileType
html =
    Html ".html"


markdown : FileType
markdown =
    Markdown ".md"


mermaid : FileType
mermaid =
    Mermaid ".mermaid"


pdf : FileType
pdf =
    Pdf ".pdf"


plainText : FileType
plainText =
    PlainText ".txt"


png : FileType
png =
    Png ".png"


svg : FileType
svg =
    Svg ".svg"


toString : FileType -> String
toString fileType =
    case fileType of
        Png _ ->
            "PNG"

        Svg _ ->
            "SVG"

        Pdf _ ->
            "PDF"

        Html _ ->
            "HTML"

        Ddl _ ->
            "DDL"

        Markdown _ ->
            "MARKDOWN"

        PlainText _ ->
            "TEXT"

        Mermaid _ ->
            "Mermaid"
