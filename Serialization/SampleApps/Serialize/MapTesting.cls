Class SampleApps.Serialize.MapTesting Extends (%Persistent,OPNLib.Serialize.Adaptor,%Library.Populate)
{
Parameter EXPTDRILLDOWN=1;
Parameter EXPTINCLUDEOREFS=0;
Parameter EXPTEXCLUDEPROP;

Property code As %Integer;

Property description As %String;

Property dateTest As %Date;

Property datetimeTest As %DateTime;

Property timestampTest As %TimeStamp;

Property timeTest As %Time;

Property floatNumber As %Numeric;

Property listOfSomething As list Of %String;

Property stdListOfSomething As %Library.ListOfDataTypes;

Property arrayOfSomething As array Of %String;

Property listOfObjects As list Of SampleApps.Serialize.MapTesting;

Property arrayOfObjects As array Of SampleApps.Serialize.MapTesting;

Property reference As SampleApps.Serialize.MapTesting;

Property customBasicDT As JTS.myType;

Property image As %Stream.GlobalBinary;

Property listOfImages As list Of %Stream.GlobalBinary;

Relationship childObjects As SampleApps.Serialize.PersistObject [ Cardinality = many, Inverse = MapTesting ];

Storage Default
{
<Data name="MapTestingDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>code</Value>
</Value>
<Value name="3">
<Value>description</Value>
</Value>
<Value name="4">
<Value>dateTest</Value>
</Value>
<Value name="5">
<Value>datetimeTest</Value>
</Value>
<Value name="6">
<Value>timestampTest</Value>
</Value>
<Value name="7">
<Value>timeTest</Value>
</Value>
<Value name="8">
<Value>floatNumber</Value>
</Value>
<Value name="9">
<Value>listOfSomething</Value>
</Value>
<Value name="10">
<Value>stdListOfSomething</Value>
</Value>
<Value name="11">
<Value>listOfObjects</Value>
</Value>
<Value name="12">
<Value>reference</Value>
</Value>
<Value name="13">
<Value>customBasicDT</Value>
</Value>
<Value name="14">
<Value>imagen</Value>
</Value>
<Value name="15">
<Value>listOfImages</Value>
</Value>
<Value name="16">
<Value>image</Value>
</Value>
</Data>
<Data name="arrayOfObjects">
<Attribute>arrayOfObjects</Attribute>
<Structure>subnode</Structure>
<Subscript>"arrayOfObjects"</Subscript>
</Data>
<Data name="arrayOfSomething">
<Attribute>arrayOfSomething</Attribute>
<Structure>subnode</Structure>
<Subscript>"arrayOfSomething"</Subscript>
</Data>
<DataLocation>^SampleApps.SeriF696.MapTestingD</DataLocation>
<DefaultData>MapTestingDefaultData</DefaultData>
<IdLocation>^SampleApps.SeriF696.MapTestingD</IdLocation>
<IndexLocation>^SampleApps.SeriF696.MapTestingI</IndexLocation>
<StreamLocation>^SampleApps.SeriF696.MapTestingS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}