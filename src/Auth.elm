module Auth exposing (Role(..), UserAuth, none)


type Role
    = User
    | Admin
    | None


type alias UserAuth =
    { username : String
    , sessionId : String
    , roles : List Role
    }


none : UserAuth
none =
    UserAuth "" "" [ None ]
