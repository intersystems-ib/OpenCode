IncludeGenerator OPNLib.Serialize.constants
Class OPNLib.Serialize.Template Extends %RegisteredObject [ Abstract ]
{
///It'll use the associated class to generate export/import methods according to MAPs or other criteria decided by implementation
Parameter EXPTASSOCIATEDCLASS;
Parameter EXPTMAP;

ClassMethod Export(pObject as %RegisteredObject, pInObject As %RegisteredObject = "", Output pOutputObject As %RegisteredObject, pDrillDown as %Integer=-1, pArgs...) as %RegisteredObject [CodeMode = objectgenerator]
{
	#dim tProp as %Dictionary.CompiledProperty
	
	quit:(%compiledclass.Name="OPNLib.Serialize.Template") $$$OK  //Doesn't generate map for Adaptor itself
	
	set tMapName=$case(%parameter("EXPTMAP"),"":"MAP0",:%parameter("EXPTMAP"))
	set tClassTarget = %parameter("EXPTASSOCIATEDCLASS")
	
	if (tClassTarget="")||(tMapName="")||($Data(^MAPS(tClassTarget,tMapName))=0)||($Data(^MAPSREV(tClassTarget,tMapName))=0)
	{
		do %code.WriteLine(" //Define EXPTASSOCIATEDCLASS and EXPTMAP parameters to get auto-generated export code")
		do %code.WriteLine(" //Be sure also that the EXPTMAP is defined before compiling this class")
		do %code.WriteLine(" //Generation data: Associated class = "_tClassTarget_" MAP = "_tMapName_" MAP set: "_$Data(^MAPSREV(tClassTarget,tMapName))) 
		quit $$$OK
	}
	
	do %code.WriteLine(" #dim tSC as %Status=$$$OK")
	do %code.WriteLine(" try")
	do %code.WriteLine(" {")
	do %code.WriteLine("   set tDrillDown = pDrillDown")
	do %code.WriteLine("   ")
	do %code.WriteLine("   set tObj = {}")
	do %code.WriteLine("   ") 
	do %code.WriteLine("   //Basic system types")
	set tGroup = $$$tpBSC
	set tIdx=""
	set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		//TO-DO Check if property tIdx exists in class tClassTarget - If not, continue
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine(" set tValue = "_$case(tConvert,"":"pObject."_tIdx,:".."_tConvert_"(pObject."_tIdx_")"))
		do %code.WriteLine(" set tObj."_tTargetProp_" = tValue")
		set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine("   ")
	do %code.WriteLine("   //Lists")
	set tGroup = $$$tpLST
	set tIdx=""
	set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   //ROOM to improve: apply conversion to elements in list")
		do %code.WriteLine("   set tObj."_tTargetProp_" = $ListToString(pObject."_tIdx_".Serialize(),$c(9))")	
		set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine("  ")
	do %code.WriteLine("   //Arrays")
	set tGroup = $$$tpARR
	set tIdx=""
	set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   set tArr = []")
		do %code.WriteLine("   set tValue = "_$case(tConvert,"":"pObject."_tIdx_".GetNext(.tKey)",:".."_tConvert_"(pObject."_tIdx_".GetNext(.tKey))"))
		do %code.WriteLine("   while (tKey'="""")")
		do %code.WriteLine("   {")
		do %code.WriteLine("  	 set tKeyValue = {}.%Set(""key"",tKey)")
		do %code.WriteLine(" 	 do tKeyValue.%Set(""value"",tValue)")	
		do %code.WriteLine("   	 do tArr.%Push(tKeyValue)")	
		do %code.WriteLine(" 	 set tValue = "_$case(tConvert,"":"pObject."_tIdx_".GetNext(.tKey)",:".."_tConvert_"(pObject."_tIdx_".GetNext(.tKey))"))
		do %code.WriteLine("   }")
		do %code.WriteLine("   set tObj."_tTargetProp_" = tArr")
		set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine("   ")
	do %code.WriteLine("   //Simple Object Reference")
	set tGroup = $$$tpOREF
	set tIdx=""
	set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   if $IsObject(pObject."_tIdx_")") 
		do %code.WriteLine("   {")
		do %code.WriteLine("     //If drilldown of this property it's not prohibited by MAP (<=0), then we'll apply")
		do %code.WriteLine("     //the level by default or the level of deep requested in the method call")
		do %code.WriteLine("     set tDrillDown = pDrillDown")
		do %code.WriteLine("     if (pDrillDown < 0)||("_(tPropMAPDrillDown'>0)_")") 
		do %code.WriteLine("     {")
		do %code.WriteLine("       set tDrillDown = "_tPropMAPDrillDown)
		do %code.WriteLine("     }")
		if (tClassRef '= "")
		{
			do %code.WriteLine("     set tJSONRef="""" ")
			do %code.WriteLine("     if (tDrillDown > 0)&&(##class(%Dictionary.CompiledClass).%OpenId("""_tClassRef_""").Super[""OPNLib.Serialize.Adaptor"")")
			do %code.WriteLine("     {")
			do %code.WriteLine("       set tJSONRef = pObject."_tIdx_".Export("""_tMAPClass_""","""_tMAP_""",,,(tDrillDown-1))")
			do %code.WriteLine("     }")
			do %code.WriteLine("     //elseif // here in default JSON we have an option to export OREFs...") 
			do %code.WriteLine("     //{")
			do %code.WriteLine("     //  set tJSONRef={""objref"":("" ""_$property(pObject,tIdx))}")
			do %code.WriteLine("     //}")
			do %code.WriteLine("     set tObj."_tTargetProp_" = tJSONRef")
		}
		else
		{
			do %code.WriteLine("   //Classname of Referenced Object was not indicated in MAP - No auto-generated import code included")
		
		}
		
		do %code.WriteLine("   }")
		set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine("   ")
	set tGroup = $$$tpARROBJ
	do %code.WriteLine("   //Arrays or Relationship Objects")
	set tIdx=""
	set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   if $IsObject(pObject."_tIdx_")") 
		do %code.WriteLine("   {")
		do %code.WriteLine("     //If drilldown of this property it's not prohibited by MAP (<=0), then we'll apply")
		do %code.WriteLine("     //the level by default or the level of deep requested in the method call")
		do %code.WriteLine("     set tDrillDown = pDrillDown")
		do %code.WriteLine("     if (pDrillDown < 0)||("_(tPropMAPDrillDown'>0)_")") 
		do %code.WriteLine("     {")
		do %code.WriteLine("       set tDrillDown = "_tPropMAPDrillDown)
		do %code.WriteLine("     }")
		do %code.WriteLine("     set tArr = []")
		do %code.WriteLine("     set tObjChildMany = pObject."_tIdx_".GetNext(.tKey)")
		do %code.WriteLine("     while (tKey'="""")")
		do %code.WriteLine("     {   ")
		do %code.WriteLine("       set tJSONRef = """" ")
		if (tClassRef '= "")
		{
			do %code.WriteLine("       if (tDrillDown > 0)&&(##class(%Dictionary.CompiledClass).%OpenId("""_tClassRef_""").Super[""OPNLib.Serialize.Adaptor"")")
			do %code.WriteLine("       {")
			do %code.WriteLine("         set tJSONRef = tObjChildMany.Export("""_tMAPClass_""","""_tMAP_""",,,(tDrillDown-1))")
			do %code.WriteLine("       }")
		}
		else
		{
			do %code.WriteLine("   //Classname of Referenced Object was not indicated in MAP - No auto-generated import code included")
		
		}
		do %code.WriteLine("       set tArrElem = {""key"":(tKey),""value"":(tJSONRef)}")
		do %code.WriteLine("       do tArr.%Push(tArrElem)")	
		do %code.WriteLine("       set tObjChildMany = pObject."_tIdx_".GetNext(.tKey)")
		do %code.WriteLine("     }")
		do %code.WriteLine("     set tObj."_tTargetProp_" = tArr")							
		do %code.WriteLine("   }")
		set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine(" ")
	set tGroup = $$$tpLSTOBJ  
	do %code.WriteLine("   //Lists of Objects")
	set tIdx=""
	set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   if $IsObject(pObject."_tIdx_")") 
		do %code.WriteLine("   {")
		do %code.WriteLine("     //If drilldown of this property it's not prohibited by MAP (<=0), then we'll apply")
		do %code.WriteLine("     //the level by default or the level of deep requested in the method call")
		do %code.WriteLine("     set tDrillDown = pDrillDown")
		do %code.WriteLine("     if (pDrillDown < 0)||("_(tPropMAPDrillDown'>0)_")") 
		do %code.WriteLine("     {")
		do %code.WriteLine("       set tDrillDown = "_tPropMAPDrillDown)
		do %code.WriteLine("     }")
		do %code.WriteLine("     set tArr = []")
		do %code.WriteLine("     set tObjChildMany = pObject."_tIdx_".GetNext(.tKey)")
		do %code.WriteLine("     while (tKey'="""")")
		do %code.WriteLine("     {   ")
		do %code.WriteLine("       set tJSONRef = """" ")
		if (tClassRef '= "")
		{
			do %code.WriteLine("       if (tDrillDown > 0)&&(##class(%Dictionary.CompiledClass).%OpenId("""_tClassRef_""").Super[""OPNLib.Serialize.Adaptor"")")
			do %code.WriteLine("       {")
			do %code.WriteLine("         set tJSONRef = tObjChildMany.Export("""_tMAPClass_""","""_tMAP_""",,,(tDrillDown-1))")
			do %code.WriteLine("       }")
		}
		else
		{
			do %code.WriteLine("   //Classname of Referenced Object was not indicated in MAP - No auto-generated import code included")		
		}
		do %code.WriteLine("       do tArr.%Push(tJSONRef)")	
		do %code.WriteLine("       set tObjChildMany = pObject."_tIdx_".GetNext(.tKey)")
		do %code.WriteLine("     }")
		do %code.WriteLine("     set tObj."_tTargetProp_" = tArr")							
		do %code.WriteLine("   }")
		set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine("   ")
	set tGroup = $$$tpSTREAM  
	do %code.WriteLine("   //Streams")
	set tIdx=""
	set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   if $IsObject(pObject."_tIdx_")")
		do %code.WriteLine("   {")
		do %code.WriteLine("     set tStream = pObject."_tIdx)
		if tConvert'=""
		{
			do %code.WriteLine("     set tContent = .."_tConvert_"(tStream)")
		}
		else 
		{
			do %code.WriteLine("     //No conversion method defined for this MAP. Applying Base64 encoding by default")
			do %code.WriteLine("     set tContent = """"")
			do %code.WriteLine("     while 'tSream.AtEnd")
			do %code.WriteLine("     {")
			do %code.WriteLine("     	set tContent = tContent_tStream.Read()")
			do %code.WriteLine("     }")
			do %code.WriteLine("     set tContent = $system.Encryption.Base64Encode(tContent)")
		} 
		do %code.WriteLine("     set tObj."_tTargetProp_" = tContent")
		do %code.WriteLine("   }")
		set tIdx = $order(^MAPS(tClassTarget,tMapName,tGroup,tIdx))
    }
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

