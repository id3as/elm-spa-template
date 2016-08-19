# elm-spa-template

## This project shows up what looks like an ELM compiler bug.

If you checkout the project and run ```elm-make src/Main.elm``` it compiles just fine.  However if you run ```Main.elm``` in 
via ```elm-reactor``` you get a crash in the following lines of javascript (lines 16687... in my browser):

```javascript
var _id3as$elm_spa_template$Main$tabInfoArray = _elm_lang$core$Array$fromList(_id3as$elm_spa_template$Main$tabInfos);
var _id3as$elm_spa_template$Main$tabInfos = A2(
	_elm_lang$core$List$map,
	function (_) {
		return _.info;
	},
	_id3as$elm_spa_template$Main$tabList);
```
The runtime cause is pretty clear - the first line references a second variable that isn't set till the line below...  
The corresponding lines in ```Mail.elm``` are on line 197:
```elm
tabPermissions : Array Auth.Role
tabPermissions =
    List.map .requiredRole tabInfos |> Array.fromList
```
If however you try to run the code in ```elm-repl``` you get the following behaviour:
```
adrian@Adrians-MacBook-Pro:~/dev/elm-spa-template(master⚡) » elm-repl
---- elm-repl 0.17.1 -----------------------------------------------------------
 :help for help, :exit to exit, more at <https://github.com/elm-lang/elm-repl>
--------------------------------------------------------------------------------
> import Main
/Users/adrian/dev/elm-spa-template/repl-temp-000.js:10017
       	onDocument: F3(on(document)),
       	                  ^

ReferenceError: document is not defined
    at /Users/adrian/dev/elm-spa-template/repl-temp-000.js:10017:20
    at Object.<anonymous> (/Users/adrian/dev/elm-spa-template/repl-temp-000.js:10034:2)
    at Object.<anonymous> (/Users/adrian/dev/elm-spa-template/repl-temp-000.js:17176:4)
    at Module._compile (module.js:413:34)
    at Object.Module._extensions..js (module.js:422:10)
    at Module.load (module.js:357:32)
    at Function.Module._load (module.js:314:12)
    at Function.Module.runMain (module.js:447:10)
    at startup (node.js:140:18)
    at node.js:1001:3

>
```


## Intent of the Project

This project is something of a playground for the wonderful Elm language and how to build SPAs in particular.  Much of the structure is 
taken from the excellent elm-mdl library.

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

Now we do have a circular dependecy here - we want to reference the name of the desired tab and we look that up in the ```tabList```, but this function is 
a member of the static constructor
