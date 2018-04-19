# OpenCode
## Serialization Project

This project is just an attempt to implement a feature to serialize objects (persistent or just registered) with **two main goals in mind** :

1. Avoid the need of changing the class definition if there are changes in naming of serialized properties or even in the criteria to serialize the object
2. Being able to serialize/deserialize to/from  multiple formats (JSON, CSV, XML, custom,…), also _without touching the class definition itself_.

### How to get universal serialization feature in your classes

To get the full features, you just have to import in your system 4 classes (1) : _OPNLib.Serialize.Adaptor, OPNLib.Serialize.Util and OPNLib.Serialize.TemplateOPNLib.Serialize.TemplateCSV_.

(1) Actually you would just need _OPNLib.Serialize.Adaptor_ if you just need JSON serialization

### Start Serializing

To enable this feature for a class, that class has to extend from _OPNLib.Serialize.Adaptor_. That'll be the only time that you'll have to touch your class for this feature. After that moment your class will be able to export/import JSON objects and it will accept future serialization mechanisms that you decide to implement without having to make more changes to class definition.

---

_**Example:**_ 
_(Example assumes that your classname is `SampleApps.Serialize.MapTesting`, that is a persistent class and that you already extended it to inherit from `OPNLib.Serialize.Adaptor`)_

From the terminal,in the name space where your class exists :

```javascript
     Set obj = ##class(SampleApps.Serialize.MapTesting).%OpenId(1)
     Set objJSON = obj.Export()
     Do objJSON.%ToJSON()

     Set newObj = ##class(SampleApps.Serialize.MapTesting).%New()
     Do newObj.Import(,,objJSON)
     set tSC = newObj.%Save()
     write newOBJ.%Id()
 ```
We will have a new instance of _`SampleApps.Serialize.MapTesting`_ object, a clone of the one with ID=1. This was the example, we can modify it before saving or just discarding.

---
 
### What _`OPNLib.Serialize.Adaptor`_ provides?

Basically when we compile a class that inherits from our Adaptor, the class will have 4 new generic instance methods: `Export` and `Import` (that will act as dispatchers), and `exportStd` and  `importStd` (that implements the default logic to serialize/deserialize in/from JSON format). Also, and very important, it will be created a generic mapping between each of the properties in the Caché object  and its equivalent serialized. That class mapping will be stored in 2 internal globals: `^MAPS` and `^MAPSREV` (Globals structure is explained in more detail in class documentation).
 
### How is the mapping built at first place?

We can have several maps for a particular class (for example to exchange data from an object  with different systems or organizations, we might need to export or import some properties but not others, or apply different conversions to some values, or name the properties differently , etc…).

By default,  all classes that inherit from `OPNLib.Serialize.Adaptor` will have an associated default map: MAP0, that will make a direct mapping regarding property names (same name for target an source property).

Each property will be categorized in group types, numbered from 1 to 6. Currently these are the group types supported :

Code | Category | Description
---- | ------------- | -----------
1 | Basic type | It'll include %String, %Integer, %Date, %Datetime,%Timestamp,%Decimal,%Float,… and most of the basic types defined in the %Library package 
2 | List collection | It'll include collections of datatypes of type %Collection.ListOfDT
3 | Array collection | It'll include collections of datatypes of type %Collection.ArrayOfDT
4 | Object Reference | A property that reference a custom object not in %* libraries 
5 | Array of objects and Relationship objects | A property of type %Collection.ArrayOfObject or a property of type %RelationshipObject with cardinality many or children
6 | List of Objects | A property of type %Collection.ListOfObject
7 | Stream | Properties of type %Stream.*, %CSP.*stream*,…

During map generation, by default, the Adaptor sets export and Import conversion methods for dates and streams (which are exported as a stream in base64).

---
**MAP0 structure**

MAP0("*classname*",_GroupType[1..6]_,"_Source Property Name_") = *List Element*
 *List Element*:
 > Pos 1 *Target Property Name*
 > Pos 2
 > Pos 3
 > Pos 4

---

### How could we configure our mapping for serialization?

We can have as much mapping definitions for a class as we need. An easy way to start to define our customized maps is exporting the default MAP0 and importing it again with a different name, then we can make changes in the map regarding the properties that should be exported /imported, names, conversor methods to apply (***) 
(***) See OPNLIB.SERIALIZE.ADAPTOR.Serialize.Util library for tools to export/import maps, get / set property mappings,etc…)

We also have the possibility of changing a bit the way in which default map MAP0 is generated :
	• Change the name of default map. 
		○ Use parameter EXPTDEFAULTMAP to indicate a name for default map before compiling the class 
	• Excluding  properties 
		○ if we don't want to export some   properties, we should include them in the parameter : EXPTEXCLUDEPROP before compiling the class (the properties will be in a comma separated list)
	• include  object references
		○ Even when we decide not to drill down through referenced objects, we still have the chance to export the object reference itself if we set the parameter EXPTINCLUDEOREF to 1.
	• Drill down levels
		○ To indicate up to what number of levels we want the export mechanism to drill down through object references. 0 means no drill down. A positive number(n) means to drill down n times through the chain of references.

Example:

<<<create MAP1 from MAP0 >>>

<<<USING MAP0 and MAP1 from the same object instance >>>

How did it work the default mechanism?

Both methods, export and Import will call the generated methods: exportStd and imoortStd respectively. These two methods will go through the global ^MAPS and ^MAPSREV respectively, looking for the properties to export /import and applying the required conversions. 
Both methods work over an already instantiated method. This is particularly important for import, as we can have an object in memory with some data already and import the rest of the data from a serialized object. The import mechanism will replace with the new content the properties contained in the serialization but will preserve other properties already set in the instance that are not included in the serialization that we import.

Example:

<< import a JSON with just some properties in an object where we already have some others set >>>

This way of working give us the flexibility of using different mappings using the same autogenerated code but it can have a penalty in performance if we use it massively in loops or in very high concurrency use cases. Anyway,better test in such scenarios. 

Some considerations about performance 

As we already mentioned, the default mechanism resolve the mapping sets at real time, trasversing a global to set the properties to export/import  targets. That means that this mechanism will always be slower than if we already had that settings resolved at compile time. In order to provide that functionality, we can use the Template classes. 

 What are the template classes for?

The templates classes allow us to generate the logic to export /import at compile time.
This have benefits over performance but comes at the price of having to use a different class for each type of serialization format and mapping.

Anyway, the primary class is not affected and doesn't have to be changed no matter how many templates define to handle the serialization of its objects.

Example :

<<< define and use different template classes, for different maps in JSON and also for different serialization (CSV)
>>> 