/// Imports data coming in <var>pInObject</var> in the instance of the caller object (<var>pObject</var>)
/// (<var>pInObject</var> could come in raw %Stream format, if so, it asssumes it can be directly converted to a %DynamicObject) 
ClassMethod Import(ByRef pObject as %RegisteredObject,pInObject as %RegisteredObject,pDrillDown as %Integer=-1,ByRef pArgs...) As %Status [ CodeMode = objectgenerator, ForceGenerate ]
{
	#dim %compiledclass as %Dictionary.CompiledClass
	#dim tProp as %Dictionary.CompiledProperty
	
	quit:(%compiledclass.Name="OPNLib.Serialize.Template") $$$OK  //Doesn't generate map for Adaptor itself
	
	set tMapName=$case(%parameter("EXPTMAP"),"":"MAP0",:%parameter("EXPTMAP"))
	set tClassTarget = %parameter("EXPTASSOCIATEDCLASS")
	
	if (tClassTarget="")||(tMapName="")||($Data(^MAPS(tClassTarget,tMapName))=0)||($Data(^MAPSREV(tClassTarget,tMapName))=0)
	{
		do %code.WriteLine(" //Define EXPTASSOCIATEDCLASS and EXPTMAP parameters to get auto-generated export code")
		do %code.WriteLine(" //Be sure also that the EXPTMAP is defined before compiling this class")
		do %code.WriteLine(" //Generation data: Associated class = "_tClassTarget_" MAP = "_tMapName_" MAP set: "_$Data(^MAPSREV(tClassTarget,tMapName))) 
		quit $$$OK
	}
	
	do %code.WriteLine(" #dim tSC as %Status=$$$OK")
	do %code.WriteLine(" try")
	do %code.WriteLine(" {")
	do %code.WriteLine("   set tDrillDown = pDrillDown")
	do %code.WriteLine("   ")
	do %code.WriteLine("   if ($zcvt(pInObject.%ClassName(1),""l"") ?1""%"".E1.""stream"".E)  //OK, it's not very clean...just a gross check it this is a system stream")
	do %code.WriteLine("   {")
	do %code.WriteLine("      set pInObject = {}.%FromJSON(pInObject)")
	do %code.WriteLine("   }")
	do %code.WriteLine("   elseif pInObject.%ClassName(1)'=""%Library.DynamicObject""")
	do %code.WriteLine("   {")
	do %code.WriteLine("      return $$$ERROR(5001,""Valid input data should be a %Stream.* or a %DynamicObject (JSON)"")")
	do %code.WriteLine("   }")
	do %code.WriteLine("   s tObj = {}")
	do %code.WriteLine("   ") 
	do %code.WriteLine(" //Basic types")
	set tGroup = $$$tpBSC
	set tIdx=""
	set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   set pObject."_tTargetProp_" = "_$case(tConvert,"":"pInObject."_tIdx,:".."_tConvert_"(pInObject."_tIdx_")"))	
		set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine("   ")
	do %code.WriteLine(" //Lists")
	set tGroup = $$$tpLST
	set tIdx=""
	set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   set tValue = $ListFromString(pInObject."_tIdx_",$c(9))")
		do %code.WriteLine("   set tSC = pObject."_tTargetProp_".InsertList(tValue)")
		set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine(" //Arrays")
	set tGroup = $$$tpARR
	set tIdx=""
	set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   if pInObject.%GetTypeOf("""_tIdx_""") = ""array""") 
		do %code.WriteLine("   {")
		do %code.WriteLine("     set tIterator = pInObject."_tIdx_".%GetIterator()")
		do %code.WriteLine("     while tIterator.%GetNext(.tElement,.tKeyValue)")
		do %code.WriteLine("     {")
		do %code.WriteLine("       set tKey = tKeyValue.key")
		do %code.WriteLine("       set tValue = "_$case(tConvert,"":"tKeyValue.value",:".."_tConvert_"(tKeyValue.value)"))
		do %code.WriteLine("       set tSC = pObject."_tTargetProp_".SetAt(tValue,tKey)")
		do %code.WriteLine("     }")
		do %code.WriteLine("   }")
		set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine(" ")
	do %code.WriteLine(" //Referenced Objects")
	set tGroup = $$$tpOREF
	set tIdx=""
	set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   //If drilldown of this property it's not prohibited by MAP (=0), then we'll apply")
		do %code.WriteLine("   //the level by default or the level of deep requested in the method call")
		do %code.WriteLine("   set tDrillDown = pDrillDown")
		do %code.WriteLine("   if (pDrillDown < 0)||("_(tPropMAPDrillDown'>0)_")") 
		do %code.WriteLine("   {")
		do %code.WriteLine("     set tDrillDown = "_tPropMAPDrillDown)
		do %code.WriteLine("   }")	
		if (tClassRef'="")
		{
			do %code.WriteLine("   //Only if there is a json object we'll try to import")
			do %code.WriteLine("   //By default we'll assume that referenced object it'll be a new one. ")
			do %code.WriteLine("   //This could be improved to allow import references to existing objects")
			do %code.WriteLine("   if (tDrillDown > 0)&&(pInObject.%GetTypeOf("""_tIdx_""") = ""object"")&&(##class(%Dictionary.CompiledClass).%OpenId("""_tClassRef_""").Super[""OPNLib.Serialize.Adaptor"")") 
			do %code.WriteLine("   {")
			do %code.WriteLine("      set tRefObject = $classmethod("""_tClassRef_""",""%New"")")
			do %code.WriteLine("      do tRefObject.Import("""_tMAPClass_""","""_tMAP_""",pInObject."_tIdx_",(tDrillDown-1))")
			do %code.WriteLine("      set pObject."_tTargetProp_" = tRefObject")
			do %code.WriteLine("   }")
		}
		else
		{
			do %code.WriteLine("   //Classname of Referenced Object was not indicated in MAP - No auto-generated import code included")
		
		}
		set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine(" ")
	do %code.WriteLine(" //Arrays of objects & Relationships")
	set tGroup = $$$tpARROBJ
	set tIdx=""
	set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   //If drilldown of this property it's not prohibited by MAP (=0), then we'll apply")
		do %code.WriteLine("   //the level by default or the level of deep requested in the method call")
		do %code.WriteLine("   set tDrillDown = pDrillDown")
		do %code.WriteLine("   if (pDrillDown < 0)||("_(tPropMAPDrillDown'>0)_")") 
		do %code.WriteLine("   {")
		do %code.WriteLine("     set tDrillDown = "_tPropMAPDrillDown)
		do %code.WriteLine("   }")
		do %code.WriteLine("   //Only if there is a json object we'll try to import")
		do %code.WriteLine("   //By default we'll assume that referenced object it'll be a new one. ")
		do %code.WriteLine("   //ROOM to improve - This perhaps could be improved to allow import references to existing objects")
		if (tClassRef'="")
		{		
			do %code.WriteLine("   if (tDrillDown > 0)&&(pInObject.%GetTypeOf("""_tIdx_""") = ""array"")") 
			do %code.WriteLine("   {")
			do %code.WriteLine("     set tIterator = pInObject."_tIdx_".%GetIterator()")
			do %code.WriteLine("     while tIterator.%GetNext(.tKey,.tValue)")
			do %code.WriteLine("     {")
			do %code.WriteLine("       //Each array element will be of type {""key"":<key>,""value"":<JSON object>")	
			do %code.WriteLine("       set tElemObj = $classmethod("""_tClassRef_""",""%New"")")
			do %code.WriteLine("       do tElemObj.Import("""_tMAPClass_""","""_tMAP_""",tValue.value,(tDrillDown-1))")
			do %code.WriteLine("       if $IsObject(tElemObj)")
			do %code.WriteLine("       {")
			do %code.WriteLine("         set tSC = pObject."_tTargetProp_".SetAt(tElemObj,tValue.key)")
			do %code.WriteLine("       }")
			do %code.WriteLine("     }")
			do %code.WriteLine("   }")
		}
		else
		{
			do %code.WriteLine("   //Classname of Referenced Object was not indicated in MAP - No auto-generated import code included")
		
		}
		set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine(" ")
	do %code.WriteLine(" //List of objects")
	set tGroup = $$$tpLSTOBJ
	set tIdx=""
	set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
		do %code.WriteLine("   //If drilldown of this property it's not prohibited by MAP (=0), then we'll apply")
		do %code.WriteLine("   //the level by default or the level of deep requested in the method call")
		do %code.WriteLine("   set tDrillDown = pDrillDown")
		do %code.WriteLine("   if (pDrillDown < 0)||("_(tPropMAPDrillDown'>0)_")") 
		do %code.WriteLine("   {")
		do %code.WriteLine("     set tDrillDown = "_tPropMAPDrillDown)
		do %code.WriteLine("   }")
		do %code.WriteLine("   //Only if there is a json object we'll try to import")
		do %code.WriteLine("   //By default we'll assume that referenced object it'll be a new one. ")
		do %code.WriteLine("   //ROOM to improve - This perhaps could be improved to allow import references to existing objects")
		if tClassRef'=""
		{
			do %code.WriteLine("   if (tDrillDown > 0)&&(pInObject.%GetTypeOf("""_tIdx_""") = ""array"")") 
			do %code.WriteLine("   {")
			do %code.WriteLine("     set tIterator = pInObject."_tIdx_".%GetIterator()")
			do %code.WriteLine("     while tIterator.%GetNext(.tKey,.tValue)")
			do %code.WriteLine("     {")
			do %code.WriteLine("       //Each array element will be of type {""key"":<key>,""value"":<JSON object>")	
			do %code.WriteLine("       set tElemObj = $classmethod("""_tClassRef_""",""%New"")")
			do %code.WriteLine("       do tElemObj.Import("""_tMAPClass_""","""_tMAP_""",tValue.value,(tDrillDown-1))")
			do %code.WriteLine("       if $IsObject(tElemObj)")
			do %code.WriteLine("       {")
			do %code.WriteLine("         set tSC = pObject."_tTargetProp_".Insert(tElemObj)")
			do %code.WriteLine("       }")
			do %code.WriteLine("     }")
			do %code.WriteLine("   }")
		}
		else
		{
			do %code.WriteLine("   //Classname of Referenced Object was not indicated in MAP - No auto-generated import code included")
		
		}
		set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine(" ")
	do %code.WriteLine("   //Streams")
	set tGroup = $$$tpSTREAM
	set tIdx=""
	set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
	while (tIdx'="")
	{
		set $ListBuild(tTargetProp,tConvert,tPropMAPDrillDown,tClassRef,tMAPClass,tMAP)=$Get(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
		if tConvert'=""
		{
			do %code.WriteLine("   set tValue = .."_tConvert_"(pInObject."_tIdx_")")
		}
		else
		{
			do %code.WriteLine("   set tContent = $system.Encryption.Base64Decode(pInObject."_tIdx_")")
			do %code.WriteLine("   set tValue = ##class(%Stream.TmpCharacter).%New()")
			do %code.WriteLine("   do tValue.Write(tContent)")
		}
	
		do %code.WriteLine("   set tSC = pObject."_tTargetProp_".CopyFrom(tValue)")	
		set tIdx = $order(^MAPSREV(tClassTarget,tMapName,tGroup,tIdx))
    }
	do %code.WriteLine(" ")
	do %code.WriteLine(" }")
	do %code.WriteLine(" catch e")
	do %code.WriteLine(" {")
	do %code.WriteLine("   set tSC = e.AsStatus()")
	do %code.WriteLine(" }")
	do %code.WriteLine(" quit tSC")

	quit $$$OK
}


ClassMethod exportDate(pInput as %Date) as %String
{
	quit $zd(pInput,3,,,,,,,"")
	
}

ClassMethod importDate(pInput as %String) as %Date
{
	quit $zdh(pInput,3,,,,,,,0)
}

ClassMethod exportTime(pInput as %Time) as %String
{
	//Input time by default is converted to the form "hh:mm:ss" (24-hour clock).
	quit $zt(pInput,,,"")
}

ClassMethod importTime(pInput as %String) as %Time
{
	//Expected format by default hh:mm:ss (24-hour clock)
	quit $zth(pInput,,0)
}

ClassMethod exportTimeStamp(pInput as %TimeStamp="") as %String
{
	quit pInput
}

ClassMethod importTimeStamp(pInput as %String="") as %TimeStamp
{
	quit pInput
}

ClassMethod exportDateTime(pInput as %DateTime="") as %String
{
	quit $zdt(pInput,3,,,,,,,,,"")
}
ClassMethod importDateTime(pInput as %String="") as %DateTime
{
	quit $zdth(pInput,3,,,,,,,,0)
}
ClassMethod exportBase64Stream(pInput as %Stream.TmpCharacter) as %String
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

ClassMethod importBase64Stream(pInput as %String) as %Stream.TmpCharacter
{
	set tContent = $system.Encryption.Base64Decode(pInput)
	set tStream = ##class(%Stream.TmpCharacter).%New()
	do tStream.Write(tContent)
	quit tStream
}

}