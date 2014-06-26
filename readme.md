AshAid
======

Set of tools aimed to aid construction of application based on top of the Ash framework.

Feature list:
------------

* JSON-based description of the engine and entities configuration;
* Engine and Entity state machines support
* Support presets in the json descriptions

Example:
-------

systems.json:
	{
	     "ExampleSystem":100
	}
scene.json:
	 {
	     "root": [
	         {
	             "name": "Entity1",
	             "ExampleComponent":""
	         }
	     ]
	 }
Main.hx:
	class Main extends ApplicationBase {
		public function new() {
			super();
			builder.configureSystemsFromFile("systems.json");
			builder.buildSceneFromFile('scene.json');
		}
	}

Presets example:
----------------

scene.json:
	 {
	     "root": [
	         {
	             "name": "Entity1",
	             "protos":["preset"]
	         },
	         {
                 "name": "Entity2",
                 "protos":["preset"]
             }
	     ]
	     "preset": {
	        "ExampleComponent":""
	        }
	 }

Component filling example:
-------------------------

 scene.json:
 	 {
 	     "preset": {
 	        "ExampleComponent":{
				numberField: 10,
				colorIntField: "0x909090",
				arrayField:[1, 2, 3],
				stringField:"String",
				"protos":["AnotherPreset"],
				"entity":"entity:EntityName"
 	        }
        }
 	 }