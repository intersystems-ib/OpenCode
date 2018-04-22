///Just an example. We could use whatever class to gather several methods to export/import data for one or several classes
/// For example, an export/import method to/from JSON/CSV/XML,... that count on a set of several common properties (FirstName, LastName, DOB, ZIP)
/// could be used for several classes
Class SampleApps.Serialize.CustomMaps
{

ClassMethod exportTestJSON(ByRef pObject as %RegisteredObject,pInObject as %RegisteredObject,Output pOutputObject as %RegisteredObject, pDrillDown as %Integer=-1, pArgs...) as %RegisteredObject
{
	set json = {"pObject":(" "_pObject),"pInObject":(" "_pInObject),"pDrillDown":(pDrillDown),"pArgs":($Get(pArgs,0))}
	set json.pOutputObject = json.%ToJSON()
	set pOutputObject = json
	return json
}

ClassMethod importTestJSON(ByRef pObject as %RegisteredObject,pInObject as %RegisteredObject, pDrillDown as %Integer=-1,pArgs...) as %Status
{
	if $IsObject(pObject) && (pObject.%ClassName(1)="%Library.DynamicObject") && (pObject.%Size()'=0)
	{
		set objText = pObject.%ToJSON()
		set ^SampleApps("Formats","importTestJSON",$zdt($h))=objText
	} 
	quit $$$OK
}
}