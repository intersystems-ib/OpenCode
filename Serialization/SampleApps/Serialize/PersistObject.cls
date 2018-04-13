Class SampleApps.Serialize.PersistObject Extends (%Persistent,%Library.Populate,OPNLib.Serialize.Adaptor,%XML.Adaptor)
{
Parameter EXPTDRILLDOWN=1;
Parameter EXPTINCLUDEOREFS=0;

Property cod As %Integer;
Property description as %String;
Property colours as list of %String;
Property start as %Date;
Property yearEnd as %Integer;
Property document as %Stream.GblChrCompress;

Relationship MapTesting As SampleApps.Serialize.MapTesting [ Cardinality = one, Inverse = childObjects ];

/// documentation
Index idxTest On cod;
Storage Default
{
<Data name="PersistObjectDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>cod</Value>
</Value>
<Value name="3">
<Value>MapTesting</Value>
</Value>
<Value name="4">
<Value>description</Value>
</Value>
<Value name="5">
<Value>colours</Value>
</Value>
<Value name="6">
<Value>start</Value>
</Value>
<Value name="7">
<Value>yearEnd</Value>
</Value>
<Value name="8">
<Value>document</Value>
</Value>
</Data>
<DataLocation>^SampleApps.SF696.PersistObjectD</DataLocation>
<DefaultData>PersistObjectDefaultData</DefaultData>
<IdLocation>^SampleApps.SF696.PersistObjectD</IdLocation>
<IndexLocation>^SampleApps.SF696.PersistObjectI</IndexLocation>
<StreamLocation>^SampleApps.SF696.PersistObjectS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}