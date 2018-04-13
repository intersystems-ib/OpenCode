Class SampleApps.Serialize.TestMethods Extends %RegisteredObject
{

ClassMethod Test(pId as %Integer=50)
{
	#dim m as SampleApps.Serialize.MapTesting
	
	set m = ##class(SampleApps.Serialize.MapTesting).%OpenId(pId)	
	set tObj = m.Export(,,,,1)

	set m2 = ##class(SampleApps.Serialize.MapTesting).%New()
	do m2.Import(,,tObj,1)	
	set tSC = m2.%Save()
	
	write !,"Saving MapTesting ID: "_m2.%Id()
	
	quit
}

ClassMethod LoadAppData(pNum as %Integer=100)
{
	#dim tPath as %String="C:\Users\salva\Documents\_jtTrabajo\_Perforce\Users\jtst\JSONMAPS\SampleApps\Serialize\img\"
	set:(pNum'>0) pNum=1
	
	set tGblResults = "^SampleAppsResults"
	kill @tGblResults
	
	do ##class(SampleApps.Serialize.MapTesting).%KillExtent()
	do ##class(SampleApps.Serialize.PersistObject).%KillExtent()
	
	do ##class(SampleApps.Serialize.MapTesting).Populate(pNum,1)
	do ##class(SampleApps.Serialize.PersistObject).Populate(pNum*10,1)
	
	for i=1:1:pNum 
	{
		set tWithList = $random(3)
		set tWithArray = $random(3)
		set tWithStream = $random(2)
		
		do ..LoadTest(pNum,i,tWithArray,tWithList,tWithStream,tGblResults,tPath)
	}
}

ClassMethod LoadTest(pMaxID as %Integer=50, pId as %Integer=50,pWithArray as %Boolean=1, pWithList as %Boolean=1, pWithStream as %Boolean=1,pGlobalResults as %String="^SampleAppsResults",pStreamPath as %String="")
{
	#dim m as SampleApps.Serialize.MapTesting
	#dim stream1 as %String="stream1.jpg"
	#dim stream2 as %String="stream2.gif"
	#dim stream3 as %String="stream3.docx"
	#dim stream4 as %String="stream4.pdf"
	#dim stream5 as %String="stream5.png"	
	
	set m = ##class(SampleApps.Serialize.MapTesting).%OpenId(pId)
	
	if pWithArray
	{
		set r = $random(pMaxID)+1
		for i = 1:r:(r+$random((pMaxID#10)+1)) 
		{
			set text = "ArrKey "
			do:(i'=pId) m.arrayOfObjects.SetObjectIdAt(i,text_i)
		}
		set:(pGlobalResults'="") @pGlobalResults@("WITHARRAY",pId)=""
		set:(pGlobalResults'="") @pGlobalResults@(pId)=$get(@pGlobalResults@(pId)," ")_", WITHARRAY ("_m.arrayOfObjects.Count()_")"
	}

	if pWithList
	{
		set r = $random(pMaxID)+1
		for i = 1:r:(r+$random((pMaxID#10)+1)) 
		{
			do:(i'=pId) m.listOfObjects.InsertObjectId(i)
		}
		set:(pGlobalResults'="") @pGlobalResults@("WITHLIST",pId)=""
		set:(pGlobalResults'="") @pGlobalResults@(pId)=$get(@pGlobalResults@(pId)," ")_", WITHLIST ("_m.listOfObjects.Count()_")"
	}
	
	if pWithStream
	{
		set tFileName = $case($random(5)+1,1:stream1,2:stream2,3:stream3,4:stream4,5:stream5)
		set tStream = ##class(%Stream.FileBinary).%New()
	    do tStream.LinkToFile(pStreamPath_tFileName)
	    set tSC = m.image.CopyFrom(tStream)
	    write !,"CopyFrom stream: "_tSC
		set:(pGlobalResults'="") @pGlobalResults@("WITHSTREAM",pId)=""
		set:(pGlobalResults'="") @pGlobalResults@(pId)=$get(@pGlobalResults@(pId)," ")_", WITHSTREAM (Size: "_m.image.Size_")"
	    
	}
		
	write !,"Save: "_m.%Save()_" ID: "_pId_"  Arr objects: "_m.arrayOfObjects.Count()	
}


ClassMethod TestExportImportMAP(pClassName as %String="SamplesApp.Serialize.MapTesting",pNewMAPname as %String="MAP11", pTargetClass as %String="TESTCLASS") 
{
	set json = ##class(OPNLib.Serialize.Util).ExportMapsToJSON(pClassName)
	set json.maps.%Get(0).map = pNewMAPname
	set json.maps.%Get(1).map = pNewMAPname
	
	set tSC = ##class(OPNLib.Serialize.Util).ImportMapsFromJSON(json,2,pTargetClass)
	
	quit tSC
}

ClassMethod TestSettings(pClassName as %String="SamplesApp.Serialize.MapTesting")
{
	set j = ##class(JTS.MapTesting).GetMappedPropSettings("code","MAP0",pClassName,1)
	quit
}

ClassMethod Dictionary(pClassName as %String="SamplesApp.Serialize.MapTesting")
{
	set tClass = ##class(%Dictionary.CompiledClass).%OpenId(pClassName)
	
	w !,"Superclass",?70,"Classtype"
	w !,"==========",?70,"========="
	w !,tClass.Super,?70,tClass.ClassType
	w !
	
	set tProperties = tClass.Properties
	write !,"Name",?20,"Type",?50,"RuntimeType",?80,"Collection",?90,"Cardinality"
	write !
	for i=1:1:70 write "="
	write !

	set key=""
	set tProp = tProperties.GetNext(.key)
	while key'="" 
	{
		write !,tProp.Name,?20,tProp.Type,?50,tProp.RuntimeType,?80,tProp.Collection,?90,tProp.Cardinality
		set tProp = tProperties.GetNext(.key)
	}
	quit
}

}