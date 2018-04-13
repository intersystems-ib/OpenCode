Class SampleApps.Serialize.Dummy Extends (%Persistent,%Populate, OPNLib.Serialize.Adaptor)
{
Property literal as %String;
Property numeric as %Integer;
Storage Default
{
<Data name="DummyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>literal</Value>
</Value>
<Value name="3">
<Value>numeric</Value>
</Value>
</Data>
<DataLocation>^SampleApps.Serialize.DummyD</DataLocation>
<DefaultData>DummyDefaultData</DefaultData>
<IdLocation>^SampleApps.Serialize.DummyD</IdLocation>
<IndexLocation>^SampleApps.Serialize.DummyI</IndexLocation>
<StreamLocation>^SampleApps.Serialize.DummyS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}