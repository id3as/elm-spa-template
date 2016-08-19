module MyTest exposing (..)


type alias Model =
    { a : Int
    , b : String
    , c : Bool
    }


init : Model
init =
    Model 1 "abc" True


getC : Model -> Bool
getC =
    .c


getCString : Model -> String
getCString =
    .c >> toString
