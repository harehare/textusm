module Style.Color exposing (bgAccent, bgActivity, bgDefault, bgDisabled, bgLight, bgMain, bgTransparent, borderColor, darkTextColor, disabledColor, errorColor, lightBackgroundColor, textAccent, textActivity, textColor, textComment, textDark, textError, textLight, textMain, textSecondaryColor)

import Css exposing (Color, backgroundColor, color, hex, transparent)


textColor : Css.Style
textColor =
    color <| hex "#EBEBEF"


textActivity : Css.Style
textActivity =
    color activityColor


textLight : Css.Style
textLight =
    color lightBackgroundColor


textSecondaryColor : Css.Style
textSecondaryColor =
    color <| hex "#b9b9b9"


textAccent : Css.Style
textAccent =
    color accentColor


textComment : Css.Style
textComment =
    color <| hex "#008800"


textMain : Css.Style
textMain =
    color <| hex "#273037"


textDark : Css.Style
textDark =
    color darkTextColor


textError : Css.Style
textError =
    color errorColor


bgMain : Css.Style
bgMain =
    backgroundColor <| hex "#273037"


bgDefault : Css.Style
bgDefault =
    backgroundColor <| hex "#323d46"


bgLight : Css.Style
bgLight =
    backgroundColor lightBackgroundColor


bgTransparent : Css.Style
bgTransparent =
    backgroundColor <| transparent


bgAccent : Css.Style
bgAccent =
    backgroundColor accentColor


bgDisabled : Css.Style
bgDisabled =
    backgroundColor disabledColor


bgActivity : Css.Style
bgActivity =
    backgroundColor activityColor


accentColor : Color
accentColor =
    hex "#3e9bcd"


darkTextColor : Color
darkTextColor =
    hex "#555555"


borderColor : Color
borderColor =
    hex "#fefefe"


disabledColor : Color
disabledColor =
    hex "#dddddd"


errorColor : Color
errorColor =
    hex "#f55c64"


activityColor : Color
activityColor =
    hex "#266b9a"


lightBackgroundColor : Color
lightBackgroundColor =
    hex "#fefefe"
