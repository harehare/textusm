module Page.Settings exposing (Model, Msg, init, update, view)

import Data.Color as Color exposing (colors)
import Html exposing (Html, div, input, label, text)
import Html.Attributes exposing (checked, class, style, type_)
import Html.Events exposing (onClick)
import Maybe.Extra exposing (isNothing)
import Settings exposing (Settings, defaultEditorSettings, settingsOfActivityBackgroundColor, settingsOfActivityColor, settingsOfBackgroundColor, settingsOfFontSize, settingsOfHeight, settingsOfLabelColor, settingsOfLineColor, settingsOfShowLineNumber, settingsOfStoryBackgroundColor, settingsOfStoryColor, settingsOfTaskBackgroundColor, settingsOfTaskColor, settingsOfTextColor, settingsOfWidth, settingsOfWordWrap, settingsOfZoomControl)
import Views.DropDownList as DropDownList exposing (DropDownValue)


baseColorItems : List { name : String, value : DropDownValue }
baseColorItems =
    List.map
        (\color ->
            { name = Color.name color, value = DropDownList.colorValue <| Color.toString color }
        )
        colors


baseSizeItems : List { name : String, value : DropDownValue }
baseSizeItems =
    List.range 0 100
        |> List.map
            (\i ->
                { name = String.fromInt <| 50 + i * 5, value = DropDownList.stringValue <| String.fromInt <| 50 + i * 5 }
            )


fontSizeItems : List { name : String, value : DropDownValue }
fontSizeItems =
    [ { name = "8", value = DropDownList.stringValue "8" }
    , { name = "9", value = DropDownList.stringValue "9" }
    , { name = "10", value = DropDownList.stringValue "10" }
    , { name = "11", value = DropDownList.stringValue "11" }
    , { name = "12", value = DropDownList.stringValue "12" }
    , { name = "14", value = DropDownList.stringValue "14" }
    , { name = "18", value = DropDownList.stringValue "18" }
    , { name = "24", value = DropDownList.stringValue "24" }
    , { name = "32", value = DropDownList.stringValue "32" }
    , { name = "40", value = DropDownList.stringValue "40" }
    ]


