module Models.FileType exposing
    ( Extension
    , FileType(..)
    , ddl
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


png : FileType
png =
    Png ".png"


svg : FileType
svg =
    Svg ".svg"


pdf : FileType
pdf =
    Pdf ".pdf"


html : FileType
html =
    Html ".html"


ddl : FileType
ddl =
    Ddl ".sql"


markdown : FileType
markdown =
    Markdown ".md"


plainText : FileType
plainText =
    PlainText ".txt"


mermaid : FileType
mermaid =
    Mermaid ".mermaid"
