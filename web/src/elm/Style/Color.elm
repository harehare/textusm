module Style.Color exposing (bgAccent, bgActivity, bgDefault, bgDisabled, bgLight, bgMain, bgTransparent, borderColor, darkTextColor, disabledColor, errorColor, lightBackgroundColor, textAccent, textActivity, textColor, textComment, textDark, textError, textLight, textMain, textSecondaryColor)

import Css exposing (Color, backgroundColor, color, hex, transparent)


bgAccent : Css.Style
bgAccent =
    backgroundColor accentColor


bgActivity : Css.Style
bgActivity =
    backgroundColor activityColor


bgDefault : Css.Style
bgDefault =
    backgroundColor <| hex "#323d46"


bgDisabled : Css.Style
bgDisabled =
    backgroundColor disabledColor


bgLight : Css.Style
bgLight =
    backgroundColor lightBackgroundColor


bgMain : Css.Style
bgMain =
    backgroundColor <| hex "#273037"


bgTransparent : Css.Style
bgTransparent =
    backgroundColor <| transparent


borderColor : Color
borderColor =
    hex "#fefefe"


darkTextColor : Color
darkTextColor =
    hex "#555555"


disabledColor : Color
disabledColor =
    hex "#dddddd"


errorColor : Color
errorColor =
    hex "#f55c64"


lightBackgroundColor : Color
lightBackgroundColor =
    hex "#fefefe"


textAccent : Css.Style
textAccent =
    color accentColor


textActivity : Css.Style
textActivity =
    color activityColor


textColor : Css.Style
textColor =
    color <| hex "#EBEBEF"


textComment : Css.Style
textComment =
    color <| hex "#008800"


textDark : Css.Style
textDark =
    color darkTextColor


textError : Css.Style
textError =
    color errorColor


textLight : Css.Style
textLight =
    color lightBackgroundColor


textMain : Css.Style
textMain =
    color <| hex "#273037"


textSecondaryColor : Css.Style
textSecondaryColor =
    color <| hex "#b9b9b9"


accentColor : Color
accentColor =
    hex "#3e9bcd"


activityColor : Color
activityColor =
    hex "#266b9a"
