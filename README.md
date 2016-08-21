# elm-spa-template

## Intent of the Project

This project is something of a playground for the wonderful [Elm language](elm-lang.org) and how to build SPAs in particular.  Much of the structure is taken from the excellent [elm-mdl](https://github.com/debois/elm-mdl) and its [live demo](https://debois.github.io/elm-mdl/) in particular.

The bug arose during a period of chasing how to a) manage boilerplate relating to separate tabs in the SPA and b) how to be able to inject
context into the views of the contained tabs.  I did not want any of the tabs to reference parent state or to store copies of global state.
Instead (and the example in the current code is for the LogonTab) we pass extra parameters (context) into the view function.

There is a major convenience in having the tabs boilerplate defined as concisely as possible  

```elm
tabList : List Tab
tabList =
    [ { info = { tabName = "Tables", tabUrl = "tables", requiredRole = Auth.User }, tabViewMap = tableTabViewMap }
    , { info = { tabName = "Puppies", tabUrl = "puppies", requiredRole = Auth.Admin }, tabViewMap = .tabPuppies >> Tabs.Puppies.view >> App.map PuppiesMsg }
    , { info = { tabName = "Encoders", tabUrl = "encoders", requiredRole = Auth.User }, tabViewMap = .tabEncoders >> Tabs.Encoders.view >> App.map EncodersMsg }
    , { info = logonTabInfo, tabViewMap = logonTabViewMap }
    ]
```

As we are strongly typed and lists must be homogeneous, the tabViewMap element must all be of the same type (in this case ```Model -> Html Msg```)
The extra information we want to pass to the Logon view is whether we have been redirected to Logon while trying to access
another tab, the name of the Tab that is the intended target and the Auth Role required to be able to get to the desired tab.

This is done on line 214:
```elm
logonTabViewMap : Model -> Html Msg
logonTabViewMap model =
    let
        viewWithInjectedArgs =
            Tabs.Logon.view (model.selectedTab /= model.desiredTab) (tabName model.desiredTab) Auth.Admin
    in
        .tabLogon model |> viewWithInjectedArgs |> App.map LogonMsg
```

Now we do have a circular dependecy here - we want to reference the name of the desired tab and we look that up in the ```tabList```, but this function is a member of ```tabList```'s constructor.
