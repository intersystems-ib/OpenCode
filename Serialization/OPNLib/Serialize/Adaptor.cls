IncludeGenerator OPNLib.Serialize.constants
Include OPNLib.Serialize.constants
Class OPNLib.Serialize.Adaptor Extends %RegisteredObject [Abstract ]
{
Parameter EXPTTEMPLATECLASS;
Parameter EXPTDRILLDOWN=1;
Parameter EXPTEXCLUDEPROP;
Parameter EXPTDEFAULTMAP="MAP0";
Parameter EXPTINCLUDEOREFS=1; //For referenced objects when we don't want to drill down, we could decide if including OREF or not in exported data

/// It generates an object (JSON, XML,...) based on <var>pMapTemplatesClass</var> and <var>pMethodMap</var>. 
/// <var>pInObject</var> will receive whatever additional object instance that the particular export method could need (it's not used for default JSON export)
/// <var>pOutputObject</var> will keep a reference to the object generated. The same reference will be also returned by the method
/// If no MapTemplatesClass/MethodMap is specified, it'll generate a JSON object defined by the default MAP
Method Export(pMapTemplatesClass As %String = "", pMethodMap As %String = "", pInObject As %RegisteredObject = "", Output pOutputObject As %RegisteredObject, pDrillDown as %Integer=-1, pArgs...) As %RegisteredObject
{
	if pMapTemplatesClass=""
	{
		//This sets the signature that must have all methods to export defined in Template classes
		set tOutput = ..exportStd($this,pInObject,.pOutputObject,pDrillDown,pArgs...)
	}
	elseif (pMethodMap'="")
	{
		//This sets the signature that must have all method to import in Template classes
		set tOutput = $classmethod(pMapTemplatesClass,pMethodMap,$this,pInObject,.pOutputObject,pDrillDown,pArgs...)
	}

	if $IsObject(pOutputObject) return pOutputObject

	return $$$NULLOREF
}
/// It imports the data from pInObject to the instance that is calling the method
/// pInObject will be an object (%DynamicObject, %XML,...) with data to load to current object through the mechanism established by pMethodMap implemented in pMapTemplatesClass
/// pMethodMap - Method chosen to import data. That method implements the logic to import data in this type of objects. Depending on the logic that data could come in different formats. 
///              By default, if no pMethodMap is indicated, it will use <b>importStd</b> that expects the import data in JSON format
/// pMapTemplatesClass - Class in which it is the pMethodMap. 
///						 This class could contain other methods to import/export data from this type of objects using different mechanisms and/or formats.
///						 By default, if no pMapTemplatesClass is indicated, and no pMethodMap, it'll be used <b>importStd</b>
/// pDrillDown - Indicates the levels to follow the chain of references if the object include references to other objects, arrays/list of objects or relationships. 
///				 -1 (default): Apply DrillDown defined in the MAP for each property
///				  0 : No drill down (but include OREF if EXPTINCLUDEORED=1 in the object class definition)
/// pArgs       - Included for flexibility.  
///				- pArg(1) : <MAP to use> Used for export/import default mechanism. Includes the MAP name to use to export/import. 
///				            If pArg(1) is null, it'll be used the default MAP (as defined in EXPTDEFAULTMAP parameter of object class definition)
Method Import(pMapTemplatesClass As %String = "", pMethodMap As %String = "", pInObject As %RegisteredObject = "",pDrillDown as %Integer=-1,ByRef pArgs...) As %Status
{
	#dim tSC as %Status=0
	#dim e as %Exception.General
	
	try 
	{
		set tObj = $this
		if pMapTemplatesClass=""
		{
			set tSC = ..importStd(.tObj,pInObject,pDrillDown,pArgs...)
		}
		elseif (pMethodMap'="")
		{
			set tSC = $classmethod(pMapTemplatesClass,pMethodMap,.tObj,pInObject,pDrillDown,pArgs...)
		}
		else {
			set tSC = $$$ERROR(5001,"Missing name of method to import data")
		}
	}
	catch e
	{
		set tSC = e.AsStatus()
	}
	quit tSC
}

///It generates the MAP by default with the following estructure:
///^MAPS and ^MAPSREV
///		Subscript 1:
///			1 --> Basic type
///			2 --> List collection
///			3 --> Array collection
///			4 --> Reference to other object
///			5 --> Array of Objects or Relationship many/children
///			6 --> List of Objects
///			7 --> Stream
///		Subscript 2:
///			Source Property name:
///				^MAPS --> property name in IRIS object
///				^MAPSREV --> property name in JSON object (pInObject)
///			Data (listbuild):
///				Pos 1: Target Property namefield name in target format:
///				 	^MAPS --> property of JSON object being generated
///				 	^MAPSREV --> property in IRIS object being generated 
///				Pos 2: (convert method) -> just one argument, data input, that will result in data converted
///				Pos 3: Drill down levels (n  -> Drill down n levels through this reference
///                                       0  -> (default) do not start to drill down this reference, but include object OREF 
///                                       -1 -> neither drill down nor include OREF)
///				Pos 4: Classname of referenced objects in lists/arrays/relationships
///				Pos 5: TemplatesClass  --> for referenced objects/relationship objects optionally indicate the class that contains export method MAPs to use
///				Pos 6: MethodMap --> Method that it triggers the export/import in TemplatesClass
ClassMethod generateDefaultMAP() as %Status [ CodeMode = objectgenerator, ForceGenerate ]
{
	#dim tSC as %Status=$$$OK
	#dim e as %Exception.General
	#dim %compiledclass as %Dictionary.CompiledClass
	
	quit:(%compiledclass.Name="OPNLib.Serialize.Adaptor") $$$OK  //Doesn't generate map for Adaptor itself
		
	try
	{
		set dMAP=$case(%parameter("EXPTDEFAULTMAP"),"":"MAP0",:%parameter("EXPTDEFAULTMAP"))
		
		//Deletes whatever previously generated default MAP
		kill ^MAPS(%compiledclass.Name,dMAP),^MAPSREV(%compiledclass.Name,dMAP)
		
		if (%parameter("EXPTEXCLUDEPROP")'="")
		{
			set tExcludeProp = $ListFromString(%parameter("EXPTEXCLUDEPROP"))
		}
		else 
		{
			set tExcludeProp=$ListBuild()
		}
		
		//Caché types that easily translates a supported basic datatypes in JSON
		set tSupportedBasicDataTypes = "%Library.CacheString|%Library.String|%Library.Char|%Library.Text|%Library.CacheLiteral|%Library.GUID"
						_"|Library.Date|%Library.DateTime|%Library.TimeStamp|%Library.Time|%Library.UTC|%Library.StringTimeStamp"
						_"|%Library.Integer|%Library.SmallInt|%Library.TinyInt|%Library.BigInt|%Library.Double|%Library.Float|%Library.Numeric|%Library.Decimal"
						_"|%Library.Boolean"
		
		set tProperties = %compiledclass.Properties
		set key=""
		set tProp = tProperties.GetNext(.key)	
		while key'="" 
		{							
			if '((tProp.Name["%")||$ListFind(tExcludeProp,tProp.Name))   //It skips system or explicitly excluded properties 
			{
				set tName = tProp.Name
				set tRTType = tProp.RuntimeType
				set tType = tProp.Type
				
				set tGroup = $$$tpUKN //Uncovered datatype
				
				if tSupportedBasicDataTypes[tRTType set tGroup = $$$tpBSC  //Basic Datatype
				
				if tProp.Collection="" 
				{ 
					if '(tProp.Type["%Library") set tGroup = $$$tpOREF  //Simple Object Reference
					if (tProp.Type["%Stream") set tGroup = $$$tpSTREAM  //Stream
				}
				elseif tProp.Collection = "array"   //We're not covering yet other types of collection (%Library.ArrayOfObjects, ArrayOfDataTypes..)
				{
					set tGroup = $$$tpARR //Array collection
					if ("%Collection.ArrayOfObj|%Collection.ArrayOfObjCN|%Collection.ArrayOfStream|%Library.RelationshipObject"[tProp.RuntimeType) set tGroup = $$$tpARROBJ //Array of Objects - Relationship Objects
				}
				elseif tProp.Collection = "list"  //We're not covering yet other types of collection (%Library.ListOfObjects, ListOfDataTypes,..)
				{
					set tGroup = $$$tpLST //List collection
					if ("%Collection.ListOfObj|%Collection.ListOfObjCN|%Collection.ListOfStream"[tProp.RuntimeType) set tGroup = $$$tpLSTOBJ  //List of Objects
				}
				
				set tConvert = $case(tType,
									"%Library.Date":"exportDate|importDate","%Library.Time":"exportTime|importTime",
									"%Library.TimeStamp":"exportTimeStamp|importTimeStamp",
									"%Stream.GlobalBinary":"exportBase64Stream|importBase64Stream","%Stream.FileBinary":"exportBase64Stream|importBase64Stream",
									"%Stream.GlobalCharacterBinary":"exportBase64Stream|importBase64Stream","%Stream.FileCharacter":"exportBase64Stream|importBase64Stream",
									:"")
				
				// Drilldown - make decision based on type and inheritance - By default establishes no drilldown
				// TypeGroup - validate/change tGroup if required
				set tDrillDown = 0
				if %parameter("EXPTINCLUDEOREFS")=0 set tDrillDown = -1
				
				set tClassRefName = "" 
				if (tGroup=$$$tpOREF)||(tGroup=$$$tpARROBJ)||(tGroup=$$$tpLSTOBJ) 
				{
					set tClassRef = ##class(%Dictionary.CompiledClass).%OpenId(tType)
					set tClassRefName = tClassRef.Name
					if (tClassRef.Super["OPNLib.Serialize.Adaptor")  //We'll set by-default Drilldown just if class referenced inherits our export mechanism
					{
						if %parameter("EXPTDRILLDOWN")>0 set tDrillDown = %parameter("EXPTDRILLDOWN")
					}
					if (tGroup=$$$tpOREF)&&(tClassRef.ClassType="datatype")
					{
						set tGroup=$$$tpBSC //It's a custom basic datatype
					}
				}
				
				set ^MAPS(%compiledclass.Name,dMAP,tGroup,tName)=$Listbuild(tName,$piece(tConvert,"|",1),tDrillDown,tClassRefName,"","")
				set ^MAPSREV(%compiledclass.Name,dMAP,tGroup,tName)=$Listbuild(tName,$piece(tConvert,"|",2),tDrillDown,tClassRefName,"","")
			}
			
			set tProp = tProperties.GetNext(.key)
		}		
	}
	catch e
	{
		set tSC = e.AsStatus()
	}
	quit tSC
}

///Export object data iterating through default MAPping global. It doesn't export data from properties not explicitly included in the MAP
///<var>pObject</var> will keep a reference to the current object that is making the call
///<var>pInObject</var> Reserved for future use. It'll be used in case we need to include any additional object
///<var>pOubputObject</var> will keep a reference to a %DynamicObject with all the exported data
///<var>pDrillDown</var> By default (-1) the export mechanism will drill down the object references as indicated in the MAPping global for each property. 
///       Through this parameter we can explicitly indicate the levels to drill down for each object chain (it will have no effect if drill down is forbidden 
///       for a particular property in the MAPping global (Drilldown setting <= 0) 
///<var>pArgs</var> pArgs(1): It'll contain the MAPname to use. Otherwise it'll use the default MAP name as defined in EXPTDEFAULTMAP parameter defined in the object class
Method exportStd(pObject as %RegisteredObject,pInObject as %RegisteredObject,Output pOutputObject as %RegisteredObject, pDrillDown as %Integer=-1,ByRef pArgs...) As %RegisteredObject [ CodeMode = objectgenerator, ForceGenerate, GenerateAfter = (generateDefaultMAP) ]
{
	#dim %compiledclass as %Dictionary.CompiledClass
	#dim tProp as %Dictionary.CompiledProperty
	
	quit:(%compiledclass.Name="OPNLib.Serialize.Adaptor") $$$OK  //Doesn't generate map for Adaptor itself
	
	set dMAP=$case(%parameter("EXPTDEFAULTMAP"),"":"MAP0",:%parameter("EXPTDEFAULTMAP"))
	
	do %code.WriteLine(" #dim tSC as %Status=$$$OK")
	do %code.WriteLine(" try")
	do %code.WriteLine(" {")
	do %code.WriteLine("   set tDrillDown = pDrillDown")
	do %code.WriteLine("   set tMapName = $case($get(pArgs(1)),"""":"""_dMAP_""",:$get(pArgs(1)))")
	do %code.WriteLine("   ")
	do %code.WriteLine("   set tObj = {}")
	do %code.WriteLine("   ") 
	do %code.WriteLine("   //Basic system types")
	set tGroup = $$$tpBSC
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {")
	do %code.WriteLine("     set tConvert=$List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),2)")
	do %code.WriteLine("     set tValue = $case(tConvert,"""":$property(pObject,tIdx),:$method(pObject,tConvert,$property(pObject,tIdx)))")
	do %code.WriteLine("     do tObj.%Set($List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1),tValue)")	
	do %code.WriteLine("     set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")	
	do %code.WriteLine("   ")
	do %code.WriteLine("   //Lists")
	set tGroup = $$$tpLST
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {")
	do %code.WriteLine("     //ROOM to improve: apply conversion to elements in list")
	do %code.WriteLine("     do tObj.%Set($List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1),$ListToString($property(pObject,tIdx).Serialize(),$c(9)))")	
	do %code.WriteLine("     set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")	
	do %code.WriteLine("   ")
	do %code.WriteLine("   //Arrays")
	set tGroup = $$$tpARR
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {")	
	do %code.WriteLine("     set tArr = []")
	do %code.WriteLine("     set tKey = """"")
	do %code.WriteLine("     set tConvert=$List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),2)")
	do %code.WriteLine("     //ROOM to improve (This forces execute a $case for each key...)") 
	do %code.WriteLine("     set tValue = $case(tConvert,"""":$property(pObject,tIdx).GetNext(.tKey),:$method(pObject,tConvert,$property(pObject,tIdx).GetNext(.tKey)))")
	do %code.WriteLine("     while (tKey'="""")")
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tKeyValue = {}.%Set(""key"",tKey)")
	do %code.WriteLine("       do tKeyValue.%Set(""value"",tValue)")	
	do %code.WriteLine("       do tArr.%Push(tKeyValue)")	
	do %code.WriteLine("       set tValue = $case(tConvert,"""":$property(pObject,tIdx).GetNext(.tKey),:$method(pObject,tConvert,$property(pObject,tIdx).GetNext(.tKey)))")
	do %code.WriteLine("     }")
	do %code.WriteLine("     do tObj.%Set($List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1),tArr)")
	do %code.WriteLine("     set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")	
	do %code.WriteLine("   ")
	do %code.WriteLine("   //Simple Object Reference")
	set tGroup = $$$tpOREF
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {")	
	do %code.WriteLine("     if $IsObject($property(pObject,tIdx))") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       //If drilldown of this property it's not prohibited by MAP (<=0), then we'll apply")
	do %code.WriteLine("       //the level by default or the level of deep requested in the method call")
	do %code.WriteLine("       set tPropMAPDrillDown = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),3)")
	do %code.WriteLine("       set tDrillDown = pDrillDown")
	do %code.WriteLine("       if (pDrillDown < 0)||(tPropMAPDrillDown'>0)") 
	do %code.WriteLine("       {")
	do %code.WriteLine("         set tDrillDown = tPropMAPDrillDown")
	do %code.WriteLine("       }")
	do %code.WriteLine("       set tMAPClass = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),5)")
	do %code.WriteLine("       set tMAP = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),6)")	
	do %code.WriteLine("       set tJSONRef="""" ")
	do %code.WriteLine("       if (tDrillDown > 0) ")
	do %code.WriteLine("       {")
	do %code.WriteLine("         set tJSONRef = $property(pObject,tIdx).Export(tMAPClass,tMAP,,,(tDrillDown-1))")
	do %code.WriteLine("       }")
	do %code.WriteLine("       elseif (tDrillDown = 0)&&("_%parameter("EXPTINCLUDEOREFS")_")") 
	do %code.WriteLine("       {")
	do %code.WriteLine("         set tJSONRef={""objref"":("" ""_$property(pObject,tIdx))}")
	do %code.WriteLine("       }")
	do %code.WriteLine("       do tObj.%Set($ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1),tJSONRef)")
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")
	do %code.WriteLine("   ")
	set tGroup = $$$tpARROBJ
	do %code.WriteLine("   //Arrays or Relationship Objects")
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {	")
	do %code.WriteLine("     if $IsObject($property(pObject,tIdx))") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       //If drilldown of this property it's not prohibited by MAP (<=0), then we'll apply")
	do %code.WriteLine("       //the level by default or the level of deep requested in the method call")
	do %code.WriteLine("       set tPropMAPDrillDown = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),3)")
	do %code.WriteLine("       set tDrillDown = pDrillDown")
	do %code.WriteLine("       if (pDrillDown < 0)||(tPropMAPDrillDown'>0)") 
	do %code.WriteLine("       {")
	do %code.WriteLine("         set tDrillDown = tPropMAPDrillDown")
	do %code.WriteLine("       }")
	do %code.WriteLine("       set tMAPClass = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),5)")
	do %code.WriteLine("       set tMAP = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),6)")				
	do %code.WriteLine("       set tArr = []")
	do %code.WriteLine("       set tKey = """"")
	do %code.WriteLine("       set tObjChildMany = $property(pObject,tIdx).GetNext(.tKey)")
	do %code.WriteLine("       while ((tKey'="""") && $IsObject(tObjChildMany))")
	do %code.WriteLine("       {   ")
	do %code.WriteLine("         set tJSONRef = """" ")
	do %code.WriteLine("         if (tDrillDown > 0)")
	do %code.WriteLine("         {")
	do %code.WriteLine("           set tJSONRef = tObjChildMany.Export(tMAPClass,tMAP,,,(tDrillDown-1))")
	do %code.WriteLine("         }")
	do %code.WriteLine("         elseif (tDrillDown = 0)&&("_%parameter("EXPTINCLUDEOREFS")_")")
	do %code.WriteLine("         {")
	do %code.WriteLine("           set tJSONRef={""objref"":("" ""_tObjChildMany)}")							
	do %code.WriteLine("         }")
	do %code.WriteLine("         set tArrElem = {""key"":(tKey),""value"":(tJSONRef)}")
	do %code.WriteLine("         do tArr.%Push(tArrElem)")	
	do %code.WriteLine("         set tObjChildMany = $property(pObject,tIdx).GetNext(.tKey)")
	do %code.WriteLine("       }")
	do %code.WriteLine("       do tObj.%Set($List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1),tArr)")							
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")
	do %code.WriteLine(" ")
	set tGroup = $$$tpLSTOBJ  
	do %code.WriteLine("   //Lists of Objects")
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {	")
	do %code.WriteLine("     if $IsObject($property(pObject,tIdx))") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       //If drilldown of this property it's not prohibited by MAP (<=0), then we'll apply")
	do %code.WriteLine("       //the level by default or the level of deep requested in the method call")
	do %code.WriteLine("       set tPropMAPDrillDown = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),3)")
	do %code.WriteLine("       set tDrillDown = pDrillDown")
	do %code.WriteLine("       if (pDrillDown < 0)||(tPropMAPDrillDown'>0)") 
	do %code.WriteLine("       {")
	do %code.WriteLine("         set tDrillDown = tPropMAPDrillDown")
	do %code.WriteLine("       }")
	do %code.WriteLine("       set tMAPClass = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),5)")
	do %code.WriteLine("       set tMAP = $ListGet(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),6)")				
	do %code.WriteLine("       set tArr = []")
	do %code.WriteLine("       set tKey = """"")
	do %code.WriteLine("       set tObjChildMany = $property(pObject,tIdx).GetNext(.tKey)")
	do %code.WriteLine("       while ((tKey'="""") && $IsObject(tObjChildMany))")
	do %code.WriteLine("       {   ")
	do %code.WriteLine("         set tJSONRef = """" ")
	do %code.WriteLine("         if tDrillDown > 0")
	do %code.WriteLine("         {")
	do %code.WriteLine("           set tJSONRef = tObjChildMany.Export(tMAPClass,tMAP,,,(tDrillDown-1))")
	do %code.WriteLine("         }")
	do %code.WriteLine("         elseif (tDrillDown = 0)&&("_%parameter("EXPTINCLUDEOREFS")_")")
	do %code.WriteLine("         {")
	do %code.WriteLine("           set tJSONRef={""objref"":("" ""_tObjChildMany)}")							
	do %code.WriteLine("         }")
	do %code.WriteLine("         do tArr.%Push(tJSONRef)")	
	do %code.WriteLine("         set tObjChildMany = $property(pObject,tIdx).GetNext(.tKey)")
	do %code.WriteLine("       }")
	do %code.WriteLine("       do tObj.%Set($List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1),tArr)")							
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")	
	do %code.WriteLine("   ")
	set tGroup = $$$tpSTREAM  
	do %code.WriteLine("   //Streams")
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {")
	do %code.WriteLine("     set tConvert=$List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),2)")
	do %code.WriteLine("     set:tConvert="""" tConvert=""exportBase64Stream""  //By default streams will be exported as base64 strings")
	do %code.WriteLine("   	 if $IsObject($property(pObject,tIdx))")
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tStream = $property(pObject,tIdx)")
	do %code.WriteLine("       set tContent = $method(pObject,tConvert,tStream)")
	do %code.WriteLine("       do tObj.%Set($List(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1),tContent)")
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPS("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")
	do %code.WriteLine(" ")
	do %code.WriteLine("   set pOutputObject = tObj")
	do %code.WriteLine("   return tObj")
	do %code.WriteLine(" }")
	do %code.WriteLine(" catch e")
	do %code.WriteLine(" {")
	do %code.WriteLine("   set tSC = e.AsStatus()")
	do %code.WriteLine("   set pOutputObject = {""Status"":(tSC)}")
	do %code.WriteLine(" }")
	do %code.WriteLine(" quit pOutputObject")
	
	quit $$$OK
}
/// Imports data coming in <var>pInObject</var>, as %DynamicObject, in the instance of the caller object (<var>pObject</var>)
Method importStd(ByRef pObject as %RegisteredObject,pInObject as %RegisteredObject,pDrillDown as %Integer=-1,ByRef pArgs...) As %Status [ CodeMode = objectgenerator, ForceGenerate, GenerateAfter = (generateDefaultMAP) ]
{
	#dim %compiledclass as %Dictionary.CompiledClass
	#dim tProp as %Dictionary.CompiledProperty
	
	quit:(%compiledclass.Name="OPNLib.Serialize.Adaptor") $$$OK  //Doesn't generate map for Adaptor itself
	
	set dMAP=$case(%parameter("EXPTDEFAULTMAP"),"":"MAP0",:%parameter("EXPTDEFAULTMAP"))

	do %code.WriteLine(" #dim tSC as %Status=$$$OK")
	do %code.WriteLine(" try")
	do %code.WriteLine(" {")
	do %code.WriteLine("   set tDrillDown = pDrillDown")
	do %code.WriteLine("   set tMapName = $case($get(pArgs(1)),"""":"""_dMAP_""",:$get(pArgs(1)))")
	do %code.WriteLine("   ")
	do %code.WriteLine("   s tObj = {}")
	do %code.WriteLine("   ") 
	set tGroup = $$$tpBSC
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")")
	do %code.WriteLine("   {")
	do %code.WriteLine("     set tConvert=$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),2) ")
	do %code.WriteLine("     set tValue = $case(tConvert,"""":pInObject.%Get(tIdx),:$method(pObject,tConvert,pInObject.%Get(tIdx)))")
	do %code.WriteLine("     set $property(pObject,$ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1))=tValue")	
	do %code.WriteLine("     set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")	
	do %code.WriteLine("   ")
	do %code.WriteLine(" //Lists")
	set tGroup = $$$tpLST
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")") 
	do %code.WriteLine("   {")
	do %code.WriteLine("     set tValue = $ListFromString(pInObject.%Get(tIdx),$c(9))")
	do %code.WriteLine("     set tSC = $property(pObject,$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1)).InsertList(tValue)")
	do %code.WriteLine("     set tIdx=$order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")
	do %code.WriteLine(" //Arrays")
	set tGroup = $$$tpARR
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")") 
	do %code.WriteLine("   {")
	do %code.WriteLine("     set tConvert=$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),2)")
	do %code.WriteLine("     if pInObject.%GetTypeOf(tIdx) = ""array""") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tIterator = pInObject.%Get(tIdx).%GetIterator()")
	do %code.WriteLine("       while tIterator.%GetNext(.tElement,.tKeyValue)")
	do %code.WriteLine("       {")
	do %code.WriteLine("         set tKey = tKeyValue.key")
	do %code.WriteLine("         set tValue = $case(tConvert,"""":tKeyValue.value,:$method(pObject,tConvert,tKeyValue.value))")
	do %code.WriteLine("         set tSC = $property(pObject,$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1)).SetAt(tValue,tKey)")
	do %code.WriteLine("       }")
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")
	do %code.WriteLine(" ")
	do %code.WriteLine(" //Referenced Objects")
	set tGroup = $$$tpOREF
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")") 
	do %code.WriteLine("   {")
	do %code.WriteLine("     //Classname of referenced object")	
	do %code.WriteLine("     set tClassRef = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),4)")	
	do %code.WriteLine("     //If drilldown of this property it's not prohibited by MAP (=0), then we'll apply")
	do %code.WriteLine("     //the level by default or the level of deep requested in the method call")
	do %code.WriteLine("     set tPropMAPDrillDown = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),3)")
	do %code.WriteLine("     set tDrillDown = pDrillDown")
	do %code.WriteLine("     if (pDrillDown < 0)||(tPropMAPDrillDown'>0)") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tDrillDown = tPropMAPDrillDown")
	do %code.WriteLine("     }")

	do %code.WriteLine("     //Only if there is a json object we'll try to import")
	do %code.WriteLine("     //By default we'll assume that referenced object it'll be a new one. ")
	do %code.WriteLine("     //This could be improved to allow import references to existing objects")
	do %code.WriteLine("     if (tDrillDown > 0)&&(pInObject.%GetTypeOf(tIdx) = ""object"")") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tMAPClass = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),5)")
	do %code.WriteLine("       set tMAP = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),6)")	
	do %code.WriteLine("       set tRefObj = $classmethod(tClassRef,""%New"")")
	do %code.WriteLine("       do tRefObj.Import(tMAPClass,tMAP,pInObject.%Get(tIdx),(tDrillDown-1))")
	do %code.WriteLine("       set $property(pObject,$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1)) = tRefObj")
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")
	do %code.WriteLine(" ")
	do %code.WriteLine(" //Arrays of objects & Relationships")
	set tGroup = $$$tpARROBJ
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")") 
	do %code.WriteLine("   {")
	do %code.WriteLine("     //Classname of inner objects")	
	do %code.WriteLine("     set tClassRef = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),4)")	
	do %code.WriteLine(" ")
	do %code.WriteLine("     //If drilldown of this property it's not prohibited by MAP (=0), then we'll apply")
	do %code.WriteLine("     //the level by default or the level of deep requested in the method call")
	do %code.WriteLine("     set tPropMAPDrillDown = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),3)")
	do %code.WriteLine("     set tDrillDown = pDrillDown")
	do %code.WriteLine("     if (pDrillDown < 0)||(tPropMAPDrillDown'>0)") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tDrillDown = tPropMAPDrillDown")
	do %code.WriteLine("     }")
	do %code.WriteLine("     //Only if there is a json object we'll try to import")
	do %code.WriteLine("     //By default we'll assume that referenced object it'll be a new one. ")
	do %code.WriteLine("     //ROOM to improve - This perhaps could be improved to allow import references to existing objects")
	do %code.WriteLine("     if (tClassRef'="""")&&(tDrillDown > 0)&&(pInObject.%GetTypeOf(tIdx) = ""array"")") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tMAPClass = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),5)")
	do %code.WriteLine("       set tMAP = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),6)")
	do %code.WriteLine("       set tIterator = pInObject.%Get(tIdx).%GetIterator()")
	do %code.WriteLine("       while tIterator.%GetNext(.tKey,.tValue)")
	do %code.WriteLine("       {")
	do %code.WriteLine("         //Each array element will be of type {""key"":<key>,""value"":<JSON object>")	
	do %code.WriteLine("         set tElemObj = $classmethod(tClassRef,""%New"")")
	do %code.WriteLine("         do tElemObj.Import(tMAPClass,tMAP,tValue.value,(tDrillDown-1))")
	do %code.WriteLine("         if $IsObject(tElemObj)")
	do %code.WriteLine("         {")
	do %code.WriteLine("           set tSC = $property(pObject,$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1)).SetAt(tElemObj,tValue.key)")
	do %code.WriteLine("         }")
	do %code.WriteLine("       }")
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")

	do %code.WriteLine(" ")
	do %code.WriteLine(" //List of objects")
	set tGroup = $$$tpLSTOBJ
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")") 
	do %code.WriteLine("   {")
	do %code.WriteLine("     //Classname of inner objects")	
	do %code.WriteLine("     set tClassRef = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),4)")	
	do %code.WriteLine(" ")
	do %code.WriteLine("     //If drilldown of this property it's not prohibited by MAP (=0), then we'll apply")
	do %code.WriteLine("     //the level by default or the level of deep requested in the method call")
	do %code.WriteLine("     set tPropMAPDrillDown = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),3)")
	do %code.WriteLine("     set tDrillDown = pDrillDown")
	do %code.WriteLine("     if (pDrillDown < 0)||(tPropMAPDrillDown'>0)") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tDrillDown = tPropMAPDrillDown")
	do %code.WriteLine("     }")
	do %code.WriteLine("     //Only if there is a json object we'll try to import")
	do %code.WriteLine("     //By default we'll assume that referenced object it'll be a new one. ")
	do %code.WriteLine("     //ROOM to improve - This perhaps could be improved to allow import references to existing objects")
	do %code.WriteLine("     if (tClassRef'="""")&&(tDrillDown > 0)&&(pInObject.%GetTypeOf(tIdx) = ""array"")") 
	do %code.WriteLine("     {")
	do %code.WriteLine("       set tMAPClass = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),5)")
	do %code.WriteLine("       set tMAP = $ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),6)")
	do %code.WriteLine("       set tIterator = pInObject.%Get(tIdx).%GetIterator()")
	do %code.WriteLine("       while tIterator.%GetNext(.tKey,.tValue)")
	do %code.WriteLine("       {")
	do %code.WriteLine("         //Each array element will be of type {""key"":<key>,""value"":<JSON object>")	
	do %code.WriteLine("         set tElemObj = $classmethod(tClassRef,""%New"")")
	do %code.WriteLine("         do tElemObj.Import(tMAPClass,tMAP,tValue.value,(tDrillDown-1))")
	do %code.WriteLine("         if $IsObject(tElemObj)")
	do %code.WriteLine("         {")
	do %code.WriteLine("           set tSC = $property(pObject,$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1)).Insert(tElemObj)")
	do %code.WriteLine("         }")
	do %code.WriteLine("       }")
	do %code.WriteLine("     }")
	do %code.WriteLine("     set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   }")
	do %code.WriteLine(" ")
	do %code.WriteLine(" //Streams")
	set tGroup = $$$tpSTREAM
	do %code.WriteLine("   set tIdx=""""")
	do %code.WriteLine("   set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("   while (tIdx'="""")") 
	do %code.WriteLine("   {")
	do %code.WriteLine("     set tConvert=$List(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),2)")
	do %code.WriteLine("     set:tConvert="""" tConvert=""importBase64Stream""")
	do %code.WriteLine("     set tValue = $case(tConvert,"""":pInObject.%Get(tIdx),:$method(pObject,tConvert,pInObject.%Get(tIdx)))")
	do %code.WriteLine("     set tSC = $property(pObject,$ListGet(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx),1)).CopyFrom(tValue)")	
	do %code.WriteLine("     set tIdx = $order(^MAPSREV("""_%compiledclass.Name_""",tMapName,"_tGroup_",tIdx))")
	do %code.WriteLine("    ")
	do %code.WriteLine("   }")
	do %code.WriteLine(" ")
	do %code.WriteLine(" }")
	do %code.WriteLine(" catch e")
	do %code.WriteLine(" {")
	do %code.WriteLine("   set tSC = e.AsStatus()")
	do %code.WriteLine(" }")
	do %code.WriteLine(" quit tSC")

	quit $$$OK
}

/// It reviews all the MAPS associated to the class
/// It'll verify:
///  - that the properties in ^MAPS exist and belong to the Group type that the Adaptor would assign by default
///  - that the properties in ^MAPSREV correspond with their opposite in ^MAPS
/// All the alerts will be exposed in a global passed by reference
/// <var>pMAP</var> if null (by default) will check all the MAPS. Otherwise will check a particular MAP
ClassMethod ValidateMaps(pMAP as %String="", ByRef pWarnings... as %String) as %Status
{
	//Is it worthier as a generated method in Adaptor or it could better be included in Util
	quit $$$ERROR(5001,"NOT YET IMPLEMENTED")
}

Method exportDate(pInput as %Date) as %String
{
	quit $zd(pInput,3,,,,,,,"")
	
}

Method importDate(pInput as %String) as %Date
{
	quit $zdh(pInput,3,,,,,,,0)
}

Method exportTime(pInput as %Time) as %String
{
	//Input time by default is converted to the form "hh:mm:ss" (24-hour clock).
	quit $zt(pInput,,,"")
}

Method importTime(pInput as %String) as %Time
{
	//Expected format by default hh:mm:ss (24-hour clock)
	quit $zth(pInput,,0)
}

Method exportTimeStamp(pInput as %TimeStamp="") as %String
{
	quit pInput
}

Method importTimeStamp(pInput as %String="") as %TimeStamp
{
	quit pInput
}

Method exportDateTime(pInput as %DateTime="") as %String
{
	quit $zdt(pInput,3,,,,,,,,,"")
}
Method importDateTime(pInput as %String="") as %DateTime
{
	quit $zdth(pInput,3,,,,,,,,0)
}
Method exportBase64Stream(pInput as %Stream.TmpCharacter) as %String
{
	if $IsObject(pInput) 
	{
		set tContent = ""
		while 'pInput.AtEnd
		{
			set tContent = tContent_pInput.Read()
		}
		
		quit $system.Encryption.Base64Encode(tContent)
	} 
	quit ""
}

Method importBase64Stream(pInput as %String) as %Stream.TmpCharacter
{
	set tContent = $system.Encryption.Base64Decode(pInput)
	set tStream = ##class(%Stream.TmpCharacter).%New()
	do tStream.Write(tContent)
	quit tStream
}

}