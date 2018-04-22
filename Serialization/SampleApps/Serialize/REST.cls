/// REST services to test Serialize application
/// test/<classname>/<id>/<DrillDown Level> : it'll generate the JSON serialization of object ID of class <classname>, drilling down <dd level>s for properties 
///                                           that reference other objects (if drill down is not prohibited by map definition)
///	/request: test service
/// /echo: test service
Class SampleApps.Serialize.REST Extends %CSP.REST
{
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!--Get object as JSON format-->
<Route Url="/object/json/:class/:id/:ddlevel/:map" Method="GET" Call="GetJSON" />
<Route Url="/object/json/:class/:id/:ddlevel" Method="GET" Call="GetJSON" />
<Route Url="/object/json/:class/:id" Method="GET" Call="GetJSON" />

<!-- Load JSON in persistent object in DB -->
<Route Url="/object/json/:class/:ddlevel/:map" Method="POST" Call="IngestJSON" />
<Route Url="/object/json/:class/:ddlevel" Method="POST" Call="IngestJSON" />
<Route Url="/object/json/:class" Method="POST" Call="IngestJSON" />
<Route Url="/object/json" Method="POST" Call="IngestJSON" />

<!-- Update object -->
<Route Url="/object/json/:class/:id" Method="PUT" Call="UpdateJSON" />

<!-- Delete object -->
<!-- NYI
<Route Url="/object/:class/:id" Method="DELETE" Call="DeleteObject" />
-->

<!-- Get serial object in format especified by serializationmethod -->
<Route Url="/object/serial/:templateclass/:serializationmethod/:class/:id/:ddlevel" Method="GET" Call="GetSerialization" />
<Route Url="/object/serial/:templateclass/:serializationmethod/:class/:id" Method="GET" Call="GetSerialization" />

<!-- Load serial object in persistent object in DB -->
<Route Url="/object/serial/:templateclass/:serializationmethod/:class/:ddlevel" Method="POST" Call="IngestSerialization" />
<Route Url="/object/serial/:templateclass/:serializationmethod/:class" Method="POST" Call="IngestSerialization" />

<!-- Update object -->
<!-- NOT YET IMPLEMENTED
<Route Url="/object/serial/:templateclass/:serializationmethod/:class/:id" Method="PUT" Call="UpdateSerial" />
-->

<!-- Get a JSON document that contains export/import MAPs associated to a particular :class -->
<Route Url="/map/:class/:map/:type" Method="GET" Call="GetStdMap"/>
<Route Url="/map/:class/:map" Method="GET" Call="GetStdMap"/>
<Route Url="/map/:class" Method="GET" Call="GetStdMap"/>

<!-- Set export/import MAPs from a JSON document -->
<Route Url="/map/:override/:filter" Method="POST" Call="LoadStdMap"/>
<Route Url="/map" Method="POST" Call="LoadStdMap"/>
<Route Url="/map/chgclass/:targetclass/:override/:filter" Method="POST" Call="LoadStdMapToOther"/>
<Route Url="/map/chgclass/:targetclass" Method="POST" Call="LoadStdMapToOther"/>

<!-- Test methods - GET -->
<Route Url="/request" Method="GET" Call="Request"/>

<!-- Test methods - POST -->
<Route Url="/echo" Method="POST" Call="Echo"/>
<Route Url="/echojson" Method="POST" Call="EchoJSON"/>
<Route Url="/echo/:txt" Method="POST" Call="Echo"/>
</Routes>
}