fontFamilyItems : List { name : String, value : DropDownValue }
fontFamilyItems =
    [ { name = "ABeeZee", value = DropDownList.stringValue "ABeeZee" }
    , { name = "Abel", value = DropDownList.stringValue "Abel" }
    , { name = "Abhaya Libre", value = DropDownList.stringValue "Abhaya Libre" }
    , { name = "Abril Fatface", value = DropDownList.stringValue "Abril Fatface" }
    , { name = "Aclonica", value = DropDownList.stringValue "Aclonica" }
    , { name = "Acme", value = DropDownList.stringValue "Acme" }
    , { name = "Actor", value = DropDownList.stringValue "Actor" }
    , { name = "Adamina", value = DropDownList.stringValue "Adamina" }
    , { name = "Advent Pro", value = DropDownList.stringValue "Advent Pro" }
    , { name = "Aguafina Script", value = DropDownList.stringValue "Aguafina Script" }
    , { name = "Akronim", value = DropDownList.stringValue "Akronim" }
    , { name = "Aladin", value = DropDownList.stringValue "Aladin" }
    , { name = "Aldrich", value = DropDownList.stringValue "Aldrich" }
    , { name = "Alef", value = DropDownList.stringValue "Alef" }
    , { name = "Alegreya", value = DropDownList.stringValue "Alegreya" }
    , { name = "Alegreya Sans", value = DropDownList.stringValue "Alegreya Sans" }
    , { name = "Alegreya Sans SC", value = DropDownList.stringValue "Alegreya Sans SC" }
    , { name = "Alegreya SC", value = DropDownList.stringValue "Alegreya SC" }
    , { name = "Aleo", value = DropDownList.stringValue "Aleo" }
    , { name = "Alex Brush", value = DropDownList.stringValue "Alex Brush" }
    , { name = "Alfa Slab One", value = DropDownList.stringValue "Alfa Slab One" }
    , { name = "Alice", value = DropDownList.stringValue "Alice" }
    , { name = "Alike", value = DropDownList.stringValue "Alike" }
    , { name = "Alike Angular", value = DropDownList.stringValue "Alike Angular" }
    , { name = "Allan", value = DropDownList.stringValue "Allan" }
    , { name = "Allerta", value = DropDownList.stringValue "Allerta" }
    , { name = "Allerta Stencil", value = DropDownList.stringValue "Allerta Stencil" }
    , { name = "Allura", value = DropDownList.stringValue "Allura" }
    , { name = "Almarai", value = DropDownList.stringValue "Almarai" }
    , { name = "Almendra", value = DropDownList.stringValue "Almendra" }
    , { name = "Almendra Display", value = DropDownList.stringValue "Almendra Display" }
    , { name = "Almendra SC", value = DropDownList.stringValue "Almendra SC" }
    , { name = "Amarante", value = DropDownList.stringValue "Amarante" }
    , { name = "Amaranth", value = DropDownList.stringValue "Amaranth" }
    , { name = "Amatic SC", value = DropDownList.stringValue "Amatic SC" }
    , { name = "Amethysta", value = DropDownList.stringValue "Amethysta" }
    , { name = "Amiko", value = DropDownList.stringValue "Amiko" }
    , { name = "Amiri", value = DropDownList.stringValue "Amiri" }
    , { name = "Amita", value = DropDownList.stringValue "Amita" }
    , { name = "Anaheim", value = DropDownList.stringValue "Anaheim" }
    , { name = "Andada", value = DropDownList.stringValue "Andada" }
    , { name = "Andika", value = DropDownList.stringValue "Andika" }
    , { name = "Angkor", value = DropDownList.stringValue "Angkor" }
    , { name = "Annie Use Your Telescope", value = DropDownList.stringValue "Annie Use Your Telescope" }
    , { name = "Anonymous Pro", value = DropDownList.stringValue "Anonymous Pro" }
    , { name = "Antic", value = DropDownList.stringValue "Antic" }
    , { name = "Antic Didone", value = DropDownList.stringValue "Antic Didone" }
    , { name = "Antic Slab", value = DropDownList.stringValue "Antic Slab" }
    , { name = "Anton", value = DropDownList.stringValue "Anton" }
    , { name = "Arapey", value = DropDownList.stringValue "Arapey" }
    , { name = "Arbutus", value = DropDownList.stringValue "Arbutus" }
    , { name = "Arbutus Slab", value = DropDownList.stringValue "Arbutus Slab" }
    , { name = "Architects Daughter", value = DropDownList.stringValue "Architects Daughter" }
    , { name = "Archivo", value = DropDownList.stringValue "Archivo" }
    , { name = "Archivo Black", value = DropDownList.stringValue "Archivo Black" }
    , { name = "Archivo Narrow", value = DropDownList.stringValue "Archivo Narrow" }
    , { name = "Aref Ruqaa", value = DropDownList.stringValue "Aref Ruqaa" }
    , { name = "Arima Madurai", value = DropDownList.stringValue "Arima Madurai" }
    , { name = "Arimo", value = DropDownList.stringValue "Arimo" }
    , { name = "Arizonia", value = DropDownList.stringValue "Arizonia" }
    , { name = "Armata", value = DropDownList.stringValue "Armata" }
    , { name = "Arsenal", value = DropDownList.stringValue "Arsenal" }
    , { name = "Artifika", value = DropDownList.stringValue "Artifika" }
    , { name = "Arvo", value = DropDownList.stringValue "Arvo" }
    , { name = "Arya", value = DropDownList.stringValue "Arya" }
    , { name = "Asap", value = DropDownList.stringValue "Asap" }
    , { name = "Asap Condensed", value = DropDownList.stringValue "Asap Condensed" }
    , { name = "Asar", value = DropDownList.stringValue "Asar" }
    , { name = "Asset", value = DropDownList.stringValue "Asset" }
    , { name = "Assistant", value = DropDownList.stringValue "Assistant" }
    , { name = "Astloch", value = DropDownList.stringValue "Astloch" }
    , { name = "Asul", value = DropDownList.stringValue "Asul" }
    , { name = "Athiti", value = DropDownList.stringValue "Athiti" }
    , { name = "Atma", value = DropDownList.stringValue "Atma" }
    , { name = "Atomic Age", value = DropDownList.stringValue "Atomic Age" }
    , { name = "Aubrey", value = DropDownList.stringValue "Aubrey" }
    , { name = "Audiowide", value = DropDownList.stringValue "Audiowide" }
    , { name = "Autour One", value = DropDownList.stringValue "Autour One" }
    , { name = "Average", value = DropDownList.stringValue "Average" }
    , { name = "Average Sans", value = DropDownList.stringValue "Average Sans" }
    , { name = "Averia Gruesa Libre", value = DropDownList.stringValue "Averia Gruesa Libre" }
    , { name = "Averia Libre", value = DropDownList.stringValue "Averia Libre" }
    , { name = "Averia Sans Libre", value = DropDownList.stringValue "Averia Sans Libre" }
    , { name = "Averia Serif Libre", value = DropDownList.stringValue "Averia Serif Libre" }
    , { name = "B612", value = DropDownList.stringValue "B612" }
    , { name = "B612 Mono", value = DropDownList.stringValue "B612 Mono" }
    , { name = "Bad Script", value = DropDownList.stringValue "Bad Script" }
    , { name = "Bahiana", value = DropDownList.stringValue "Bahiana" }
    , { name = "Bahianita", value = DropDownList.stringValue "Bahianita" }
    , { name = "Bai Jamjuree", value = DropDownList.stringValue "Bai Jamjuree" }
    , { name = "Baloo", value = DropDownList.stringValue "Baloo" }
    , { name = "Baloo Bhai", value = DropDownList.stringValue "Baloo Bhai" }
    , { name = "Baloo Bhaijaan", value = DropDownList.stringValue "Baloo Bhaijaan" }
    , { name = "Baloo Bhaina", value = DropDownList.stringValue "Baloo Bhaina" }
    , { name = "Baloo Chettan", value = DropDownList.stringValue "Baloo Chettan" }
    , { name = "Baloo Da", value = DropDownList.stringValue "Baloo Da" }
    , { name = "Baloo Paaji", value = DropDownList.stringValue "Baloo Paaji" }
    , { name = "Baloo Tamma", value = DropDownList.stringValue "Baloo Tamma" }
    , { name = "Baloo Tammudu", value = DropDownList.stringValue "Baloo Tammudu" }
    , { name = "Baloo Thambi", value = DropDownList.stringValue "Baloo Thambi" }
    , { name = "Balthazar", value = DropDownList.stringValue "Balthazar" }
    , { name = "Bangers", value = DropDownList.stringValue "Bangers" }
    , { name = "Barlow", value = DropDownList.stringValue "Barlow" }
    , { name = "Barlow Condensed", value = DropDownList.stringValue "Barlow Condensed" }
    , { name = "Barlow Semi Condensed", value = DropDownList.stringValue "Barlow Semi Condensed" }
    , { name = "Barriecito", value = DropDownList.stringValue "Barriecito" }
    , { name = "Barrio", value = DropDownList.stringValue "Barrio" }
    , { name = "Basic", value = DropDownList.stringValue "Basic" }
    , { name = "Battambang", value = DropDownList.stringValue "Battambang" }
    , { name = "Baumans", value = DropDownList.stringValue "Baumans" }
    , { name = "Bayon", value = DropDownList.stringValue "Bayon" }
    , { name = "Be Vietnam", value = DropDownList.stringValue "Be Vietnam" }
    , { name = "Belgrano", value = DropDownList.stringValue "Belgrano" }
    , { name = "Bellefair", value = DropDownList.stringValue "Bellefair" }
    , { name = "Belleza", value = DropDownList.stringValue "Belleza" }
    , { name = "BenchNine", value = DropDownList.stringValue "BenchNine" }
    , { name = "Bentham", value = DropDownList.stringValue "Bentham" }
    , { name = "Berkshire Swash", value = DropDownList.stringValue "Berkshire Swash" }
    , { name = "Beth Ellen", value = DropDownList.stringValue "Beth Ellen" }
    , { name = "Bevan", value = DropDownList.stringValue "Bevan" }
    , { name = "Big Shoulders Display", value = DropDownList.stringValue "Big Shoulders Display" }
    , { name = "Big Shoulders Text", value = DropDownList.stringValue "Big Shoulders Text" }
    , { name = "Bigelow Rules", value = DropDownList.stringValue "Bigelow Rules" }
    , { name = "Bigshot One", value = DropDownList.stringValue "Bigshot One" }
    , { name = "Bilbo", value = DropDownList.stringValue "Bilbo" }
    , { name = "Bilbo Swash Caps", value = DropDownList.stringValue "Bilbo Swash Caps" }
    , { name = "BioRhyme", value = DropDownList.stringValue "BioRhyme" }
    , { name = "BioRhyme Expanded", value = DropDownList.stringValue "BioRhyme Expanded" }
    , { name = "Biryani", value = DropDownList.stringValue "Biryani" }
    , { name = "Bitter", value = DropDownList.stringValue "Bitter" }
    , { name = "Black And White Picture", value = DropDownList.stringValue "Black And White Picture" }
    , { name = "Black Han Sans", value = DropDownList.stringValue "Black Han Sans" }
    , { name = "Black Ops One", value = DropDownList.stringValue "Black Ops One" }
    , { name = "Blinker", value = DropDownList.stringValue "Blinker" }
    , { name = "Bokor", value = DropDownList.stringValue "Bokor" }
    , { name = "Bonbon", value = DropDownList.stringValue "Bonbon" }
    , { name = "Boogaloo", value = DropDownList.stringValue "Boogaloo" }
    , { name = "Bowlby One", value = DropDownList.stringValue "Bowlby One" }
    , { name = "Bowlby One SC", value = DropDownList.stringValue "Bowlby One SC" }
    , { name = "Brawler", value = DropDownList.stringValue "Brawler" }
    , { name = "Bree Serif", value = DropDownList.stringValue "Bree Serif" }
    , { name = "Bubblegum Sans", value = DropDownList.stringValue "Bubblegum Sans" }
    , { name = "Bubbler One", value = DropDownList.stringValue "Bubbler One" }
    , { name = "Buda", value = DropDownList.stringValue "Buda" }
    , { name = "Buenard", value = DropDownList.stringValue "Buenard" }
    , { name = "Bungee", value = DropDownList.stringValue "Bungee" }
    , { name = "Bungee Hairline", value = DropDownList.stringValue "Bungee Hairline" }
    , { name = "Bungee Inline", value = DropDownList.stringValue "Bungee Inline" }
    , { name = "Bungee Outline", value = DropDownList.stringValue "Bungee Outline" }
    , { name = "Bungee Shade", value = DropDownList.stringValue "Bungee Shade" }
    , { name = "Butcherman", value = DropDownList.stringValue "Butcherman" }
    , { name = "Butterfly Kids", value = DropDownList.stringValue "Butterfly Kids" }
    , { name = "Cabin", value = DropDownList.stringValue "Cabin" }
    , { name = "Cabin Condensed", value = DropDownList.stringValue "Cabin Condensed" }
    , { name = "Cabin Sketch", value = DropDownList.stringValue "Cabin Sketch" }
    , { name = "Caesar Dressing", value = DropDownList.stringValue "Caesar Dressing" }
    , { name = "Cagliostro", value = DropDownList.stringValue "Cagliostro" }
    , { name = "Cairo", value = DropDownList.stringValue "Cairo" }
    , { name = "Calligraffitti", value = DropDownList.stringValue "Calligraffitti" }
    , { name = "Cambay", value = DropDownList.stringValue "Cambay" }
    , { name = "Cambo", value = DropDownList.stringValue "Cambo" }
    , { name = "Candal", value = DropDownList.stringValue "Candal" }
    , { name = "Cantarell", value = DropDownList.stringValue "Cantarell" }
    , { name = "Cantata One", value = DropDownList.stringValue "Cantata One" }
    , { name = "Cantora One", value = DropDownList.stringValue "Cantora One" }
    , { name = "Capriola", value = DropDownList.stringValue "Capriola" }
    , { name = "Cardo", value = DropDownList.stringValue "Cardo" }
    , { name = "Carme", value = DropDownList.stringValue "Carme" }
    , { name = "Carrois Gothic", value = DropDownList.stringValue "Carrois Gothic" }
    , { name = "Carrois Gothic SC", value = DropDownList.stringValue "Carrois Gothic SC" }
    , { name = "Carter One", value = DropDownList.stringValue "Carter One" }
    , { name = "Catamaran", value = DropDownList.stringValue "Catamaran" }
    , { name = "Caudex", value = DropDownList.stringValue "Caudex" }
    , { name = "Caveat", value = DropDownList.stringValue "Caveat" }
    , { name = "Caveat Brush", value = DropDownList.stringValue "Caveat Brush" }
    , { name = "Cedarville Cursive", value = DropDownList.stringValue "Cedarville Cursive" }
    , { name = "Ceviche One", value = DropDownList.stringValue "Ceviche One" }
    , { name = "Chakra Petch", value = DropDownList.stringValue "Chakra Petch" }
    , { name = "Changa", value = DropDownList.stringValue "Changa" }
    , { name = "Changa One", value = DropDownList.stringValue "Changa One" }
    , { name = "Chango", value = DropDownList.stringValue "Chango" }
    , { name = "Charm", value = DropDownList.stringValue "Charm" }
    , { name = "Charmonman", value = DropDownList.stringValue "Charmonman" }
    , { name = "Chathura", value = DropDownList.stringValue "Chathura" }
    , { name = "Chau Philomene One", value = DropDownList.stringValue "Chau Philomene One" }
    , { name = "Chela One", value = DropDownList.stringValue "Chela One" }
    , { name = "Chelsea Market", value = DropDownList.stringValue "Chelsea Market" }
    , { name = "Chenla", value = DropDownList.stringValue "Chenla" }
    , { name = "Cherry Cream Soda", value = DropDownList.stringValue "Cherry Cream Soda" }
    , { name = "Cherry Swash", value = DropDownList.stringValue "Cherry Swash" }
    , { name = "Chewy", value = DropDownList.stringValue "Chewy" }
    , { name = "Chicle", value = DropDownList.stringValue "Chicle" }
    , { name = "Chilanka", value = DropDownList.stringValue "Chilanka" }
    , { name = "Chivo", value = DropDownList.stringValue "Chivo" }
    , { name = "Chonburi", value = DropDownList.stringValue "Chonburi" }
    , { name = "Cinzel", value = DropDownList.stringValue "Cinzel" }
    , { name = "Cinzel Decorative", value = DropDownList.stringValue "Cinzel Decorative" }
    , { name = "Clicker Script", value = DropDownList.stringValue "Clicker Script" }
    , { name = "Coda", value = DropDownList.stringValue "Coda" }
    , { name = "Coda Caption", value = DropDownList.stringValue "Coda Caption" }
    , { name = "Codystar", value = DropDownList.stringValue "Codystar" }
    , { name = "Coiny", value = DropDownList.stringValue "Coiny" }
    , { name = "Combo", value = DropDownList.stringValue "Combo" }
    , { name = "Comfortaa", value = DropDownList.stringValue "Comfortaa" }
    , { name = "Coming Soon", value = DropDownList.stringValue "Coming Soon" }
    , { name = "Concert One", value = DropDownList.stringValue "Concert One" }
    , { name = "Condiment", value = DropDownList.stringValue "Condiment" }
    , { name = "Content", value = DropDownList.stringValue "Content" }
    , { name = "Contrail One", value = DropDownList.stringValue "Contrail One" }
    , { name = "Convergence", value = DropDownList.stringValue "Convergence" }
    , { name = "Cookie", value = DropDownList.stringValue "Cookie" }
    , { name = "Copse", value = DropDownList.stringValue "Copse" }
    , { name = "Corben", value = DropDownList.stringValue "Corben" }
    , { name = "Cormorant", value = DropDownList.stringValue "Cormorant" }
    , { name = "Cormorant Garamond", value = DropDownList.stringValue "Cormorant Garamond" }
    , { name = "Cormorant Infant", value = DropDownList.stringValue "Cormorant Infant" }
    , { name = "Cormorant SC", value = DropDownList.stringValue "Cormorant SC" }
    , { name = "Cormorant Unicase", value = DropDownList.stringValue "Cormorant Unicase" }
    , { name = "Cormorant Upright", value = DropDownList.stringValue "Cormorant Upright" }
    , { name = "Courgette", value = DropDownList.stringValue "Courgette" }
    , { name = "Cousine", value = DropDownList.stringValue "Cousine" }
    , { name = "Coustard", value = DropDownList.stringValue "Coustard" }
    , { name = "Covered By Your Grace", value = DropDownList.stringValue "Covered By Your Grace" }
    , { name = "Crafty Girls", value = DropDownList.stringValue "Crafty Girls" }
    , { name = "Creepster", value = DropDownList.stringValue "Creepster" }
    , { name = "Crete Round", value = DropDownList.stringValue "Crete Round" }
    , { name = "Crimson Pro", value = DropDownList.stringValue "Crimson Pro" }
    , { name = "Crimson Text", value = DropDownList.stringValue "Crimson Text" }
    , { name = "Croissant One", value = DropDownList.stringValue "Croissant One" }
    , { name = "Crushed", value = DropDownList.stringValue "Crushed" }
    , { name = "Cuprum", value = DropDownList.stringValue "Cuprum" }
    , { name = "Cute Font", value = DropDownList.stringValue "Cute Font" }
    , { name = "Cutive", value = DropDownList.stringValue "Cutive" }
    , { name = "Cutive Mono", value = DropDownList.stringValue "Cutive Mono" }
    , { name = "Damion", value = DropDownList.stringValue "Damion" }
    , { name = "Dancing Script", value = DropDownList.stringValue "Dancing Script" }
    , { name = "Dangrek", value = DropDownList.stringValue "Dangrek" }
    , { name = "Darker Grotesque", value = DropDownList.stringValue "Darker Grotesque" }
    , { name = "David Libre", value = DropDownList.stringValue "David Libre" }
    , { name = "Dawning of a New Day", value = DropDownList.stringValue "Dawning of a New Day" }
    , { name = "Days One", value = DropDownList.stringValue "Days One" }
    , { name = "Dekko", value = DropDownList.stringValue "Dekko" }
    , { name = "Delius", value = DropDownList.stringValue "Delius" }
    , { name = "Delius Swash Caps", value = DropDownList.stringValue "Delius Swash Caps" }
    , { name = "Delius Unicase", value = DropDownList.stringValue "Delius Unicase" }
    , { name = "Della Respira", value = DropDownList.stringValue "Della Respira" }
    , { name = "Denk One", value = DropDownList.stringValue "Denk One" }
    , { name = "Devonshire", value = DropDownList.stringValue "Devonshire" }
    , { name = "Dhurjati", value = DropDownList.stringValue "Dhurjati" }
    , { name = "Didact Gothic", value = DropDownList.stringValue "Didact Gothic" }
    , { name = "Diplomata", value = DropDownList.stringValue "Diplomata" }
    , { name = "Diplomata SC", value = DropDownList.stringValue "Diplomata SC" }
    , { name = "DM Sans", value = DropDownList.stringValue "DM Sans" }
    , { name = "DM Serif Display", value = DropDownList.stringValue "DM Serif Display" }
    , { name = "DM Serif Text", value = DropDownList.stringValue "DM Serif Text" }
    , { name = "Do Hyeon", value = DropDownList.stringValue "Do Hyeon" }
    , { name = "Dokdo", value = DropDownList.stringValue "Dokdo" }
    , { name = "Domine", value = DropDownList.stringValue "Domine" }
    , { name = "Donegal One", value = DropDownList.stringValue "Donegal One" }
    , { name = "Doppio One", value = DropDownList.stringValue "Doppio One" }
    , { name = "Dorsa", value = DropDownList.stringValue "Dorsa" }
    , { name = "Dosis", value = DropDownList.stringValue "Dosis" }
    , { name = "Dr Sugiyama", value = DropDownList.stringValue "Dr Sugiyama" }
    , { name = "Duru Sans", value = DropDownList.stringValue "Duru Sans" }
    , { name = "Dynalight", value = DropDownList.stringValue "Dynalight" }
    , { name = "Eagle Lake", value = DropDownList.stringValue "Eagle Lake" }
    , { name = "East Sea Dokdo", value = DropDownList.stringValue "East Sea Dokdo" }
    , { name = "Eater", value = DropDownList.stringValue "Eater" }
    , { name = "EB Garamond", value = DropDownList.stringValue "EB Garamond" }
    , { name = "Economica", value = DropDownList.stringValue "Economica" }
    , { name = "Eczar", value = DropDownList.stringValue "Eczar" }
    , { name = "El Messiri", value = DropDownList.stringValue "El Messiri" }
    , { name = "Electrolize", value = DropDownList.stringValue "Electrolize" }
    , { name = "Elsie", value = DropDownList.stringValue "Elsie" }
    , { name = "Elsie Swash Caps", value = DropDownList.stringValue "Elsie Swash Caps" }
    , { name = "Emblema One", value = DropDownList.stringValue "Emblema One" }
    , { name = "Emilys Candy", value = DropDownList.stringValue "Emilys Candy" }
    , { name = "Encode Sans", value = DropDownList.stringValue "Encode Sans" }
    , { name = "Encode Sans Condensed", value = DropDownList.stringValue "Encode Sans Condensed" }
    , { name = "Encode Sans Expanded", value = DropDownList.stringValue "Encode Sans Expanded" }
    , { name = "Encode Sans Semi Condensed", value = DropDownList.stringValue "Encode Sans Semi Condensed" }
    , { name = "Encode Sans Semi Expanded", value = DropDownList.stringValue "Encode Sans Semi Expanded" }
    , { name = "Engagement", value = DropDownList.stringValue "Engagement" }
    , { name = "Englebert", value = DropDownList.stringValue "Englebert" }
    , { name = "Enriqueta", value = DropDownList.stringValue "Enriqueta" }
    , { name = "Erica One", value = DropDownList.stringValue "Erica One" }
    , { name = "Esteban", value = DropDownList.stringValue "Esteban" }
    , { name = "Euphoria Script", value = DropDownList.stringValue "Euphoria Script" }
    , { name = "Ewert", value = DropDownList.stringValue "Ewert" }
    , { name = "Exo", value = DropDownList.stringValue "Exo" }
    , { name = "Exo 2", value = DropDownList.stringValue "Exo 2" }
    , { name = "Expletus Sans", value = DropDownList.stringValue "Expletus Sans" }
    , { name = "Fahkwang", value = DropDownList.stringValue "Fahkwang" }
    , { name = "Fanwood Text", value = DropDownList.stringValue "Fanwood Text" }
    , { name = "Farro", value = DropDownList.stringValue "Farro" }
    , { name = "Farsan", value = DropDownList.stringValue "Farsan" }
    , { name = "Fascinate", value = DropDownList.stringValue "Fascinate" }
    , { name = "Fascinate Inline", value = DropDownList.stringValue "Fascinate Inline" }
    , { name = "Faster One", value = DropDownList.stringValue "Faster One" }
    , { name = "Fasthand", value = DropDownList.stringValue "Fasthand" }
    , { name = "Fauna One", value = DropDownList.stringValue "Fauna One" }
    , { name = "Faustina", value = DropDownList.stringValue "Faustina" }
    , { name = "Federant", value = DropDownList.stringValue "Federant" }
    , { name = "Federo", value = DropDownList.stringValue "Federo" }
    , { name = "Felipa", value = DropDownList.stringValue "Felipa" }
    , { name = "Fenix", value = DropDownList.stringValue "Fenix" }
    , { name = "Finger Paint", value = DropDownList.stringValue "Finger Paint" }
    , { name = "Fira Code", value = DropDownList.stringValue "Fira Code" }
    , { name = "Fira Mono", value = DropDownList.stringValue "Fira Mono" }
    , { name = "Fira Sans", value = DropDownList.stringValue "Fira Sans" }
    , { name = "Fira Sans Condensed", value = DropDownList.stringValue "Fira Sans Condensed" }
    , { name = "Fira Sans Extra Condensed", value = DropDownList.stringValue "Fira Sans Extra Condensed" }
    , { name = "Fjalla One", value = DropDownList.stringValue "Fjalla One" }
    , { name = "Fjord One", value = DropDownList.stringValue "Fjord One" }
    , { name = "Flamenco", value = DropDownList.stringValue "Flamenco" }
    , { name = "Flavors", value = DropDownList.stringValue "Flavors" }
    , { name = "Fondamento", value = DropDownList.stringValue "Fondamento" }
    , { name = "Fontdiner Swanky", value = DropDownList.stringValue "Fontdiner Swanky" }
    , { name = "Forum", value = DropDownList.stringValue "Forum" }
    , { name = "Francois One", value = DropDownList.stringValue "Francois One" }
    , { name = "Frank Ruhl Libre", value = DropDownList.stringValue "Frank Ruhl Libre" }
    , { name = "Freckle Face", value = DropDownList.stringValue "Freckle Face" }
    , { name = "Fredericka the Great", value = DropDownList.stringValue "Fredericka the Great" }
    , { name = "Fredoka One", value = DropDownList.stringValue "Fredoka One" }
    , { name = "Freehand", value = DropDownList.stringValue "Freehand" }
    , { name = "Fresca", value = DropDownList.stringValue "Fresca" }
    , { name = "Frijole", value = DropDownList.stringValue "Frijole" }
    , { name = "Fruktur", value = DropDownList.stringValue "Fruktur" }
    , { name = "Fugaz One", value = DropDownList.stringValue "Fugaz One" }
    , { name = "Gabriela", value = DropDownList.stringValue "Gabriela" }
    , { name = "Gaegu", value = DropDownList.stringValue "Gaegu" }
    , { name = "Gafata", value = DropDownList.stringValue "Gafata" }
    , { name = "Galada", value = DropDownList.stringValue "Galada" }
    , { name = "Galdeano", value = DropDownList.stringValue "Galdeano" }
    , { name = "Galindo", value = DropDownList.stringValue "Galindo" }
    , { name = "Gamja Flower", value = DropDownList.stringValue "Gamja Flower" }
    , { name = "Gayathri", value = DropDownList.stringValue "Gayathri" }
    , { name = "Gentium Basic", value = DropDownList.stringValue "Gentium Basic" }
    , { name = "Gentium Book Basic", value = DropDownList.stringValue "Gentium Book Basic" }
    , { name = "Geo", value = DropDownList.stringValue "Geo" }
    , { name = "Geostar", value = DropDownList.stringValue "Geostar" }
    , { name = "Geostar Fill", value = DropDownList.stringValue "Geostar Fill" }
    , { name = "Germania One", value = DropDownList.stringValue "Germania One" }
    , { name = "GFS Didot", value = DropDownList.stringValue "GFS Didot" }
    , { name = "GFS Neohellenic", value = DropDownList.stringValue "GFS Neohellenic" }
    , { name = "Gidugu", value = DropDownList.stringValue "Gidugu" }
    , { name = "Gilda Display", value = DropDownList.stringValue "Gilda Display" }
    , { name = "Give You Glory", value = DropDownList.stringValue "Give You Glory" }
    , { name = "Glass Antiqua", value = DropDownList.stringValue "Glass Antiqua" }
    , { name = "Glegoo", value = DropDownList.stringValue "Glegoo" }
    , { name = "Gloria Hallelujah", value = DropDownList.stringValue "Gloria Hallelujah" }
    , { name = "Goblin One", value = DropDownList.stringValue "Goblin One" }
    , { name = "Gochi Hand", value = DropDownList.stringValue "Gochi Hand" }
    , { name = "Gorditas", value = DropDownList.stringValue "Gorditas" }
    , { name = "Gothic A1", value = DropDownList.stringValue "Gothic A1" }
    , { name = "Goudy Bookletter 1911", value = DropDownList.stringValue "Goudy Bookletter 1911" }
    , { name = "Graduate", value = DropDownList.stringValue "Graduate" }
    , { name = "Grand Hotel", value = DropDownList.stringValue "Grand Hotel" }
    , { name = "Gravitas One", value = DropDownList.stringValue "Gravitas One" }
    , { name = "Great Vibes", value = DropDownList.stringValue "Great Vibes" }
    , { name = "Grenze", value = DropDownList.stringValue "Grenze" }
    , { name = "Griffy", value = DropDownList.stringValue "Griffy" }
    , { name = "Gruppo", value = DropDownList.stringValue "Gruppo" }
    , { name = "Gudea", value = DropDownList.stringValue "Gudea" }
    , { name = "Gugi", value = DropDownList.stringValue "Gugi" }
    , { name = "Gurajada", value = DropDownList.stringValue "Gurajada" }
    , { name = "Habibi", value = DropDownList.stringValue "Habibi" }
    , { name = "Halant", value = DropDownList.stringValue "Halant" }
    , { name = "Hammersmith One", value = DropDownList.stringValue "Hammersmith One" }
    , { name = "Hanalei", value = DropDownList.stringValue "Hanalei" }
    , { name = "Hanalei Fill", value = DropDownList.stringValue "Hanalei Fill" }
    , { name = "Handlee", value = DropDownList.stringValue "Handlee" }
    , { name = "Hanuman", value = DropDownList.stringValue "Hanuman" }
    , { name = "Happy Monkey", value = DropDownList.stringValue "Happy Monkey" }
    , { name = "Harmattan", value = DropDownList.stringValue "Harmattan" }
    , { name = "Headland One", value = DropDownList.stringValue "Headland One" }
    , { name = "Heebo", value = DropDownList.stringValue "Heebo" }
    , { name = "Henny Penny", value = DropDownList.stringValue "Henny Penny" }
    , { name = "Hepta Slab", value = DropDownList.stringValue "Hepta Slab" }
    , { name = "Herr Von Muellerhoff", value = DropDownList.stringValue "Herr Von Muellerhoff" }
    , { name = "Hi Melody", value = DropDownList.stringValue "Hi Melody" }
    , { name = "Hind", value = DropDownList.stringValue "Hind" }
    , { name = "Hind Guntur", value = DropDownList.stringValue "Hind Guntur" }
    , { name = "Hind Madurai", value = DropDownList.stringValue "Hind Madurai" }
    , { name = "Hind Siliguri", value = DropDownList.stringValue "Hind Siliguri" }
    , { name = "Hind Vadodara", value = DropDownList.stringValue "Hind Vadodara" }
    , { name = "Holtwood One SC", value = DropDownList.stringValue "Holtwood One SC" }
    , { name = "Homemade Apple", value = DropDownList.stringValue "Homemade Apple" }
    , { name = "Homenaje", value = DropDownList.stringValue "Homenaje" }
    , { name = "IBM Plex Mono", value = DropDownList.stringValue "IBM Plex Mono" }
    , { name = "IBM Plex Sans", value = DropDownList.stringValue "IBM Plex Sans" }
    , { name = "IBM Plex Sans Condensed", value = DropDownList.stringValue "IBM Plex Sans Condensed" }
    , { name = "IBM Plex Serif", value = DropDownList.stringValue "IBM Plex Serif" }
    , { name = "Iceberg", value = DropDownList.stringValue "Iceberg" }
    , { name = "Iceland", value = DropDownList.stringValue "Iceland" }
    , { name = "IM Fell Double Pica", value = DropDownList.stringValue "IM Fell Double Pica" }
    , { name = "IM Fell Double Pica SC", value = DropDownList.stringValue "IM Fell Double Pica SC" }
    , { name = "IM Fell DW Pica", value = DropDownList.stringValue "IM Fell DW Pica" }
    , { name = "IM Fell DW Pica SC", value = DropDownList.stringValue "IM Fell DW Pica SC" }
    , { name = "IM Fell English", value = DropDownList.stringValue "IM Fell English" }
    , { name = "IM Fell English SC", value = DropDownList.stringValue "IM Fell English SC" }
    , { name = "IM Fell French Canon", value = DropDownList.stringValue "IM Fell French Canon" }
    , { name = "IM Fell French Canon SC", value = DropDownList.stringValue "IM Fell French Canon SC" }
    , { name = "IM Fell Great Primer", value = DropDownList.stringValue "IM Fell Great Primer" }
    , { name = "IM Fell Great Primer SC", value = DropDownList.stringValue "IM Fell Great Primer SC" }
    , { name = "Imprima", value = DropDownList.stringValue "Imprima" }
    , { name = "Inconsolata", value = DropDownList.stringValue "Inconsolata" }
    , { name = "Inder", value = DropDownList.stringValue "Inder" }
    , { name = "Indie Flower", value = DropDownList.stringValue "Indie Flower" }
    , { name = "Inika", value = DropDownList.stringValue "Inika" }
    , { name = "Inknut Antiqua", value = DropDownList.stringValue "Inknut Antiqua" }
    , { name = "Irish Grover", value = DropDownList.stringValue "Irish Grover" }
    , { name = "Istok Web", value = DropDownList.stringValue "Istok Web" }
    , { name = "Italiana", value = DropDownList.stringValue "Italiana" }
    , { name = "Italianno", value = DropDownList.stringValue "Italianno" }
    , { name = "Itim", value = DropDownList.stringValue "Itim" }
    , { name = "Jacques Francois", value = DropDownList.stringValue "Jacques Francois" }
    , { name = "Jacques Francois Shadow", value = DropDownList.stringValue "Jacques Francois Shadow" }
    , { name = "Jaldi", value = DropDownList.stringValue "Jaldi" }
    , { name = "Jim Nightshade", value = DropDownList.stringValue "Jim Nightshade" }
    , { name = "Jockey One", value = DropDownList.stringValue "Jockey One" }
    , { name = "Jolly Lodger", value = DropDownList.stringValue "Jolly Lodger" }
    , { name = "Jomhuria", value = DropDownList.stringValue "Jomhuria" }
    , { name = "Josefin Sans", value = DropDownList.stringValue "Josefin Sans" }
    , { name = "Josefin Slab", value = DropDownList.stringValue "Josefin Slab" }
    , { name = "Joti One", value = DropDownList.stringValue "Joti One" }
    , { name = "Jua", value = DropDownList.stringValue "Jua" }
    , { name = "Judson", value = DropDownList.stringValue "Judson" }
    , { name = "Julee", value = DropDownList.stringValue "Julee" }
    , { name = "Julius Sans One", value = DropDownList.stringValue "Julius Sans One" }
    , { name = "Junge", value = DropDownList.stringValue "Junge" }
    , { name = "Jura", value = DropDownList.stringValue "Jura" }
    , { name = "Just Another Hand", value = DropDownList.stringValue "Just Another Hand" }
    , { name = "Just Me Again Down Here", value = DropDownList.stringValue "Just Me Again Down Here" }
    , { name = "K2D", value = DropDownList.stringValue "K2D" }
    , { name = "Kadwa", value = DropDownList.stringValue "Kadwa" }
    , { name = "Kalam", value = DropDownList.stringValue "Kalam" }
    , { name = "Kameron", value = DropDownList.stringValue "Kameron" }
    , { name = "Kanit", value = DropDownList.stringValue "Kanit" }
    , { name = "Kantumruy", value = DropDownList.stringValue "Kantumruy" }
    , { name = "Karla", value = DropDownList.stringValue "Karla" }
    , { name = "Karma", value = DropDownList.stringValue "Karma" }
    , { name = "Katibeh", value = DropDownList.stringValue "Katibeh" }
    , { name = "Kaushan Script", value = DropDownList.stringValue "Kaushan Script" }
    , { name = "Kavivanar", value = DropDownList.stringValue "Kavivanar" }
    , { name = "Kavoon", value = DropDownList.stringValue "Kavoon" }
    , { name = "Kdam Thmor", value = DropDownList.stringValue "Kdam Thmor" }
    , { name = "Keania One", value = DropDownList.stringValue "Keania One" }
    , { name = "Kelly Slab", value = DropDownList.stringValue "Kelly Slab" }
    , { name = "Kenia", value = DropDownList.stringValue "Kenia" }
    , { name = "Khand", value = DropDownList.stringValue "Khand" }
    , { name = "Khmer", value = DropDownList.stringValue "Khmer" }
    , { name = "Khula", value = DropDownList.stringValue "Khula" }
    , { name = "Kirang Haerang", value = DropDownList.stringValue "Kirang Haerang" }
    , { name = "Kite One", value = DropDownList.stringValue "Kite One" }
    , { name = "Knewave", value = DropDownList.stringValue "Knewave" }
    , { name = "Kodchasan", value = DropDownList.stringValue "Kodchasan" }
    , { name = "KoHo", value = DropDownList.stringValue "KoHo" }
    , { name = "Kosugi", value = DropDownList.stringValue "Kosugi" }
    , { name = "Kosugi Maru", value = DropDownList.stringValue "Kosugi Maru" }
    , { name = "Kotta One", value = DropDownList.stringValue "Kotta One" }
    , { name = "Koulen", value = DropDownList.stringValue "Koulen" }
    , { name = "Kranky", value = DropDownList.stringValue "Kranky" }
    , { name = "Kreon", value = DropDownList.stringValue "Kreon" }
    , { name = "Kristi", value = DropDownList.stringValue "Kristi" }
    , { name = "Krona One", value = DropDownList.stringValue "Krona One" }
    , { name = "Krub", value = DropDownList.stringValue "Krub" }
    , { name = "Kumar One", value = DropDownList.stringValue "Kumar One" }
    , { name = "Kumar One Outline", value = DropDownList.stringValue "Kumar One Outline" }
    , { name = "Kurale", value = DropDownList.stringValue "Kurale" }
    , { name = "La Belle Aurore", value = DropDownList.stringValue "La Belle Aurore" }
    , { name = "Lacquer", value = DropDownList.stringValue "Lacquer" }
    , { name = "Laila", value = DropDownList.stringValue "Laila" }
    , { name = "Lakki Reddy", value = DropDownList.stringValue "Lakki Reddy" }
    , { name = "Lalezar", value = DropDownList.stringValue "Lalezar" }
    , { name = "Lancelot", value = DropDownList.stringValue "Lancelot" }
    , { name = "Lateef", value = DropDownList.stringValue "Lateef" }
    , { name = "Lato", value = DropDownList.stringValue "Lato" }
    , { name = "League Script", value = DropDownList.stringValue "League Script" }
    , { name = "Leckerli One", value = DropDownList.stringValue "Leckerli One" }
    , { name = "Ledger", value = DropDownList.stringValue "Ledger" }
    , { name = "Lekton", value = DropDownList.stringValue "Lekton" }
    , { name = "Lemon", value = DropDownList.stringValue "Lemon" }
    , { name = "Lemonada", value = DropDownList.stringValue "Lemonada" }
    , { name = "Lexend Deca", value = DropDownList.stringValue "Lexend Deca" }
    , { name = "Lexend Exa", value = DropDownList.stringValue "Lexend Exa" }
    , { name = "Lexend Giga", value = DropDownList.stringValue "Lexend Giga" }
    , { name = "Lexend Mega", value = DropDownList.stringValue "Lexend Mega" }
    , { name = "Lexend Peta", value = DropDownList.stringValue "Lexend Peta" }
    , { name = "Lexend Tera", value = DropDownList.stringValue "Lexend Tera" }
    , { name = "Lexend Zetta", value = DropDownList.stringValue "Lexend Zetta" }
    , { name = "Libre Barcode 128", value = DropDownList.stringValue "Libre Barcode 128" }
    , { name = "Libre Barcode 128 Text", value = DropDownList.stringValue "Libre Barcode 128 Text" }
    , { name = "Libre Barcode 39", value = DropDownList.stringValue "Libre Barcode 39" }
    , { name = "Libre Barcode 39 Extended", value = DropDownList.stringValue "Libre Barcode 39 Extended" }
    , { name = "Libre Barcode 39 Extended Text", value = DropDownList.stringValue "Libre Barcode 39 Extended Text" }
    , { name = "Libre Barcode 39 Text", value = DropDownList.stringValue "Libre Barcode 39 Text" }
    , { name = "Libre Baskerville", value = DropDownList.stringValue "Libre Baskerville" }
    , { name = "Libre Caslon Text", value = DropDownList.stringValue "Libre Caslon Text" }
    , { name = "Libre Franklin", value = DropDownList.stringValue "Libre Franklin" }
    , { name = "Life Savers", value = DropDownList.stringValue "Life Savers" }
    , { name = "Lilita One", value = DropDownList.stringValue "Lilita One" }
    , { name = "Lily Script One", value = DropDownList.stringValue "Lily Script One" }
    , { name = "Limelight", value = DropDownList.stringValue "Limelight" }
    , { name = "Linden Hill", value = DropDownList.stringValue "Linden Hill" }
    , { name = "Literata", value = DropDownList.stringValue "Literata" }
    , { name = "Liu Jian Mao Cao", value = DropDownList.stringValue "Liu Jian Mao Cao" }
    , { name = "Livvic", value = DropDownList.stringValue "Livvic" }
    , { name = "Lobster", value = DropDownList.stringValue "Lobster" }
    , { name = "Lobster Two", value = DropDownList.stringValue "Lobster Two" }
    , { name = "Londrina Outline", value = DropDownList.stringValue "Londrina Outline" }
    , { name = "Londrina Shadow", value = DropDownList.stringValue "Londrina Shadow" }
    , { name = "Londrina Sketch", value = DropDownList.stringValue "Londrina Sketch" }
    , { name = "Londrina Solid", value = DropDownList.stringValue "Londrina Solid" }
    , { name = "Long Cang", value = DropDownList.stringValue "Long Cang" }
    , { name = "Lora", value = DropDownList.stringValue "Lora" }
    , { name = "Love Ya Like A Sister", value = DropDownList.stringValue "Love Ya Like A Sister" }
    , { name = "Loved by the King", value = DropDownList.stringValue "Loved by the King" }
    , { name = "Lovers Quarrel", value = DropDownList.stringValue "Lovers Quarrel" }
    , { name = "Luckiest Guy", value = DropDownList.stringValue "Luckiest Guy" }
    , { name = "Lusitana", value = DropDownList.stringValue "Lusitana" }
    , { name = "Lustria", value = DropDownList.stringValue "Lustria" }
    , { name = "M PLUS 1p", value = DropDownList.stringValue "M PLUS 1p" }
    , { name = "M PLUS Rounded 1c", value = DropDownList.stringValue "M PLUS Rounded 1c" }
    , { name = "Ma Shan Zheng", value = DropDownList.stringValue "Ma Shan Zheng" }
    , { name = "Macondo", value = DropDownList.stringValue "Macondo" }
    , { name = "Macondo Swash Caps", value = DropDownList.stringValue "Macondo Swash Caps" }
    , { name = "Mada", value = DropDownList.stringValue "Mada" }
    , { name = "Magra", value = DropDownList.stringValue "Magra" }
    , { name = "Maiden Orange", value = DropDownList.stringValue "Maiden Orange" }
    , { name = "Maitree", value = DropDownList.stringValue "Maitree" }
    , { name = "Major Mono Display", value = DropDownList.stringValue "Major Mono Display" }
    , { name = "Mako", value = DropDownList.stringValue "Mako" }
    , { name = "Mali", value = DropDownList.stringValue "Mali" }
    , { name = "Mallanna", value = DropDownList.stringValue "Mallanna" }
    , { name = "Mandali", value = DropDownList.stringValue "Mandali" }
    , { name = "Manjari", value = DropDownList.stringValue "Manjari" }
    , { name = "Mansalva", value = DropDownList.stringValue "Mansalva" }
    , { name = "Manuale", value = DropDownList.stringValue "Manuale" }
    , { name = "Marcellus", value = DropDownList.stringValue "Marcellus" }
    , { name = "Marcellus SC", value = DropDownList.stringValue "Marcellus SC" }
    , { name = "Marck Script", value = DropDownList.stringValue "Marck Script" }
    , { name = "Margarine", value = DropDownList.stringValue "Margarine" }
    , { name = "Markazi Text", value = DropDownList.stringValue "Markazi Text" }
    , { name = "Marko One", value = DropDownList.stringValue "Marko One" }
    , { name = "Marmelad", value = DropDownList.stringValue "Marmelad" }
    , { name = "Martel", value = DropDownList.stringValue "Martel" }
    , { name = "Martel Sans", value = DropDownList.stringValue "Martel Sans" }
    , { name = "Marvel", value = DropDownList.stringValue "Marvel" }
    , { name = "Mate", value = DropDownList.stringValue "Mate" }
    , { name = "Mate SC", value = DropDownList.stringValue "Mate SC" }
    , { name = "Maven Pro", value = DropDownList.stringValue "Maven Pro" }
    , { name = "McLaren", value = DropDownList.stringValue "McLaren" }
    , { name = "Meddon", value = DropDownList.stringValue "Meddon" }
    , { name = "MedievalSharp", value = DropDownList.stringValue "MedievalSharp" }
    , { name = "Medula One", value = DropDownList.stringValue "Medula One" }
    , { name = "Meera Inimai", value = DropDownList.stringValue "Meera Inimai" }
    , { name = "Megrim", value = DropDownList.stringValue "Megrim" }
    , { name = "Meie Script", value = DropDownList.stringValue "Meie Script" }
    , { name = "Merienda", value = DropDownList.stringValue "Merienda" }
    , { name = "Merienda One", value = DropDownList.stringValue "Merienda One" }
    , { name = "Merriweather", value = DropDownList.stringValue "Merriweather" }
    , { name = "Merriweather Sans", value = DropDownList.stringValue "Merriweather Sans" }
    , { name = "Metal", value = DropDownList.stringValue "Metal" }
    , { name = "Metal Mania", value = DropDownList.stringValue "Metal Mania" }
    , { name = "Metamorphous", value = DropDownList.stringValue "Metamorphous" }
    , { name = "Metrophobic", value = DropDownList.stringValue "Metrophobic" }
    , { name = "Michroma", value = DropDownList.stringValue "Michroma" }
    , { name = "Milonga", value = DropDownList.stringValue "Milonga" }
    , { name = "Miltonian", value = DropDownList.stringValue "Miltonian" }
    , { name = "Miltonian Tattoo", value = DropDownList.stringValue "Miltonian Tattoo" }
    , { name = "Mina", value = DropDownList.stringValue "Mina" }
    , { name = "Miniver", value = DropDownList.stringValue "Miniver" }
    , { name = "Miriam Libre", value = DropDownList.stringValue "Miriam Libre" }
    , { name = "Mirza", value = DropDownList.stringValue "Mirza" }
    , { name = "Miss Fajardose", value = DropDownList.stringValue "Miss Fajardose" }
    , { name = "Mitr", value = DropDownList.stringValue "Mitr" }
    , { name = "Modak", value = DropDownList.stringValue "Modak" }
    , { name = "Modern Antiqua", value = DropDownList.stringValue "Modern Antiqua" }
    , { name = "Mogra", value = DropDownList.stringValue "Mogra" }
    , { name = "Molengo", value = DropDownList.stringValue "Molengo" }
    , { name = "Molle", value = DropDownList.stringValue "Molle" }
    , { name = "Monda", value = DropDownList.stringValue "Monda" }
    , { name = "Monofett", value = DropDownList.stringValue "Monofett" }
    , { name = "Monoton", value = DropDownList.stringValue "Monoton" }
    , { name = "Monsieur La Doulaise", value = DropDownList.stringValue "Monsieur La Doulaise" }
    , { name = "Montaga", value = DropDownList.stringValue "Montaga" }
    , { name = "Montez", value = DropDownList.stringValue "Montez" }
    , { name = "Montserrat", value = DropDownList.stringValue "Montserrat" }
    , { name = "Montserrat Alternates", value = DropDownList.stringValue "Montserrat Alternates" }
    , { name = "Montserrat Subrayada", value = DropDownList.stringValue "Montserrat Subrayada" }
    , { name = "Moul", value = DropDownList.stringValue "Moul" }
    , { name = "Moulpali", value = DropDownList.stringValue "Moulpali" }
    , { name = "Mountains of Christmas", value = DropDownList.stringValue "Mountains of Christmas" }
    , { name = "Mouse Memoirs", value = DropDownList.stringValue "Mouse Memoirs" }
    , { name = "Mr Bedfort", value = DropDownList.stringValue "Mr Bedfort" }
    , { name = "Mr Dafoe", value = DropDownList.stringValue "Mr Dafoe" }
    , { name = "Mr De Haviland", value = DropDownList.stringValue "Mr De Haviland" }
    , { name = "Mrs Saint Delafield", value = DropDownList.stringValue "Mrs Saint Delafield" }
    , { name = "Mrs Sheppards", value = DropDownList.stringValue "Mrs Sheppards" }
    , { name = "Mukta", value = DropDownList.stringValue "Mukta" }
    , { name = "Mukta Mahee", value = DropDownList.stringValue "Mukta Mahee" }
    , { name = "Mukta Malar", value = DropDownList.stringValue "Mukta Malar" }
    , { name = "Mukta Vaani", value = DropDownList.stringValue "Mukta Vaani" }
    , { name = "Muli", value = DropDownList.stringValue "Muli" }
    , { name = "Mystery Quest", value = DropDownList.stringValue "Mystery Quest" }
    , { name = "Nanum Brush Script", value = DropDownList.stringValue "Nanum Brush Script" }
    , { name = "Nanum Gothic", value = DropDownList.stringValue "Nanum Gothic" }
    , { name = "Nanum Gothic Coding", value = DropDownList.stringValue "Nanum Gothic Coding" }
    , { name = "Nanum Myeongjo", value = DropDownList.stringValue "Nanum Myeongjo" }
    , { name = "Nanum Pen Script", value = DropDownList.stringValue "Nanum Pen Script" }
    , { name = "Neucha", value = DropDownList.stringValue "Neucha" }
    , { name = "Neuton", value = DropDownList.stringValue "Neuton" }
    , { name = "New Rocker", value = DropDownList.stringValue "New Rocker" }
    , { name = "News Cycle", value = DropDownList.stringValue "News Cycle" }
    , { name = "Niconne", value = DropDownList.stringValue "Niconne" }
    , { name = "Niramit", value = DropDownList.stringValue "Niramit" }
    , { name = "Nixie One", value = DropDownList.stringValue "Nixie One" }
    , { name = "Nobile", value = DropDownList.stringValue "Nobile" }
    , { name = "Nokora", value = DropDownList.stringValue "Nokora" }
    , { name = "Norican", value = DropDownList.stringValue "Norican" }
    , { name = "Nosifer", value = DropDownList.stringValue "Nosifer" }
    , { name = "Notable", value = DropDownList.stringValue "Notable" }
    , { name = "Nothing You Could Do", value = DropDownList.stringValue "Nothing You Could Do" }
    , { name = "Noticia Text", value = DropDownList.stringValue "Noticia Text" }
    , { name = "Noto Sans", value = DropDownList.stringValue "Noto Sans" }
    , { name = "Noto Sans HK", value = DropDownList.stringValue "Noto Sans HK" }
    , { name = "Noto Sans JP", value = DropDownList.stringValue "Noto Sans JP" }
    , { name = "Noto Sans KR", value = DropDownList.stringValue "Noto Sans KR" }
    , { name = "Noto Sans SC", value = DropDownList.stringValue "Noto Sans SC" }
    , { name = "Noto Sans TC", value = DropDownList.stringValue "Noto Sans TC" }
    , { name = "Noto Serif", value = DropDownList.stringValue "Noto Serif" }
    , { name = "Noto Serif JP", value = DropDownList.stringValue "Noto Serif JP" }
    , { name = "Noto Serif KR", value = DropDownList.stringValue "Noto Serif KR" }
    , { name = "Noto Serif SC", value = DropDownList.stringValue "Noto Serif SC" }
    , { name = "Noto Serif TC", value = DropDownList.stringValue "Noto Serif TC" }
    , { name = "Nova Cut", value = DropDownList.stringValue "Nova Cut" }
    , { name = "Nova Flat", value = DropDownList.stringValue "Nova Flat" }
    , { name = "Nova Mono", value = DropDownList.stringValue "Nova Mono" }
    , { name = "Nova Oval", value = DropDownList.stringValue "Nova Oval" }
    , { name = "Nova Round", value = DropDownList.stringValue "Nova Round" }
    , { name = "Nova Script", value = DropDownList.stringValue "Nova Script" }
    , { name = "Nova Slim", value = DropDownList.stringValue "Nova Slim" }
    , { name = "Nova Square", value = DropDownList.stringValue "Nova Square" }
    , { name = "NTR", value = DropDownList.stringValue "NTR" }
    , { name = "Numans", value = DropDownList.stringValue "Numans" }
    , { name = "Nunito", value = DropDownList.stringValue "Nunito" }
    , { name = "Nunito Sans", value = DropDownList.stringValue "Nunito Sans" }
    , { name = "Odor Mean Chey", value = DropDownList.stringValue "Odor Mean Chey" }
    , { name = "Offside", value = DropDownList.stringValue "Offside" }
    , { name = "Old Standard TT", value = DropDownList.stringValue "Old Standard TT" }
    , { name = "Oldenburg", value = DropDownList.stringValue "Oldenburg" }
    , { name = "Oleo Script", value = DropDownList.stringValue "Oleo Script" }
    , { name = "Oleo Script Swash Caps", value = DropDownList.stringValue "Oleo Script Swash Caps" }
    , { name = "Open Sans", value = DropDownList.stringValue "Open Sans" }
    , { name = "Open Sans Condensed", value = DropDownList.stringValue "Open Sans Condensed" }
    , { name = "Oranienbaum", value = DropDownList.stringValue "Oranienbaum" }
    , { name = "Orbitron", value = DropDownList.stringValue "Orbitron" }
    , { name = "Oregano", value = DropDownList.stringValue "Oregano" }
    , { name = "Orienta", value = DropDownList.stringValue "Orienta" }
    , { name = "Original Surfer", value = DropDownList.stringValue "Original Surfer" }
    , { name = "Oswald", value = DropDownList.stringValue "Oswald" }
    , { name = "Over the Rainbow", value = DropDownList.stringValue "Over the Rainbow" }
    , { name = "Overlock", value = DropDownList.stringValue "Overlock" }
    , { name = "Overlock SC", value = DropDownList.stringValue "Overlock SC" }
    , { name = "Overpass", value = DropDownList.stringValue "Overpass" }
    , { name = "Overpass Mono", value = DropDownList.stringValue "Overpass Mono" }
    , { name = "Ovo", value = DropDownList.stringValue "Ovo" }
    , { name = "Oxygen", value = DropDownList.stringValue "Oxygen" }
    , { name = "Oxygen Mono", value = DropDownList.stringValue "Oxygen Mono" }
    , { name = "Pacifico", value = DropDownList.stringValue "Pacifico" }
    , { name = "Padauk", value = DropDownList.stringValue "Padauk" }
    , { name = "Palanquin", value = DropDownList.stringValue "Palanquin" }
    , { name = "Palanquin Dark", value = DropDownList.stringValue "Palanquin Dark" }
    , { name = "Pangolin", value = DropDownList.stringValue "Pangolin" }
    , { name = "Paprika", value = DropDownList.stringValue "Paprika" }
    , { name = "Parisienne", value = DropDownList.stringValue "Parisienne" }
    , { name = "Passero One", value = DropDownList.stringValue "Passero One" }
    , { name = "Passion One", value = DropDownList.stringValue "Passion One" }
    , { name = "Pathway Gothic One", value = DropDownList.stringValue "Pathway Gothic One" }
    , { name = "Patrick Hand", value = DropDownList.stringValue "Patrick Hand" }
    , { name = "Patrick Hand SC", value = DropDownList.stringValue "Patrick Hand SC" }
    , { name = "Pattaya", value = DropDownList.stringValue "Pattaya" }
    , { name = "Patua One", value = DropDownList.stringValue "Patua One" }
    , { name = "Pavanam", value = DropDownList.stringValue "Pavanam" }
    , { name = "Paytone One", value = DropDownList.stringValue "Paytone One" }
    , { name = "Peddana", value = DropDownList.stringValue "Peddana" }
    , { name = "Peralta", value = DropDownList.stringValue "Peralta" }
    , { name = "Permanent Marker", value = DropDownList.stringValue "Permanent Marker" }
    , { name = "Petit Formal Script", value = DropDownList.stringValue "Petit Formal Script" }
    , { name = "Petrona", value = DropDownList.stringValue "Petrona" }
    , { name = "Philosopher", value = DropDownList.stringValue "Philosopher" }
    , { name = "Piedra", value = DropDownList.stringValue "Piedra" }
    , { name = "Pinyon Script", value = DropDownList.stringValue "Pinyon Script" }
    , { name = "Pirata One", value = DropDownList.stringValue "Pirata One" }
    , { name = "Plaster", value = DropDownList.stringValue "Plaster" }
    , { name = "Play", value = DropDownList.stringValue "Play" }
    , { name = "Playball", value = DropDownList.stringValue "Playball" }
    , { name = "Playfair Display", value = DropDownList.stringValue "Playfair Display" }
    , { name = "Playfair Display SC", value = DropDownList.stringValue "Playfair Display SC" }
    , { name = "Podkova", value = DropDownList.stringValue "Podkova" }
    , { name = "Poiret One", value = DropDownList.stringValue "Poiret One" }
    , { name = "Poller One", value = DropDownList.stringValue "Poller One" }
    , { name = "Poly", value = DropDownList.stringValue "Poly" }
    , { name = "Pompiere", value = DropDownList.stringValue "Pompiere" }
    , { name = "Pontano Sans", value = DropDownList.stringValue "Pontano Sans" }
    , { name = "Poor Story", value = DropDownList.stringValue "Poor Story" }
    , { name = "Poppins", value = DropDownList.stringValue "Poppins" }
    , { name = "Port Lligat Sans", value = DropDownList.stringValue "Port Lligat Sans" }
    , { name = "Port Lligat Slab", value = DropDownList.stringValue "Port Lligat Slab" }
    , { name = "Pragati Narrow", value = DropDownList.stringValue "Pragati Narrow" }
    , { name = "Prata", value = DropDownList.stringValue "Prata" }
    , { name = "Preahvihear", value = DropDownList.stringValue "Preahvihear" }
    , { name = "Press Start 2P", value = DropDownList.stringValue "Press Start 2P" }
    , { name = "Pridi", value = DropDownList.stringValue "Pridi" }
    , { name = "Princess Sofia", value = DropDownList.stringValue "Princess Sofia" }
    , { name = "Prociono", value = DropDownList.stringValue "Prociono" }
    , { name = "Prompt", value = DropDownList.stringValue "Prompt" }
    , { name = "Prosto One", value = DropDownList.stringValue "Prosto One" }
    , { name = "Proza Libre", value = DropDownList.stringValue "Proza Libre" }
    , { name = "PT Mono", value = DropDownList.stringValue "PT Mono" }
    , { name = "PT Sans", value = DropDownList.stringValue "PT Sans" }
    , { name = "PT Sans Caption", value = DropDownList.stringValue "PT Sans Caption" }
    , { name = "PT Sans Narrow", value = DropDownList.stringValue "PT Sans Narrow" }
    , { name = "PT Serif", value = DropDownList.stringValue "PT Serif" }
    , { name = "PT Serif Caption", value = DropDownList.stringValue "PT Serif Caption" }
    , { name = "Puritan", value = DropDownList.stringValue "Puritan" }
    , { name = "Purple Purse", value = DropDownList.stringValue "Purple Purse" }
    , { name = "Quando", value = DropDownList.stringValue "Quando" }
    , { name = "Quantico", value = DropDownList.stringValue "Quantico" }
    , { name = "Quattrocento", value = DropDownList.stringValue "Quattrocento" }
    , { name = "Quattrocento Sans", value = DropDownList.stringValue "Quattrocento Sans" }
    , { name = "Questrial", value = DropDownList.stringValue "Questrial" }
    , { name = "Quicksand", value = DropDownList.stringValue "Quicksand" }
    , { name = "Quintessential", value = DropDownList.stringValue "Quintessential" }
    , { name = "Qwigley", value = DropDownList.stringValue "Qwigley" }
    , { name = "Racing Sans One", value = DropDownList.stringValue "Racing Sans One" }
    , { name = "Radley", value = DropDownList.stringValue "Radley" }
    , { name = "Rajdhani", value = DropDownList.stringValue "Rajdhani" }
    , { name = "Rakkas", value = DropDownList.stringValue "Rakkas" }
    , { name = "Raleway", value = DropDownList.stringValue "Raleway" }
    , { name = "Raleway Dots", value = DropDownList.stringValue "Raleway Dots" }
    , { name = "Ramabhadra", value = DropDownList.stringValue "Ramabhadra" }
    , { name = "Ramaraja", value = DropDownList.stringValue "Ramaraja" }
    , { name = "Rambla", value = DropDownList.stringValue "Rambla" }
    , { name = "Rammetto One", value = DropDownList.stringValue "Rammetto One" }
    , { name = "Ranchers", value = DropDownList.stringValue "Ranchers" }
    , { name = "Rancho", value = DropDownList.stringValue "Rancho" }
    , { name = "Ranga", value = DropDownList.stringValue "Ranga" }
    , { name = "Rasa", value = DropDownList.stringValue "Rasa" }
    , { name = "Rationale", value = DropDownList.stringValue "Rationale" }
    , { name = "Ravi Prakash", value = DropDownList.stringValue "Ravi Prakash" }
    , { name = "Red Hat Display", value = DropDownList.stringValue "Red Hat Display" }
    , { name = "Red Hat Text", value = DropDownList.stringValue "Red Hat Text" }
    , { name = "Redressed", value = DropDownList.stringValue "Redressed" }
    , { name = "Reem Kufi", value = DropDownList.stringValue "Reem Kufi" }
    , { name = "Reenie Beanie", value = DropDownList.stringValue "Reenie Beanie" }
    , { name = "Revalia", value = DropDownList.stringValue "Revalia" }
    , { name = "Rhodium Libre", value = DropDownList.stringValue "Rhodium Libre" }
    , { name = "Ribeye", value = DropDownList.stringValue "Ribeye" }
    , { name = "Ribeye Marrow", value = DropDownList.stringValue "Ribeye Marrow" }
    , { name = "Righteous", value = DropDownList.stringValue "Righteous" }
    , { name = "Risque", value = DropDownList.stringValue "Risque" }
    , { name = "Roboto", value = DropDownList.stringValue "Roboto" }
    , { name = "Roboto Condensed", value = DropDownList.stringValue "Roboto Condensed" }
    , { name = "Roboto Mono", value = DropDownList.stringValue "Roboto Mono" }
    , { name = "Roboto Slab", value = DropDownList.stringValue "Roboto Slab" }
    , { name = "Rochester", value = DropDownList.stringValue "Rochester" }
    , { name = "Rock Salt", value = DropDownList.stringValue "Rock Salt" }
    , { name = "Rokkitt", value = DropDownList.stringValue "Rokkitt" }
    , { name = "Romanesco", value = DropDownList.stringValue "Romanesco" }
    , { name = "Ropa Sans", value = DropDownList.stringValue "Ropa Sans" }
    , { name = "Rosario", value = DropDownList.stringValue "Rosario" }
    , { name = "Rosarivo", value = DropDownList.stringValue "Rosarivo" }
    , { name = "Rouge Script", value = DropDownList.stringValue "Rouge Script" }
    , { name = "Rozha One", value = DropDownList.stringValue "Rozha One" }
    , { name = "Rubik", value = DropDownList.stringValue "Rubik" }
    , { name = "Rubik Mono One", value = DropDownList.stringValue "Rubik Mono One" }
    , { name = "Ruda", value = DropDownList.stringValue "Ruda" }
    , { name = "Rufina", value = DropDownList.stringValue "Rufina" }
    , { name = "Ruge Boogie", value = DropDownList.stringValue "Ruge Boogie" }
    , { name = "Ruluko", value = DropDownList.stringValue "Ruluko" }
    , { name = "Rum Raisin", value = DropDownList.stringValue "Rum Raisin" }
    , { name = "Ruslan Display", value = DropDownList.stringValue "Ruslan Display" }
    , { name = "Russo One", value = DropDownList.stringValue "Russo One" }
    , { name = "Ruthie", value = DropDownList.stringValue "Ruthie" }
    , { name = "Rye", value = DropDownList.stringValue "Rye" }
    , { name = "Sacramento", value = DropDownList.stringValue "Sacramento" }
    , { name = "Sahitya", value = DropDownList.stringValue "Sahitya" }
    , { name = "Sail", value = DropDownList.stringValue "Sail" }
    , { name = "Saira", value = DropDownList.stringValue "Saira" }
    , { name = "Saira Condensed", value = DropDownList.stringValue "Saira Condensed" }
    , { name = "Saira Extra Condensed", value = DropDownList.stringValue "Saira Extra Condensed" }
    , { name = "Saira Semi Condensed", value = DropDownList.stringValue "Saira Semi Condensed" }
    , { name = "Saira Stencil One", value = DropDownList.stringValue "Saira Stencil One" }
    , { name = "Salsa", value = DropDownList.stringValue "Salsa" }
    , { name = "Sanchez", value = DropDownList.stringValue "Sanchez" }
    , { name = "Sancreek", value = DropDownList.stringValue "Sancreek" }
    , { name = "Sansita", value = DropDownList.stringValue "Sansita" }
    , { name = "Sarabun", value = DropDownList.stringValue "Sarabun" }
    , { name = "Sarala", value = DropDownList.stringValue "Sarala" }
    , { name = "Sarina", value = DropDownList.stringValue "Sarina" }
    , { name = "Sarpanch", value = DropDownList.stringValue "Sarpanch" }
    , { name = "Satisfy", value = DropDownList.stringValue "Satisfy" }
    , { name = "Sawarabi Gothic", value = DropDownList.stringValue "Sawarabi Gothic" }
    , { name = "Sawarabi Mincho", value = DropDownList.stringValue "Sawarabi Mincho" }
    , { name = "Scada", value = DropDownList.stringValue "Scada" }
    , { name = "Scheherazade", value = DropDownList.stringValue "Scheherazade" }
    , { name = "Schoolbell", value = DropDownList.stringValue "Schoolbell" }
    , { name = "Scope One", value = DropDownList.stringValue "Scope One" }
    , { name = "Seaweed Script", value = DropDownList.stringValue "Seaweed Script" }
    , { name = "Secular One", value = DropDownList.stringValue "Secular One" }
    , { name = "Sedgwick Ave", value = DropDownList.stringValue "Sedgwick Ave" }
    , { name = "Sedgwick Ave Display", value = DropDownList.stringValue "Sedgwick Ave Display" }
    , { name = "Sevillana", value = DropDownList.stringValue "Sevillana" }
    , { name = "Seymour One", value = DropDownList.stringValue "Seymour One" }
    , { name = "Shadows Into Light", value = DropDownList.stringValue "Shadows Into Light" }
    , { name = "Shadows Into Light Two", value = DropDownList.stringValue "Shadows Into Light Two" }
    , { name = "Shanti", value = DropDownList.stringValue "Shanti" }
    , { name = "Share", value = DropDownList.stringValue "Share" }
    , { name = "Share Tech", value = DropDownList.stringValue "Share Tech" }
    , { name = "Share Tech Mono", value = DropDownList.stringValue "Share Tech Mono" }
    , { name = "Shojumaru", value = DropDownList.stringValue "Shojumaru" }
    , { name = "Short Stack", value = DropDownList.stringValue "Short Stack" }
    , { name = "Shrikhand", value = DropDownList.stringValue "Shrikhand" }
    , { name = "Siemreap", value = DropDownList.stringValue "Siemreap" }
    , { name = "Sigmar One", value = DropDownList.stringValue "Sigmar One" }
    , { name = "Signika", value = DropDownList.stringValue "Signika" }
    , { name = "Signika Negative", value = DropDownList.stringValue "Signika Negative" }
    , { name = "Simonetta", value = DropDownList.stringValue "Simonetta" }
    , { name = "Single Day", value = DropDownList.stringValue "Single Day" }
    , { name = "Sintony", value = DropDownList.stringValue "Sintony" }
    , { name = "Sirin Stencil", value = DropDownList.stringValue "Sirin Stencil" }
    , { name = "Six Caps", value = DropDownList.stringValue "Six Caps" }
    , { name = "Skranji", value = DropDownList.stringValue "Skranji" }
    , { name = "Slabo 13px", value = DropDownList.stringValue "Slabo 13px" }
    , { name = "Slabo 27px", value = DropDownList.stringValue "Slabo 27px" }
    , { name = "Slackey", value = DropDownList.stringValue "Slackey" }
    , { name = "Smokum", value = DropDownList.stringValue "Smokum" }
    , { name = "Smythe", value = DropDownList.stringValue "Smythe" }
    , { name = "Sniglet", value = DropDownList.stringValue "Sniglet" }
    , { name = "Snippet", value = DropDownList.stringValue "Snippet" }
    , { name = "Snowburst One", value = DropDownList.stringValue "Snowburst One" }
    , { name = "Sofadi One", value = DropDownList.stringValue "Sofadi One" }
    , { name = "Sofia", value = DropDownList.stringValue "Sofia" }
    , { name = "Song Myung", value = DropDownList.stringValue "Song Myung" }
    , { name = "Sonsie One", value = DropDownList.stringValue "Sonsie One" }
    , { name = "Sorts Mill Goudy", value = DropDownList.stringValue "Sorts Mill Goudy" }
    , { name = "Source Code Pro", value = DropDownList.stringValue "Source Code Pro" }
    , { name = "Source Sans Pro", value = DropDownList.stringValue "Source Sans Pro" }
    , { name = "Source Serif Pro", value = DropDownList.stringValue "Source Serif Pro" }
    , { name = "Space Mono", value = DropDownList.stringValue "Space Mono" }
    , { name = "Special Elite", value = DropDownList.stringValue "Special Elite" }
    , { name = "Spectral", value = DropDownList.stringValue "Spectral" }
    , { name = "Spectral SC", value = DropDownList.stringValue "Spectral SC" }
    , { name = "Spicy Rice", value = DropDownList.stringValue "Spicy Rice" }
    , { name = "Spinnaker", value = DropDownList.stringValue "Spinnaker" }
    , { name = "Spirax", value = DropDownList.stringValue "Spirax" }
    , { name = "Squada One", value = DropDownList.stringValue "Squada One" }
    , { name = "Sree Krushnadevaraya", value = DropDownList.stringValue "Sree Krushnadevaraya" }
    , { name = "Sriracha", value = DropDownList.stringValue "Sriracha" }
    , { name = "Srisakdi", value = DropDownList.stringValue "Srisakdi" }
    , { name = "Staatliches", value = DropDownList.stringValue "Staatliches" }
    , { name = "Stalemate", value = DropDownList.stringValue "Stalemate" }
    , { name = "Stalinist One", value = DropDownList.stringValue "Stalinist One" }
    , { name = "Stardos Stencil", value = DropDownList.stringValue "Stardos Stencil" }
    , { name = "Stint Ultra Condensed", value = DropDownList.stringValue "Stint Ultra Condensed" }
    , { name = "Stint Ultra Expanded", value = DropDownList.stringValue "Stint Ultra Expanded" }
    , { name = "Stoke", value = DropDownList.stringValue "Stoke" }
    , { name = "Strait", value = DropDownList.stringValue "Strait" }
    , { name = "Stylish", value = DropDownList.stringValue "Stylish" }
    , { name = "Sue Ellen Francisco", value = DropDownList.stringValue "Sue Ellen Francisco" }
    , { name = "Suez One", value = DropDownList.stringValue "Suez One" }
    , { name = "Sumana", value = DropDownList.stringValue "Sumana" }
    , { name = "Sunflower", value = DropDownList.stringValue "Sunflower" }
    , { name = "Sunshiney", value = DropDownList.stringValue "Sunshiney" }
    , { name = "Supermercado One", value = DropDownList.stringValue "Supermercado One" }
    , { name = "Sura", value = DropDownList.stringValue "Sura" }
    , { name = "Suranna", value = DropDownList.stringValue "Suranna" }
    , { name = "Suravaram", value = DropDownList.stringValue "Suravaram" }
    , { name = "Suwannaphum", value = DropDownList.stringValue "Suwannaphum" }
    , { name = "Swanky and Moo Moo", value = DropDownList.stringValue "Swanky and Moo Moo" }
    , { name = "Syncopate", value = DropDownList.stringValue "Syncopate" }
    , { name = "Tajawal", value = DropDownList.stringValue "Tajawal" }
    , { name = "Tangerine", value = DropDownList.stringValue "Tangerine" }
    , { name = "Taprom", value = DropDownList.stringValue "Taprom" }
    , { name = "Tauri", value = DropDownList.stringValue "Tauri" }
    , { name = "Taviraj", value = DropDownList.stringValue "Taviraj" }
    , { name = "Teko", value = DropDownList.stringValue "Teko" }
    , { name = "Telex", value = DropDownList.stringValue "Telex" }
    , { name = "Tenali Ramakrishna", value = DropDownList.stringValue "Tenali Ramakrishna" }
    , { name = "Tenor Sans", value = DropDownList.stringValue "Tenor Sans" }
    , { name = "Text Me One", value = DropDownList.stringValue "Text Me One" }
    , { name = "Thasadith", value = DropDownList.stringValue "Thasadith" }
    , { name = "The Girl Next Door", value = DropDownList.stringValue "The Girl Next Door" }
    , { name = "Tienne", value = DropDownList.stringValue "Tienne" }
    , { name = "Tillana", value = DropDownList.stringValue "Tillana" }
    , { name = "Timmana", value = DropDownList.stringValue "Timmana" }
    , { name = "Tinos", value = DropDownList.stringValue "Tinos" }
    , { name = "Titan One", value = DropDownList.stringValue "Titan One" }
    , { name = "Titillium Web", value = DropDownList.stringValue "Titillium Web" }
    , { name = "Trade Winds", value = DropDownList.stringValue "Trade Winds" }
    , { name = "Trirong", value = DropDownList.stringValue "Trirong" }
    , { name = "Trocchi", value = DropDownList.stringValue "Trocchi" }
    , { name = "Trochut", value = DropDownList.stringValue "Trochut" }
    , { name = "Trykker", value = DropDownList.stringValue "Trykker" }
    , { name = "Tulpen One", value = DropDownList.stringValue "Tulpen One" }
    , { name = "Turret Road", value = DropDownList.stringValue "Turret Road" }
    , { name = "Ubuntu", value = DropDownList.stringValue "Ubuntu" }
    , { name = "Ubuntu Condensed", value = DropDownList.stringValue "Ubuntu Condensed" }
    , { name = "Ubuntu Mono", value = DropDownList.stringValue "Ubuntu Mono" }
    , { name = "Ultra", value = DropDownList.stringValue "Ultra" }
    , { name = "Uncial Antiqua", value = DropDownList.stringValue "Uncial Antiqua" }
    , { name = "Underdog", value = DropDownList.stringValue "Underdog" }
    , { name = "Unica One", value = DropDownList.stringValue "Unica One" }
    , { name = "UnifrakturCook", value = DropDownList.stringValue "UnifrakturCook" }
    , { name = "UnifrakturMaguntia", value = DropDownList.stringValue "UnifrakturMaguntia" }
    , { name = "Unkempt", value = DropDownList.stringValue "Unkempt" }
    , { name = "Unlock", value = DropDownList.stringValue "Unlock" }
    , { name = "Unna", value = DropDownList.stringValue "Unna" }
    , { name = "Vampiro One", value = DropDownList.stringValue "Vampiro One" }
    , { name = "Varela", value = DropDownList.stringValue "Varela" }
    , { name = "Varela Round", value = DropDownList.stringValue "Varela Round" }
    , { name = "Vast Shadow", value = DropDownList.stringValue "Vast Shadow" }
    , { name = "Vesper Libre", value = DropDownList.stringValue "Vesper Libre" }
    , { name = "Vibes", value = DropDownList.stringValue "Vibes" }
    , { name = "Vibur", value = DropDownList.stringValue "Vibur" }
    , { name = "Vidaloka", value = DropDownList.stringValue "Vidaloka" }
    , { name = "Viga", value = DropDownList.stringValue "Viga" }
    , { name = "Voces", value = DropDownList.stringValue "Voces" }
    , { name = "Volkhov", value = DropDownList.stringValue "Volkhov" }
    , { name = "Vollkorn", value = DropDownList.stringValue "Vollkorn" }
    , { name = "Vollkorn SC", value = DropDownList.stringValue "Vollkorn SC" }
    , { name = "Voltaire", value = DropDownList.stringValue "Voltaire" }
    , { name = "VT323", value = DropDownList.stringValue "VT323" }
    , { name = "Waiting for the Sunrise", value = DropDownList.stringValue "Waiting for the Sunrise" }
    , { name = "Wallpoet", value = DropDownList.stringValue "Wallpoet" }
    , { name = "Walter Turncoat", value = DropDownList.stringValue "Walter Turncoat" }
    , { name = "Warnes", value = DropDownList.stringValue "Warnes" }
    , { name = "Wellfleet", value = DropDownList.stringValue "Wellfleet" }
    , { name = "Wendy One", value = DropDownList.stringValue "Wendy One" }
    , { name = "Wire One", value = DropDownList.stringValue "Wire One" }
    , { name = "Work Sans", value = DropDownList.stringValue "Work Sans" }
    , { name = "Yanone Kaffeesatz", value = DropDownList.stringValue "Yanone Kaffeesatz" }
    , { name = "Yantramanav", value = DropDownList.stringValue "Yantramanav" }
    , { name = "Yatra One", value = DropDownList.stringValue "Yatra One" }
    , { name = "Yellowtail", value = DropDownList.stringValue "Yellowtail" }
    , { name = "Yeon Sung", value = DropDownList.stringValue "Yeon Sung" }
    , { name = "Yeseva One", value = DropDownList.stringValue "Yeseva One" }
    , { name = "Yesteryear", value = DropDownList.stringValue "Yesteryear" }
    , { name = "Yrsa", value = DropDownList.stringValue "Yrsa" }
    , { name = "ZCOOL KuaiLe", value = DropDownList.stringValue "ZCOOL KuaiLe" }
    , { name = "ZCOOL QingKe HuangYou", value = DropDownList.stringValue "ZCOOL QingKe HuangYou" }
    , { name = "ZCOOL XiaoWei", value = DropDownList.stringValue "ZCOOL XiaoWei" }
    , { name = "Zeyada", value = DropDownList.stringValue "Zeyada" }
    , { name = "Zhi Mang Xing", value = DropDownList.stringValue "Zhi Mang Xing" }
    , { name = "Zilla Slab", value = DropDownList.stringValue "Zilla Slab" }
    , { name = "Zilla Slab Highlight", value = DropDownList.stringValue "Zilla Slab Highlight" }
    ]


