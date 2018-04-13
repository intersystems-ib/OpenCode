Class SampleApps.Serialize.MapTesting.customMaps
{

ClassMethod ExpMapTestingCustomMAP1(ByRef pObject as SampleApps.Serialize.MapTesting,pInObject as %RegisteredObject,Output pOutputObject as %RegisteredObject, pDrillDown as %Integer=-1, pArgs...) as %RegisteredObject
{
	#dim pOutputObject as %Library.DynamicObject
	
	set tJSON = pObject.exportStd(pObject,,.pOutputObject,pDrillDown,"MAP1")
	
	return tJSON
	
}

ClassMethod ImpMapTestingCustomMAP1(ByRef pObject as SampleApps.Serialize.MapTesting,pInObject as %DynamicObject, pDrillDown as %Integer=-1,pArgs...) as %Status
{
	set tSC = pObject.importStd(.pObject,pInObject,pDrillDown,"MAP1")
	quit tSC
}

}