ClassMethod EchoJSON() as %Status
{
	set %response.ContentType = "application/json"
	set tJSON = {}.%FromJSON(%request.Content)
	write tJSON.%ToJSON()
	quit 1
}
// pType --> [export|import]
ClassMethod GetStdMap(pClass as %String,pMap as %String="",pType as %String="") as %Status
{
    If $Get(%request.CgiEnvs("HTTP_ACCEPT"))="application/json" 
    {
    	set %response.ContentType = "application/json"
	}
	
	set tObj = ##class(OPNLib.Serialize.Util).ExportMapsToJSON(pClass,pMap,pType)
	
	if ($IsObject(tObj) && (tObj.%Size()'=0))
	{
		write tObj.%ToJSON()
	}
	else 
	{
		write {"status":"0 - There are no maps for that class"}.%ToJSON()
	}
	quit $$$OK
}

ClassMethod LoadStdMap(pOverride as %Integer=1,pFilter as %String="",pTargetClass as %String="") as %Status
{
	#dim %request as %CSP.Request
	#dim %response as %CSP.Response
	#dim tJSON as %DynamicObject
	#dim tSC as %Status=$$$OK
	
	quit:(pClass="")
	set %response.ContentType=%request.ContentType
    set tJSON = {}.%FromJSON(%request.Content)
    if tJSON.%Size()'=0
    {
    	set tSC = ##class(OPNLib.Serialize.Util).ImportMapsFromJSON(tJSON,pOverride,pFilter)
    }
    
    quit tSC
}

ClassMethod LoadStdMapToOther(pTargetClass as %Integer=1,pOverride as %Integer=1,pFilter as %String="") as %Status
{
	#dim %request as %CSP.Request
	#dim %response as %CSP.Response
	#dim tJSON as %DynamicObject
	#dim tSC as %Status=$$$OK
	
	quit:(pClass="")
	set %response.ContentType=%request.ContentType
    set tJSON = {}.%FromJSON(%request.Content)
    if tJSON.%Size()'=0
    {
    	set tSC = ##class(OPNLib.Serialize.Util).ImportMapsFromJSON(tJSON,pOverride,pFilter,pTargetClass)
    }
    
    quit tSC
}

/// Assumes default serialization method to JSON as establish by <class>OPNLib.Serialize.Adaptor</class>
/// It'll receive the id: <var>pId</var> of class: <var>pClase</var> as parameters. 
/// <var>pDrillDownLevel</var> will indicate the level of drill down through the chain references (-1 by default, to follow the chain reference as indicated in the MAP defined
/// <var>pMAP</var>, if null, the export will be done according to the default mapping for the class especified. Otherwise, follow the MAP here indicated.
ClassMethod GetJSON(pClass as %String,pId as %Integer,pDrillDownLevel as %Integer=-1,pMAP as %String="") as %Status
{

    set %response.ContentType = "application/json"

	set tObjRef = $classmethod(pClass,"%OpenId",pId)
	
	if $IsObject(tObjRef)&&(##class(%Dictionary.CompiledClass).%OpenId(pClass).Super["OPNLib.Serialize.Adaptor")
	{
		set tObj = tObjRef.Export(,,,,pDrillDownLevel,pMAP)
		write tObj.%ToJSON()
	}
	else 
	{
		write {"status":"0 - Object doesn't exist or class doesn't inherits from OPNLib.Serialize.Adaptor"}.%ToJSON()
	}
	quit $$$OK
}

/// Load an object that comes in JSON format. It'll be a new object, even if it comes with ID info
/// If pClass is null, it'll get the info in property _classname of json object. Otherwise pClass is used for the new object to create
/// It returns a JSON object with info about new ID and status code
ClassMethod IngestJSON(pClass as %String="",pDrillDownLevel as %Integer=-1,pMAP as %String="") as %Status
{
	#dim %request as %CSP.Request
	#dim %response as %CSP.Response
	#dim tNewID as %String=""
	#dim tJSON as %DynamicObject
	#dim tSC as %Status=$$$OK
	
    set %response.ContentType = "application/json"
    set tJSON = {}.%FromJSON(%request.Content)
   	if pClass="" set pClass = tJSON."_classname"
    if (pClass'="")&&(tJSON.%Size()'=0)&&(##class(%Dictionary.CompiledClass).%OpenId(pClass).Super["OPNLib.Serialize.Adaptor")
    {
    	set tObjRef = $classmethod(pClass,"%New")
    	set:$IsObject(tObjRef) tSC = tObjRef.Import(tJSON,pDrillDownLevel,,,pMAP)
    	set tSC = tObjRef.%Save()
    	set tNewID = tObjRef.%Id()
    	write "{""newID"":"_tNewID_",""status"":"""_tSC_"""}"
    }
    else
    {
    	write "{""newID"":,""status"":""0: Target class missing or no input data or class doesn't inherits from OPNLib.Serialize.Adaptor""}"
    }
    
    quit tSC
}

ClassMethod UpdateJSON(pClass as %String="", pId as %String="") as %Status
{
	#dim %request as %CSP.Request
	#dim %response as %CSP.Response
	#dim tJSON as %DynamicObject
	#dim tSC as %Status=0
	
    set %response.ContentType = "application/json"
    set tJSON = {}.%FromJSON(%request.Content)
   	if pClass="" set pClass = tJSON."_classname"  //For JSON approach we assume that classname could come in _classname property in JSON object
   	if pId="" set pId = tJSON."_id" //For JSON approach we assume that classname could come in _classname property in JSON object
    if (pClass'="")&&(pId'="")&&(tJSON.%Size()'=0)&&(##class(%Dictionary.CompiledClass).%OpenId(pClass).Super["OPNLib.Serialize.Adaptor")
    {
    	set tObjRef = $classmethod(pClass,"%OpenId",pId)
    	set:$IsObject(tObjRef) tSC = tObjRef.Import(tJSON,0)
    	set tSC = tObjRef.%Save()
    	write "{""ID"":"_pId_",""status"":"""_tSC_"""}"
    }
    else
    {
    	write "{""ID"":,""status"":""0: Possible causes: Target class or object ID missing - No input data - Class doesn't inherits from OPNLib.Serialize.Adaptor""}"
    }
    
    quit tSC
}

/// Load an object that comes in a serialized format (it assumes that the info comes in a Stream).
/// It'll be a new object, even if it comes with ID info
/// If pClass is null, it'll get the info from the serialized data. Otherwise pClass is used for the new object to create
/// It returns a JSON object with info about new ID and status code
ClassMethod IngestSerialization(pTemplateClass as %String="",pImportMethod as %String="",pClass as %String="",pDrillDownLevel as %Integer=-1,pMAP as %String="") as %Status
{
	#dim %request as %CSP.Request
	#dim %response as %CSP.Response
	#dim tNewID as %String=""
	#dim tJSON as %DynamicObject
	#dim tSC as %Status=0
	
	set %response.ContentType=%request.ContentType
    if (pClass'="") && $IsObject(%request.Content) 
        && (%request.Content.Size'=0) 
        && (##class(%Dictionary.CompiledClass).%OpenId(pClass).Super["OPNLib.Serialize.Adaptor") 
        && (##class(%Dictionary.CompiledMethod).%ExistsId(pTemplateClass_"||"_pImportMethod))
    {
    	set tObjRef = $classmethod(pClass,"%New")
    	if $IsObject(tObjRef)
    	{
    		set tSC = tObjRef.Import(%request.Content,pDrillDownLevel,pTemplateClass,pImportMethod)
    		set:(tSC=1) tSC = tObjRef.%Save()
    		set tNewID = tObjRef.%Id()
    		write "{""newID"":"_tNewID_",""status"":"""_tSC_"""}"
    	}
    }
    else 
    {
    	write "{""newID"":"_tNewID_",""status"":""0 - Target class missing or no input data or class doesn't inherits from OPNLib.Serialize.Adaptor""}"
    }
    
    quit tSC
}


/// Same than GetJSON, but using <var>pExportMethod</var> implemented in <var>pTemplateClass</var> to serialize the object
ClassMethod GetSerialization(pTemplateClass as %String="",pExportMethod as %String="",pClass as %String="",pId as %Integer,pDrillDownLevel as %Integer=-1) as %Status
{
	if (pTemplateClass="")&&(pExportMethod="") 
	{
		do ..GetJSON(pClass,pId,pDrillDownLevel)
	}
	elseif (##class(%Dictionary.CompiledMethod).%ExistsId(pTemplateClass_"||"_pExportMethod))
	        && (##class(%Dictionary.CompiledClass).%OpenId(pClass).Super["OPNLib.Serialize.Adaptor")
	{
		set tObjRef = $classmethod(pClass,"%OpenId",pId)
		set tObj = tObjRef.Export(pTemplateClass,pExportMethod,,,pDrillDownLevel)
		
		if (tObj.%ClassName(1)="%Library.DynamicObject")
		{
			set %response.ContentType = "application/json"
			set %response.CharSet="utf-8"
			
			write tObj.%ToJSON()
		}
		else //If no %DynamicObject we assume the serialization method delivers a Stream
		{
			do tObj.OutputToDevice()
		}
	}
    else 
    {
    	write "{""status"":""0 - Target class missing or no input data or class doesn't inherits from OPNLib.Serialize.Adaptor""}"
    }
	
	quit $$$OK
}

/// Return a dump of the request object
ClassMethod Request() As %Status
{
	Set %response.ContentType="text/plain"
	Do $System.OBJ.Dump(%request)
    Quit $$$OK
}

/// Return the posted data
ClassMethod Echo(txt as %String="") As %Status
{
    Set %response.ContentType=%request.ContentType
	write %request.Content.%ClassName(1)
    write txt
       Quit %request.Content.OutputToDevice()
}
}