type alias Model =
    { dropDownIndex : Maybe String
    , settings : Settings
    }


type Msg
    = UpdateSettings (String -> Settings) String
    | ToggleDropDownList String
    | DropDownClose


init : Settings -> ( Model, Cmd Msg )
init settings =
    ( Model Nothing settings, Cmd.none )


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        ToggleDropDownList id ->
            let
                activeIndex =
                    if (model.dropDownIndex |> Maybe.withDefault "") == id then
                        Nothing

                    else
                        Just id
            in
            ( { model | dropDownIndex = activeIndex }, Cmd.none )

        UpdateSettings getSetting value ->
            let
                settings =
                    getSetting value
            in
            ( { model | dropDownIndex = Nothing, settings = settings }, Cmd.none )

        DropDownClose ->
            ( { model | dropDownIndex = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    view_ model.dropDownIndex model.settings


view_ : Maybe String -> Settings -> Html Msg
view_ dropDownIndex settings =
    div
        [ class "settings"
        , style "user-select" "none"
        , onClick DropDownClose
        ]
        [ section (Just "Basic")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Font Family" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "font-family"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                { settings | font = x }
                            )
                        )
                        fontFamilyItems
                        settings.font
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Background color" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "background-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfBackgroundColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.backgroundColor
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Zoom Control" ]
                , div [ class "input-area" ]
                    [ label []
                        [ input
                            [ type_ "checkbox"
                            , checked (Maybe.withDefault True settings.storyMap.zoomControl)
                            , onClick
                                (UpdateSettings
                                    (\_ -> settings |> settingsOfZoomControl.set (Maybe.map not settings.storyMap.zoomControl))
                                    ""
                                )
                            ]
                            []
                        , text "Enabled"
                        ]
                    ]
                ]
            ]
        , section (Just "Editor")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Show Line Number" ]
                , div [ class "input-area" ]
                    [ label []
                        [ input
                            [ type_ "checkbox"
                            , checked
                                (settings.editor |> defaultEditorSettings |> .showLineNumber)
                            , onClick
                                (UpdateSettings
                                    (\_ -> settings |> settingsOfShowLineNumber.set (not (settings.editor |> defaultEditorSettings |> .showLineNumber)))
                                    ""
                                )
                            ]
                            []
                        , text "Enabled"
                        ]
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Word Wrap" ]
                , div [ class "input-area" ]
                    [ label []
                        [ input
                            [ type_ "checkbox"
                            , checked
                                (settings.editor |> defaultEditorSettings |> .wordWrap)
                            , onClick
                                (UpdateSettings
                                    (\_ ->
                                        settings |> settingsOfWordWrap.set (not (settings.editor |> defaultEditorSettings |> .wordWrap))
                                    )
                                    ""
                                )
                            ]
                            []
                        , text "Enabled"
                        ]
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Font Size" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "editor-font-size"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfFontSize.set (Maybe.withDefault 0 <| String.toInt x)
                            )
                        )
                        fontSizeItems
                        (String.fromInt <| (settings.editor |> defaultEditorSettings |> .fontSize))
                    ]
                ]
            ]
        , section (Just "Card Size")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Card Width" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "card-width"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfWidth.set (String.toInt x |> Maybe.withDefault 150)
                            )
                        )
                        baseSizeItems
                        (String.fromInt settings.storyMap.size.width)
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Card Height" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "card-height"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfHeight.set (String.toInt x |> Maybe.withDefault 45)
                            )
                        )
                        baseSizeItems
                        (String.fromInt settings.storyMap.size.height)
                    ]
                ]
            ]
        , section (Just "Color")
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Background Color1" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "activity-background-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfActivityBackgroundColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.activity.backgroundColor
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Foreground Color1" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "activity-foreground-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfActivityColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.activity.color
                    ]
                ]
            ]
        , section Nothing
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Background Color2" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "task-background-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfTaskBackgroundColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.task.backgroundColor
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Foreground Color2" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "task-foreground-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfTaskColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.task.color
                    ]
                ]
            ]
        , section Nothing
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Background Color3" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "story-background-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfStoryBackgroundColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.story.backgroundColor
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Foreground Color3" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "story-foreground-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfStoryColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.story.color
                    ]
                ]
            ]
        , section Nothing
        , section Nothing
        , div [ class "controls" ]
            [ div [ class "control" ]
                [ div [ class "label" ] [ text "Line Color" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "line-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfLineColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.line
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Label Color" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "label-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfLabelColor.set x
                            )
                        )
                        baseColorItems
                        settings.storyMap.color.label
                    ]
                ]
            , div [ class "control" ]
                [ div [ class "label" ] [ text "Text Color" ]
                , div [ class "input-area" ]
                    [ DropDownList.view ToggleDropDownList
                        "text-color"
                        dropDownIndex
                        (UpdateSettings
                            (\x ->
                                settings |> settingsOfTextColor.set x
                            )
                        )
                        baseColorItems
                        (settings.storyMap.color.text |> Maybe.withDefault "#111111")
                    ]
                ]
            ]
        ]


section : Maybe String -> Html Msg
section title =
    div
        [ if isNothing title then
            style "" ""

          else
            style "border-top" "1px solid #323B46"
        , if isNothing title then
            style "padding" "0px"

          else
            style "padding" "16px"
        , style "font-weight" "400"
        , style "margin" "0 0 16px 0px"
        ]
        [ div [ style "font-size" "1.2rem", style "font-weight" "600" ] [ text (title |> Maybe.withDefault "") ]
        ]
