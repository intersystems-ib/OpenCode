Include OPNLib.Serialize.constants
Class OPNLib.Serialize.Util
{
///It initializes all default MAPS (MAP0) for all classes (pAll = 1) or a set of classes included in pClasses. Classes in pExclude list won't be initialized
ClassMethod InitializeMaps(pAll as %Boolean=0,pClasses as %List,pExclude as %List) as %Status
{
	#dim e as %Exception.General
	#dim tSC as %Status=$$$OK
	
	try
	{
		throw ##class(%Exception.General).%New("NOTIMPLEMENTED")
	}
	catch e
	{
		set tSC = e.AsStatus()
	}
	quit tSC	
}

ClassMethod ResetDefaultMAP(pClassName as %String="",pDefaultMAP as %String="",pExcludeProp as %String="",pIncludeOREFS as %Integer="",pDrillDown as %Integer="") as %Status
{
	#dim tSC as %Status=$$$OK
	#dim e as %Exception.General
	#dim %compiledclass as %Dictionary.CompiledClass
		
	try
	{
		return:(pClassName="") $$$ERROR(5001,"Classname missing")
		
		set tClassCompiled = ##class(%Dictionary.CompiledClass).%OpenId(pClassName)
		if $IsObject(tClassCompiled)
		{
			return:(tClassCompiled.Super'["OPNLib.Serialize.Adaptor") $$$ERROR(5001,"Class doesn't inherit from OPNLib.Serialize.Adaptor")
		}
		
		set:(pDefaultMAP="") pDefaultMAP = ##class("%Dictionary.CompiledParameter").%OpenId(pClassName_"||EXPTDEFAULTMAP").Default
		set:(pExcludeProp="") pExcludeProp = $classmethod("%Dictionary.CompiledParameter","%OpenId",pClassName_"||EXPTEXCLUDEPROP").Default
		set:(pIncludeOREFS="") pIncludeOREFS = $classmethod("%Dictionary.CompiledParameter","%OpenId",pClassName_"||EXPTINCLUDEOREFS").Default
		set:(pDrillDown="") pDrillDown = $classmethod("%Dictionary.CompiledParameter","%OpenId",pClassName_"||EXPTDRILLDOWN").Default
		
		//Deletes whatever previously generated default MAP
		kill ^MAPS(pClassName,pDefaultMAP),^MAPSREV(pClassName,pDefaultMAP)
		
		if (pExcludeProp'="")
		{
			set tExcludeProp = $ListFromString(pExcludeProp)
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
		
		set tProperties = tClassCompiled.Properties
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
				if pIncludeOREFS=0 set tDrillDown = -1
				
				set tClassRefName = "" 
				if (tGroup=$$$tpOREF)||(tGroup=$$$tpARROBJ)||(tGroup=$$$tpLSTOBJ) 
				{
					set tClassRef = ##class(%Dictionary.CompiledClass).%OpenId(tType)
					set tClassRefName = tClassRef.Name
					if (tClassRef.Super["OPNLib.Serialize.Adaptor")  //We'll set by-default Drilldown just if class referenced inherits our export mechanism
					{
						if pDrillDown>0 set tDrillDown = pDrillDown
					}
					if (tGroup=$$$tpOREF)&&(tClassRef.ClassType="datatype")
					{
						set tGroup=$$$tpBSC //It's a custom basic datatype
					}
				}
				
				set ^MAPS(pClassName,pDefaultMAP,tGroup,tName)=$Listbuild(tName,$piece(tConvert,"|",1),tDrillDown,tClassRefName,"","")
				set ^MAPSREV(pClassName,pDefaultMAP,tGroup,tName)=$Listbuild(tName,$piece(tConvert,"|",2),tDrillDown,tClassRefName,"","")
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

/// It generates a JSON object with options defined in MAP identifier passed by parameter
/// If no pMap is included, the JSON object will include all the MAPs defined for that class
/// JSON STRUCTURE:
///		{
///		 classname: "<nameofclass>",
///		 maps:[
///             {
///				 map:"<nameofmap>",
///              type:"export|import",
///              typeGroups:[
///							 {
///							  typeGroup:<[0|1|....]>,  //0-NotCovered 1-Basic 2-List 3-Array 4-ObjectRef 5-ArrayOfObj/RelationShips 6-ListOfObj 7-Stream
///                           groupDesc:"<group desc>",
///							  infoSettings:"<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>"  //repeated - just for info
///							  propertiesMapping: [
///												  {
///												   from:"<propNameSource>",
///												   settings:"property mapping data"
///												  },
///												  ...
///												 ]
///							 },
///							 ...
///							]
///				},
///				...
///			  ]
///		}
/// pTypeMap: "" -> All maps / "export" -> map to export data / "import" -> map to import data
ClassMethod ExportMapsToJSON(pClass as %String,pMap as %String="",pTypeMap as %String="") as %DynamicObject
{
	#dim tJSONMap as %DynamicObject
	#dim e as %Exception.General
	#dim tSC as %Status=$$$OK
	
	try
	{
		set tClass = pClass
		set tLstTypeMap = $case(pTypeMap,"":$ListBuild("export","import"),:$ListBuild(pTypeMap))
		set tMap = pMap
	
		set jsonOutput = {}
		set jsonOutput.maps = []
		
		set tPtr=0
		set tTypeMap=""
		while $ListNext(tLstTypeMap,tPtr,tTypeMap)
		{
			set tGlobal = $case(tTypeMap,"export":"^MAPS","import":"^MAPSREV")
			if tMap = "" //Export All MAPS
			{
				set tMap=$order(@tGlobal@(tClass,""))
				while tMap'=""
				{
					set jsonMAP = ..mapToJSON(tClass,tMap,tTypeMap)
					do jsonOutput.maps.%Push(jsonMAP)
					set tMap=$order(@tGlobal@(tClass,tMap))
				}
			}
			else 
			{
				set jsonMAP = ..mapToJSON(tClass,tMap,tTypeMap)
				do jsonOutput.maps.%Push(jsonMAP)				
			}
		}			

		return jsonOutput
	}
	catch e
	{
		set tSC = e.AsStatus()
		set jsonOutput = {"Status":(tSC)}
	}
	quit jsonOutput
}

ClassMethod mapToJSON(pClass as %String,pMap as %String,pType as %String) as %DynamicObject
{
	quit:(pClass="")||(pMap="")||((pType'="export")&&(pType'="import")) ""
	set tGlobal=$case(pType,"export":"^MAPS","import":"^MAPSREV")
	
	set jsonMAP={}
	set jsonMAP.map = pMap
	set jsonMAP.className = pClass
	set jsonMAP.type = pType
	
	set jsonMAP.typeGroups = []
	
	set tGrp = $order(@tGlobal@(pClass,pMap,""))
	while tGrp'=""
	{
		set typeGroup = {"typeGroup":(tGrp),"groupDesc":($case(tGrp,$$$tpBSC:"basic",$$$tpLST:"list",$$$tpARR:"array",$$$tpOREF:"object",$$$tpARROBJ:"arrOfObj-RltShip",$$$tpLSTOBJ:"lstOfObj",$$$tpSTREAM:"Stream",:"Uncovered"))}
		set typeGroup.infoSettings = "<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>"
		set typeGroup.propertiesMappings = []
		set tProp = $order(@tGlobal@(pClass,pMap,tGrp,""))
		while tProp'=""
		{
			set jsonProp = {"from":(tProp),
							"settings":($ListToString($get(@tGlobal@(pClass,pMap,tGrp,tProp))))
						   }
			//w !, "{""from"":"_tGrp_",""settings"":"_($ListToString($get(@tGlobal@(pClass,pMap,tGrp))))_"}"
			do typeGroup.propertiesMappings.%Push(jsonProp)
			set tProp = $order(@tGlobal@(pClass,pMap,tGrp,tProp))
		}
		do jsonMAP.typeGroups.%Push(typeGroup)
		set tGrp = $order(@tGlobal@(pClass,pMap,tGrp))
	}
	return jsonMAP
}

/// It loads a new MAP or MAPs as defined in a JSON object passed by parameter
/// If pFilter --> <class1,class2,...classN> If it's not null, we will load just the maps for the classes included in pFilter list (separated by comma)
/// If pTargetClass is not null, the map will be applied to pTargetClass instead of the classname included in the JSON document
///       (WARNING - if pTargetClass is not null, ALL maps will be loaded assigned to that class.
/// pOverride -> 1 (default) override the map definition if it already exists 2 -> same as 1 but preserving a copy of replaced MAP 0 -> skip the load of MAP definition if it already exists for that class
ClassMethod ImportMapsFromJSON(pJSONMap as %DynamicObject,pOverride as %Integer=1, pFilter as %String="",pTargetClass as %String="") as %Status
{
	#dim e as %Exception.General
	#dim tSC as %Status=$$$OK
		
	try
	{
		set tLstFilter = $ListFromString(pFilter)
		
		set tIterator = pJSONMap.maps.%GetIterator()
		while tIterator.%GetNext(.key,.tMap)
		{
			continue:$ListFind(tLstFilter,tMap.className)   // Skips load maps for classes in filter
			
			set tClassName = $case(pTargetClass,"":tMap.className,:pTargetClass)
			set tMapName = tMap.map
			set tGlobal = $case(tMap.type,"export":"^MAPS","import":"^MAPSREV",:"")
			set tGlobalTrash = tGlobal_"trash"
			
			if 'pOverride 
			{
				continue:$data(@tGlobal@(tClassName,tMapName))
			}
			else {
				merge:pOverride=2 @tGlobalTrash@($zdt($h,3),tClassName,tMapName) = @tGlobal@(tClassName,tMapName)
				kill @tGlobal@(tClassName,tMapName) 
			}
			
			set tIterGroup = tMap.typeGroups.%GetIterator()
			while tIterGroup.%GetNext(.keyGrp,.tGroup)
			{
				set tGrpNum = tGroup.typeGroup
				set tIterProp = tGroup.propertiesMappings.%GetIterator()
				while tIterProp.%GetNext(.keyProp,.tProp)
				{
					set tPropFrom = tProp.from
					set tSettings = $ListFromString(tProp.settings)
					set @tGlobal@(tClassName,tMapName,tGrpNum,tPropFrom)=tSettings
				}
			}
			
		}
	}
	catch e
	{
		set tSC = e.AsStatus()
	}
	quit tSC
}

/// Get the settings for the property in the specified map
/// pMap: map where the property is defined (if null, default map is chosen)
/// pExport: 1 (default) for the export map - 0 for the import map
ClassMethod GetMappedPropSettings(pProp as %String,pMap as %String,pClassName as %String, pGrpType as %Integer,pExport as %Boolean=1) as %DynamicObject
{
	#dim tSettings as %String=""

	set tGlobal = $case(pExport,0:"^MAPSREV",:"^MAPS")
	
	quit:(pClassName="")||(pProp="")||(pMap="") {"Status":("Invalid params. Please check. PropName = "_pProp_" ClassName = "_pClassName_" MAP = "_pMap)}
	
	if (pGrpType'="")&&($data(@tGlobal@(pClassName,pMap,pGrpType,pProp))) 
	{
		set tSettings = ^(pProp)
	}
	else  //we'll loop through the global
	{
		set tGrp=$order(@tGlobal@(pClassName,pMap,""))
		while tGrp'=""
		{
			set tIdx=$order(@tGlobal@(pClassName,pMap,tGrp,""))
			while tIdx'=""
			{
				if tIdx=pProp 
				{
					set tSettings = $ListToString($get(^(tIdx)))
					quit				
				}
				set tIdx=$order(@tGlobal@(pClassName,pMap,tGrp,tIdx))
			}
			quit:tSettings'=""
			set tGrp=$order(@tGlobal@(pClassName,pMap,tGrp))
		}
	}
	set tJSON = {"from":(pProp),
				 "settings":(tSettings)
				}
	return tJSON

}

/// Set the settings (specified a comma separated list) for the property in the MAP specified
/// pSettings: comma separated list ("<propNameTarget>,<methodName>,<drillDownFlag>,<classInnerObjects>,<templatesClass>,<methodClass>"
/// pMap: map in which the property has to be set (if null, default map is chosen) 
/// pExport: 1 (default) for export map - 0 for import map 
ClassMethod SetMappedPropSettings(pProp as %String,pSettings as %String="", pMap as %String,pClassName as %String, pGrpType as %Integer="",pExport as %Boolean=1) as %Status
{
	#dim e as %Exception.General
	#dim tSC as %Status = 0
	
	try {
		set tGlobal = $case(pExport,0:"^MAPSREV",:"^MAPS")

		if (pGrpType'="")&&($data(@tGlobal@(pClassName,pMap,pGrpType,pProp))) 
		{
			if ##class(%Dictionary.CompiledProperty).%ExistsId(pClassName_"||"_pProp)
			{
				set ^(pProp)=$ListFromString(pSettings)
				return $$$OK
			}
		}
		else  //we'll loop through the global
		{	
			set tGrp=$order(@tGlobal@(pClassName,pMap,""))
			while tGrp'=""
			{
				set tIdx=$order(@tGlobal@(pClassName,pMap,tGrp,""))
				while tIdx'=""
				{
					if tIdx=pProp 
					{
						set ^(pProp)=$ListFromString(pSettings)
						return $$$OK
					}
					set tIdx=$order(@tGlobal@(pClassName,pMap,tGrp,tIdx))
				}
				set tGrp=$order(@tGlobal@(pClassName,pMap,tGrp))
			}
		}
	}
	catch e
	{
		set tSC = e.AsStatus()
	}
	return tSC
}

///It deletes a MAP.
ClassMethod DeleteMap(pClass as %String, pMap as %String) as %Status
{
	kill ^MAPS(pClass,pMap)
	kill ^MAPSREV(pClass,pMap)
	quit $$$OK
}

///It deletes ^MAPStrash and ^MAPREVtrash for a particular DateTime-Class-Map or DateTime-Class or DateTime
///If no param are introduced, it cleans all the info in *trash globals
ClassMethod CleanTrash(pDateTime as %String="", pClass as %String="", pMap as %String="") as %Status
{
	if (pDateTime'="")&&(pClass'="")&&(pMap'="") 
	{
		kill ^MAPS(pDateTime,pClass,pMap), ^MAPSREV(pDateTime,pClass,pMAp)
		quit $$$OK
	}
	elseif (pDateTime'="")&&(pClass'="") 
	{
		kill ^MAPS(pDateTime,pClass), ^MAPSREV(pDateTime,pClass)
		quit $$$OK
	}
	elseif (pDateTime'="") 
	{
		kill ^MAPS(pDateTime), ^MAPSREV(pDateTime)
		quit $$$OK
	}
	elseif (pDateTime="")&&(pClass="")&&(pMap="")
	{
		kill ^MAPS,^MAPSREV
		quit $$$OK
	}
	quit 0
}
}