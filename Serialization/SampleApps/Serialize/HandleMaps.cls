Class SampleApps.Serialize.HandleMaps
{
/// Helper to set a MAP for PersistObject objtects...
/// This can be done more cleanly importing the JSON map from a file.
ClassMethod SetPersistObjectMAP1() as %Status
{
	set tMAPS = {
				  "maps": [
				    {
				      "map": "MAP1",
				      "className": "SampleApps.Serialize.PersistObject",
				      "type": "export",
				      "typeGroups": [
				        {
				          "typeGroup": "1",
				          "groupDesc": "basic",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "cod",
				              "settings": "codigo,,-1,,,"
				            },
				            {
				              "from": "description",
				              "settings": "descripcion,,-1,,,"
				            },
				            {
				              "from": "start",
				              "settings": "inicio,exportDate,-1,,,"
				            },
				            {
				              "from": "yearEnd",
				              "settings": "añofinal,,-1,,,"
				            }
				          ]
				        },
				        {
				          "typeGroup": "2",
				          "groupDesc": "list",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "colours",
				              "settings": "colores,,-1,,,"
				            }
				          ]
				        },
				        {
				          "typeGroup": "4",
				          "groupDesc": "object",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "MapTesting",
				              "settings": "MapTesting,,1,SampleApps.Serialize.MapTesting,SampleApps.Serialize.MapTesting.CustomMaps,ExpMapTestingCustomMAP1"
				            }
				          ]
				        }
				      ]
				    },
				    {
				      "map": "MAP1",
				      "className": "SampleApps.Serialize.PersistObject",
				      "type": "import",
				      "typeGroups": [
				        {
				          "typeGroup": "1",
				          "groupDesc": "basic",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "codigo",
				              "settings": "cod,,-1,,,"
				            },
				            {
				              "from": "descripcion",
				              "settings": "description,,-1,,,"
				            },
				            {
				              "from": "inicio",
				              "settings": "start,importDate,-1,,,"
				            },
				            {
				              "from": "añofinal",
				              "settings": "yearEnd,,-1,,,"
				            }
				          ]
				        },
				        {
				          "typeGroup": "2",
				          "groupDesc": "list",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "colores",
				              "settings": "colours,,-1,,,"
				            }
				          ]
				        },
				        {
				          "typeGroup": "4",
				          "groupDesc": "object",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "MapTesting",
				              "settings": "MapTesting,,1,SampleApps.Serialize.MapTesting,SampleApps.Serialize.MapTesting.CustomMaps,ImpMapTestingCustomMAP1"
				            }
				          ]
				        }
				      ]
				    }
				  ]
				}
	set tSC = ##class(OPNLib.Serialize.Util).ImportMapsFromJSON(tMAPS)
	
	quit tSC
}

/// Same as MAP1 but getting rid of some properties that won't be exported/imported: yearEnd  (basic), colours (list) and MapTesting (object reference/relationship - parent)
ClassMethod SetPersistObjectMAP2() as %Status
{
	set tMAPS = {
				  "maps": [
				    {
				      "map": "MAP2",
				      "className": "SampleApps.Serialize.PersistObject",
				      "type": "export",
				      "typeGroups": [
				        {
				          "typeGroup": "1",
				          "groupDesc": "basic",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "cod",
				              "settings": "codigo,,-1,,,"
				            },
				            {
				              "from": "description",
				              "settings": "descripcion,,-1,,,"
				            },
				            {
				              "from": "start",
				              "settings": "inicio,exportDate,-1,,,"
				            }
				          ]
				        }
				      ]
				    },
				    {
				      "map": "MAP2",
				      "className": "SampleApps.Serialize.PersistObject",
				      "type": "import",
				      "typeGroups": [
				        {
				          "typeGroup": "1",
				          "groupDesc": "basic",
				          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
				          "propertiesMappings": [
				            {
				              "from": "codigo",
				              "settings": "cod,,-1,,,"
				            },
				            {
				              "from": "descripcion",
				              "settings": "description,,-1,,,"
				            },
				            {
				              "from": "inicio",
				              "settings": "start,importDate,-1,,,"
				            }
				          ]
				        }
				      ]
				    }
				  ]
				}
	set tSC = ##class(OPNLib.Serialize.Util).ImportMapsFromJSON(tMAPS)
	
	quit tSC
}


/// Helper to set a MAP for MapTesting objects...
/// This can be done more cleanly importing the JSON map from a file.
ClassMethod SetMapTestingMAP1() as %String
{
	set tMAPS = {
		  "maps": [
		    {
		      "map": "MAP1",
		      "className": "SampleApps.Serialize.MapTesting",
		      "type": "export",
		      "typeGroups": [
		        {
		          "typeGroup": "0",
		          "groupDesc": "Uncovered",
		          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
		          "propertiesMappings": [
		            {
		              "from": "stdListOfSomething",
		              "settings": "stdListOfSomething,,-1,,,"
		            }
		          ]
		        },
		        {
		          "typeGroup": "1",
		          "groupDesc": "basic",
		          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
		          "propertiesMappings": [
		            {
		              "from": "code",
		              "settings": "codigo,,-1,,,"
		            },
		            {
		              "from": "dateTest",
		              "settings": "fecha,exportDate,-1,,,"
		            },
		            {
		              "from": "description",
		              "settings": "descripcion,,-1,,,"
		            },
		            {
		              "from": "floatNumber",
		              "settings": "numeroDecimal,,-1,,,"
		            },
		            {
		              "from": "timestampTest",
		              "settings": "fechaHora,exportTimeStamp,-1,,,"
		            },
		            {
		              "from": "timeTest",
		              "settings": "hora,exportTime,-1,,,"
		            }
		          ]
		        },
		        {
		          "typeGroup": "2",
		          "groupDesc": "list",
		          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
		          "propertiesMappings": [
		            {
		              "from": "listOfSomething",
		              "settings": "lista,,-1,,,"
		            }
		          ]
		        }
		      ]
		    },
		    {
		      "map": "MAP1",
		      "className": "SampleApps.Serialize.MapTesting",
		      "type": "import",
		      "typeGroups": [
		        {
		          "typeGroup": "0",
		          "groupDesc": "Uncovered",
		          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
		          "propertiesMappings": [
		            {
		              "from": "stdListOfSomething",
		              "settings": "stdListOfSomething,,-1,,,"
		            }
		          ]
		        },
		        {
		          "typeGroup": "1",
		          "groupDesc": "basic",
		          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
		          "propertiesMappings": [
		            {
		              "from": "codigo",
		              "settings": "code,,-1,,,"
		            },
		            {
		              "from": "fecha",
		              "settings": "dateTest,importDate,-1,,,"
		            },
		            {
		              "from": "descripcion",
		              "settings": "description,,-1,,,"
		            },
		            {
		              "from": "numeroDecimal",
		              "settings": "floatNumber,,-1,,,"
		            },
		            {
		              "from": "fechaHora",
		              "settings": "timestampTest,importTimeStamp,-1,,,"
		            },
		            {
		              "from": "hora",
		              "settings": "timeTest,importTime,-1,,,"
		            }
		          ]
		        },
		        {
		          "typeGroup": "2",
		          "groupDesc": "list",
		          "infoSettings": "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>",
		          "propertiesMappings": [
		            {
		              "from": "lista",
		              "settings": "listOfSomething,,-1,,,"
		            }
		          ]
		        }
		      ]
		    }
		  ]
		 }

	set tSC = ##class(OPNLib.Serialize.Util).ImportMapsFromJSON(tMAPS)
	quit tSC
}

}