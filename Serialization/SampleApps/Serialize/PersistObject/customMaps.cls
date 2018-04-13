Class SampleApps.Serialize.PersistObject.customMaps
{

/// Just an example. 
/// This method can be used with gral Export, to get data info in XML format within a stream (in this case using %XML.Adaptor functionality)
ClassMethod ExpPersistObjectXML(ByRef pObject as SampleApps.Serialize.PersistObject,pInObject as %RegisteredObject,Output pOutputObject as %RegisteredObject, pDrillDown as %Integer=-1, pArgs...) as %RegisteredObject
{
	set tXMLstream = ##class(%Stream.GlobalCharacter).%New()

	if $IsObject(pObject) && (##class(%Dictionary.CompiledClass).%OpenId(pObject.%ClassName(1)).Super["%XML.Adaptor") 
	{
		set %response.ContentType = "text/xml"
		set %response.CharSet = "utf-8"
		do pObject.XMLExportToStream(.tXMLstream)
		set pOutputObject = tXMLstream
		return tXMLstream
	}
	else
	{
		do tXMLstream.Write("<status>No input data or object class doesn't inherit from %XML.Adaptor</status>")
		set pOutputObject = tXMLstream
	}
	quit tXMLstream
}

ClassMethod ImpPersistObjectXML(ByRef pObject as SampleApps.Serialize.PersistObject,pInObject as %Stream.GlobalCharacter, pDrillDown as %Integer=-1,pArgs...) as %Status
{
	#dim tXMLreader as %XML.Reader
	#dim tSC as %Status=$$$OK
	#dim tObject as SampleApps.Serialize.PersistObject
	#dim e as %Exception.General
	
	// We should populate incoming pObject with XML content.. Current logic based on XMLReader creates from scratch the objects which makes very difficult to use that logic 
	// But we use it as it's an example
	try 
	{
		set tXMLreader = ##class(%XML.Reader).%New()
		do tXMLreader.OpenStream(pInObject)
		do tXMLreader.Correlate("PersistObject","SampleApps.Serialize.PersistObject")
		do tXMLreader.Next(.tObject,.tSC)
		
		set pObject.cod = tObject.cod
		set pObject.start = tObject.start
		set pObject.yearEnd = tObject.yearEnd
		set pObject.description = tObject.description
		set pObject.colours = tObject.colours
		if $IsObject(tObject.document) && (tObject.document.Size>0)
		{
			do pObject.document.CopyFrom(tObject.document)
		}
	}
	catch e
	{
		set tSC = e.AsStatus()
	}
	
	quit tSC
}
}