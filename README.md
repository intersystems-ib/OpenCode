
# OpenCode
## Serialization Project

This project is just an attempt to implement a feature to serialize objects (persistent or just registered) with **two main goals in mind** :

1. Avoid the need of changing the class definition if there are changes in the names of serialized properties or even in the criteria to serialize the object
2. Being able to serialize/deserialize to/from  multiple formats (JSON, CSV, XML, custom,…), also _without touching the class definition itself_.


> **WARNING**: This code it's not supported in any way. It's been developed as a proof of concept for myself and because there is no JSON.Adaptor yet (coming soon!). Be careful and count on that can (likely will) fail if you even consider using it in some kind of production environments. Use it, play with it, change it or improve it at your own discretion.
This said and understood, you can follow on... ;-)

### How to get universal serialization feature in your classes

To get the full features, you just have to import in your system 4 classes (1) : `OPNLib.Serialize.Adaptor`, `OPNLib.Serialize.Util`, `OPNLib.Serialize.TemplateOPNLib.Serialize.Template` and `OPNLib.Serialize.TemplateOPNLib.Serialize.TemplateCSV` (this last one it's not yet finished in Release 1/2018-04).

(1) Actually you would just need `OPNLib.Serialize.Adaptor` if you just need JSON serialization

### Start Serializing

To enable this feature for a class, that class has to extend from `OPNLib.Serialize.Adaptor`. That'll be the only time that you'll have to touch your class for this feature. After that moment your class will be able to export/import JSON objects and it will accept future serialization mechanisms that you decide to implement without having to make more changes to class definition.

---

_**Example:**_ 
_(Example assumes that your classname is `SampleApps.Serialize.MapTesting`, that is a persistent class and that you already extended it to inherit from `OPNLib.Serialize.Adaptor`)_

From the terminal,in the name space where your class exists :

```javascript
     Set obj = ##class(SampleApps.Serialize.MapTesting).%OpenId(1)
     Set objJSON = obj.Export()
     Do objJSON.%ToJSON()

     Set newObj = ##class(SampleApps.Serialize.MapTesting).%New()
     Do newObj.Import(objJSON)
     set tSC = newObj.%Save()
     write newOBJ.%Id()
 ```
We will have a new instance of _`SampleApps.Serialize.MapTesting`_ object, a clone of the one with ID=1. This was the example, we can modify it before saving or just discarding.

---
 
### What _`OPNLib.Serialize.Adaptor`_ provides?

Basically when we compile a class that inherits from our Adaptor, the class will have 4 new generic instance methods: `Export` and `Import` (that will act as dispatchers), and `exportStd` and  `importStd` (that implements the default logic to serialize/deserialize in/from JSON format). Also, and very important, it will be created a generic mapping between each of the properties in the Caché object  and its equivalent serialized. That class mapping will be stored in 2 internal globals: `^MAPS` and `^MAPSREV` (Globals structure is explained in more detail in class documentation).
 
### How is the mapping built at first place?

We can have several maps for a particular class (for example to exchange data from an object  with different systems or organizations, we might need to export or import some properties but not others, or apply different conversions to some values, or name the properties differently , etc…).

By default,  all classes that inherit from `OPNLib.Serialize.Adaptor` will have an associated default map: `MAP0`, that will make a direct mapping regarding property names (same name for target an source property).

Each property will be categorized in group types, numbered from `1` to `6`. Currently these are the group types supported :

Code | Category | Description
---- | ------------- | -----------
1 | Basic type | It'll include %String, %Integer, %Date, %Datetime,%Timestamp,%Decimal,%Float,… and most of the basic types defined in the %Library package 
2 | List collection | It'll include collections of datatypes of type %Collection.ListOfDT
3 | Array collection | It'll include collections of datatypes of type %Collection.ArrayOfDT
4 | Object Reference | A property that reference a custom object not in %* libraries 
5 | Array of objects and Relationship objects | A property of type %Collection.ArrayOfObject or a property of type %RelationshipObject with cardinality many or children
6 | List of Objects | A property of type %Collection.ListOfObject
7 | Stream | Properties of type %Stream.*, %CSP.*stream*,…

During map generation, by default, the `Adaptor` sets export and import conversion methods for dates, datetimes, timestamps and streams (which are exported as a stream in base64).

---
**MAPS / MAPSREV globals' structure**

^MAP("*classname*","*mapname*",_GroupType[1..6]_,"_Source Property Name_") = *List Element*

 *List Element*:
 
  [1] *Target Property Name*
  
  [2] *Convert Method*
  
  [3] *Drill down*
  
  [4] *Class of referenced object(s)*
  
  [5] *Template Class that implement export/import logic*
  
  [6] *Method Class to dispatch for export/import*

---

This is an example of two nodes in global `^MAPS` and their counterpart in `^MAPSREV`:
```
...
...
^MAPS("SampleApps.Serialize.MapTesting","MAP0",4,"reference")=$lb("referencia","","1","SampleApps.Serialize.MapTesting","","")
^MAPS("SampleApps.Serialize.MapTesting","MAP0",5,"arrayOfObjects")=$lb("arrayDeObjectos","","1","SampleApps.Serialize.MapTesting","","")
...
...
^MAPSREV("SampleApps.Serialize.MapTesting","MAP0",4,"referencia")=$lb("reference","","1","SampleApps.Serialize.MapTesting","","")
^MAPSREV("SampleApps.Serialize.MapTesting","MAP0",5,"arrayDeObjetos")=$lb("arrayOfObjects","","1","SampleApps.Serialize.MapTesting","","")
...
...
```

### How could we configure our mapping for serialization?

We can have as much mapping definitions for a class as we need. An easy way to start to define our customized maps is exporting the default `MAP0` and importing it again with a different name, then we can make changes in the map regarding the properties that should be exported /imported, names, conversor methods to apply. To do this, we can modify directly in the global, or do it programatically (See `OPNLib.Serialize.Util` class for tools to export/import maps, get / set property mappings,etc…)

---
**Example:**

```javascript
 set tClassName = "SampleApps.Serialize.MapTesting"
 ;Assuming the class has only 1 map: MAP0, used in ^MAPS and ^MAPSREV
 set json = ##class(OPNLib.Serialize.Util).ExportMapsToJSON(tClassName)
 
 ;change name of map from MAP0 to MAP1 
 set json.maps.%Get(0).map = "MAP1"  //change mapname entry in corresponding to ^MAPS
 set json.maps.%Get(1).map = "MAP1" //change mapname entry corresponding to ^MAPSREV

 ;Overwrite map (2) of SampleApps.Serialize.MapTesting with map in object:json
 set tSC = ##class(OPNLib.Serialize.Util).ImportMapsFromJSON(json,2,tClassName) 

 ;Get settings of one of the properties. They are returned in a json object
 set propExprt = ##class(SampleApps.Serialize.MapTesting).GetMappedPropSettings("code","MAP1",tClassName,1)

 ;We change the targetPropertyName setting
 set $ListUpdate(propExprt.settings,1) = "codeAccepted"
 do ##class(SampleApps.Serialize.MapTesting).SetMappedPropSettings("code",propExprt,"MAP1",tClassName,1)

 ;Now we open and object and export it using new mapping
 set obj = ##class(SampleApps.Serialize.MapTesting).%OpenId(1)
 set objJSON = obj.Export(,,,,"MAP1")
 do objJSON.%ToJSON()

```
---

We also have the possibility of changing a bit the way in which default map `MAP0` is generated :
* Change the name of default map. 
  * Use parameter `EXPTDEFAULTMAP` to indicate a name for default map before compiling the class 
* Excluding  properties 
  * if we don't want to export some   properties, we should include them (comma separated list) in the parameter : `EXPTEXCLUDEPROP` before compiling the class
* Include  object references
  * Even when we decide not to drill down through referenced objects, we still have the chance to export the object reference itself if we set the parameter `EXPTINCLUDEOREF` to 1.
* Drill down levels
  * Use `EXPTDRILLDOWN`To indicate up to what number of levels that the export/import logic should follow through object references. 0 means no drill down. A positive number(n) means to drill down n times through the chain of references.

## How did it work the default mechanism?

Both methods, `Export` and `Import` will call the generated methods: `exportStd` and `importStd` respectively. These two methods will go through the global `^MAPS` and `^MAPSREV` respectively, looking for the properties to export /import and applying the required conversions. 
Both methods work over an already instantiated method. This is particularly interesting for import, as we can have an object in memory with some data already and import the rest of the data from a serialized object. The import mechanism will replace with the new content the properties contained in the serialization but will preserve other properties already set in the instance that are not included in the serialization that we import.

This way of working give us the flexibility of using different mappings using the same autogenerated code but it can have a penalty in performance if we use it massively in loops or in very high concurrency use cases. Anyway, better test in such scenarios. 

## Some considerations about performance 

As it was already mentioned, the default mechanism resolve the mapping sets at real time, trasversing a global to set the properties to export/import targets. That means that this mechanism will always be slower than if we already had that settings resolved at compile time. In order to provide that functionality, we can use the Template classes. 

## What are the template classes for?

The templates classes allow us to generate the logic to export/import at compile time.
This have benefits over performance but comes at the price of having to use a different class for each type of serialization format and mapping.

Anyway, the primary class is not affected and doesn't have to be changed no matter how many templates define to handle the serialization of its objects.

Using these classes is very easy. Let's see an example:

---
**Example:**

We want to be able to export `SampleApps.Serialize.PersistObject` to JSON, but just some of the properties: `cod`, `description` and `start`. We want to project those properties, for example, in Spanish, as: `codigo`, `descripcion` and `inicio` respectively.

We design the required map, that we call `MAP2` and load it:

```javascript
do ##class(SampleApps.Serialize.HandleMaps).SetPersistObjectMAP2()
```
Loa
Then, we create a new class that we can call `SampleApps.Serialize.PersistObject.generatedMAP2` that extends `OPNLib.Serialize.Template` and change the required parameters. This would be the class definition:
```javascript
Class SampleApps.Serialize.PersistObject.generatedMAP2 Extends OPNLib.Serialize.Template
{
Parameter EXPTASSOCIATEDCLASS = "SampleApps.Serialize.PersistObject";
Parameter EXPTMAP = "MAP2";
}
```
We have just set the associated class and the MAP to apply. Then, we will have 2 methods auto-generated: `Export` and `Import` with the code required to export/import from/to JSON format objects of type `PersistObject` following the `MAP2` designed.
The disadvantage with this approach is that we will have to recompile each time the mapping changes. The advantage is that it will be a bit quicker than the standard approach as all the property sets are static as have been resolved at compile time.

As you can see, the class that stores the `PersistObject` objects, is not aware of these export/import classes and methods and it doesn't require any modification.

This way, once our template class is compiled, we could do:

```javascript
 set cMAP1 = "SampleApps.Serialize.PersistObject.generatedMAP1"
 //...
 set mObject = ##class(SampleApps.Serialize.PersistObject).%OpenId(1)
 set json = mObject.Export(cMAP,"Export")
 do json.%ToJSON()
 {
  "codigo":372732612,
  "descripcion":"Q8845",
  "inicio":"1953-03-04",
  "añofinal":133788319,
  "colores":"B9211\tC8958\tY489\tC5123",
  "MapTesting":
          {
           "codigo":462711925,
           "fecha":"1932-03-30",
           "descripcion":"F1357",
           "numeroDecimal":5303.31,
           "fechaHora":"1956-07-25 04:52:33",
           "hora":"17:47:32",
           "lista":"J9796\tZ2412\tN4278"
          }
 }
```
---

## Sample Application
There are some classes that I used to build some of the examples. There are others testing other features. You can take a look at them in the package `SampleApps.Serialize`

## REST Services
Just a bunch of REST services to make use and test this functionality. You can find them in `SampleApps.Serialize.REST`class:

Service | Path | HTTP Method 
------- | ---- | -----------
Get an object up to a drilldown level in JSON format following a particular map especification | /object/json/:class/:id/:ddlevel/:map | GET
Get an object up to a drilldown level in JSON format following the default map | /object/json/:class/:id/:ddlevel | GET
Get an object in JSON format following the default map and default drilldown especs | /object/json/:class/:id" | GET
Load an object from JSON using a particular map and drilldown especifications | /object/json/:class/:ddlevel/:map | POST
Load an object from JSON using its default map and a particular drilldown especifications | /object/json/:class/:ddlevel | POST
Load an object from JSON using its default map | /object/json/:class | POST
Load an object from JSON using its default map and which class is included in _classname_ property of the JSON document | /object/json | POST
Get a serialized object in format especified by serialization method and with a especified drilldown level | /object/serial/:templateclass/:serializationmethod/:class/:id/:ddlevel | GET
Get a serialized object in format especified by serialization method | /object/serial/:templateclass/:serializationmethod/:class/:id |GET
Load object from a particular class, and with an especified drilldown level, from a serialized stream | /object/serial/:templateclass/:serializationmethod/:class/:ddlevel | POST 
Load object from a particular class from a serialized stream | /object/serial/:templateclass/:serializationmethod/:class | POST
Update an object from JSON input | /object/json/:class/:id | PUT
Delete an object with certain ID | NOT YET IMPLEMENTED | DELETE
Update an object from serialized input | (NOT YET IMPLEMENTED) /object/serial/:templateclass/:serializationmethod/:class/:id | PUT
Get a JSON document that contains certain type of MAPS (export or import) for a particular class | /map/:class/:map/:type | GET
Get a JSON document that contains export and import definition of a MAP name associated with a particular class | /map/:class/:map | GET
Get a JSON document that contains all the maps' definitions for a class | /map/:class | GET
Set export/import MAPS (all or those comma-separated especified in Filter) from a JSON document | /map/:override/:filter | POST
Set export/import MAPS from a JSON document (overriding the existing ones if any) | /map" | POST
Set the export/import MAPS from a JSON document to a different target class (all or those especificied in filter) | /map/chgclass/:targetclass/:override/:filter | POST
Set the export/import MAPS from a JSON document to a different target class | /map/chgclass/:targetclass | POST


## End

I hope this code can help you in any way.

Enjoy!
_Jose-Tomas Salvador_
