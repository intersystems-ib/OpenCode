/// John Conway Game of Life simulation
/// 
/// This class allows to define different worlds, with different basic initial rules. From an initial state we could run different iterations that will make
/// that world evolve according to John Conway Game of Life rules. 
/// Default rules (RulesOfLife = 2.3/3):
///   - A block is alive or dead
///   - An alive block survives if it's in contact with 2 or 3 alive blocks
///   - An alive block deaths if surrounded by more than 3 alive blocks (over population) of just by one or cero (loneless)
///   - A death block becomes alive if surrounded by exactly 3 alive blocks (new born)
/// We can change the basic rules changing RulesOfLife property
/// Example - Testing the game
///    From your terminal prompt:
///      USER> set g = ##class(OPNLib.Game.ConwayLifeGame).%New()
///      USER> do g.Initialize(4) 
///      USER> do g.Iterate(200)
///      USER> do g.DisplayRange(0,200,0.5)  //it will display one iteration from 0 to 200, each 0.5 seconds (default)
Class OPNLib.Game.ConwayLifeGame Extends %Persistent
{

/// To keep identified each "universe"
Property World As %Integer [ Identity ];

/// Width dimension
Property Rows As %Integer(MINVAL = 15) [ InitialExpression = 40 ];

/// High dimension
Property Columns As %Integer(MINVAL = 15) [ InitialExpression = 100 ];

/// Number of Iterations executed to get to the final view
Property Iterations As %Integer [ InitialExpression = 0 ];

/// Basic rules <digit1>.<digit2>/<digit3> 
/// where <digit1><digit2> are exact number of alive blocks around to survive (<digit1> or <digit2>), and <digit3> are exact blocks to new born
/// By default, original rules: 2 or 3 to keep alive, 3 for a new born
Property RulesOfLife As %String [ InitialExpression = "2.3/3" ];

/// documentation
Index idxIDKEY On World [ IdKey ];

/// It restart the board allowing different initial configurations:
/// 0 (default): fully random (similar to 20% of alive blocks
/// 1 : Intermittent blocks (vertical/horizontal line of three blocks that keeps changing between one and the other forever
/// 2 : Stationary life: an initial configuration that evolves to a form that maintains equal forever
/// 3 : Gliders : forms that change till evolve to the original one but one block below diagonally
/// 4 : Glider machine gun : Bigger than a glider form that, after a while, change its form, emits a glider and comes back to its original form and position
/// 5 : Mixed patterns - choose several of patterns above
/// 
/// WARNING: Initialize kill all previous iterations associated with the current world
/// 
Method Initialize(pConfiguration As %Integer = 0, pIniRow As %Integer = 3, pIniCol As %Integer = 3) As %String
{
	if ..World="" do ..%Save()  //it saves the object before creating the first "origin" (iteration 0)
	
	kill ^OPNLib.Game.CWLF(..World)
	set ..Iterations = 0
	
	if pConfiguration = 1 // 
	{
		do ..EmptyBoard()
		do ..Oscillator(1,pIniRow,pIniCol)  //bar
		do ..Oscillator(2,pIniRow+5,pIniCol+5)  //toad		
	}
	elseif pConfiguration = 2
	{
		do ..EmptyBoard()
		do ..StillLife(1,pIniRow,pIniCol)
		do ..StillLife(2,pIniRow+5,pIniCol+5)
	}
	elseif pConfiguration = 3
	{
		do ..EmptyBoard()
		do ..Glider(1,pIniRow,pColRow)
		do ..Glider(2,pIniRow+5,pColRow+5)
	}
	elseif pConfiguration = 4
	{
		do ..EmptyBoard()
		do ..GliderMachineGun(pIniRow,pIniCol)
	}
	elseif pConfiguration = 5
	{
		set tNumOsc = $random(5)+1
		set tNumStillLife = $random(5)+1
		set tNumGliders = $random(5)+1
		set tNumMachineGun = $random(2)+1
		
		do ..EmptyBoard()
		
		for i = 1:1:tNumOsc do ..Oscillator($random(2)+1,$random(..Rows)+1,$random(..Columns)+1)
		for i = 1:1:tNumStillLife do ..StillLife($random(2)+1,$random(..Rows)+1,$random(..Columns)+1)
		for i = 1:1:tNumGliders do ..Glider($random(2)+1,$random(..Rows)+1,$random(..Columns)+1)
		for i = 1:1:tNumMachineGun do ..GliderMachineGun($random(..Rows)+1,$random(..Columns)+1)
	}
	else // random (20% alive)
	{
		for i=1:1:..Rows
		{
			for j=1:1:..Columns
			{
				set $BIT(^OPNLib.Game.CWLF(..World,0,i),j)=(($random(10)#10) '> 0) // only 0 if $random = 10, so .. 10% theoretical probability of value 1
			}
		}
	}
	quit $$$OK
}

Method EmptyBoard() As %Status
{
	set $bit(emptyRow,..Columns)=""
	for i=1:1:..Rows
	{
		set ^OPNLib.Game.CWLF(..World,0,i)=emptyRow
	}

	quit $$$OK
}

/// Oscillator patterns
/// pType = 1 (default) horizontal/vertical line  | 2 - toad
/// 01234567   012345678
/// 1-------   1--------
/// 2--xxx--   2---xxx--
/// 3-------   3--xxx---
///           4--------
Method Oscillator(pType As %Integer = 1, pIniRow As %Integer = 3, pIniCol As %Integer = 3)
{
		
	for i = 1:1:4 set tRow(i)=pIniRow+i
	for i = 1:1:8 set tCol(i)=pIniCol+i

	if pType=2 // Toad pattern
	{
		set $bit(rowLine2,tCol(4))=1
		set $bit(rowLine2,tCol(5))=1
		set $bit(rowLine2,tCol(6))=1		

		set $bit(rowLine3,tCol(3))=1
		set $bit(rowLine3,tCol(4))=1
		set $bit(rowLine3,tCol(5))=1		

		set ^OPNLib.Game.CWLF(..World,0,tRow(2)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(2))|rowLine2)	
		set ^OPNLib.Game.CWLF(..World,0,tRow(3)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(3))|rowLine3)	
	}
	else
	{
		set $bit(rowLine2,tCol(3))=1
		set $bit(rowLine2,tCol(4))=1
		set $bit(rowLine2,tCol(5))=1

		// It positions three block line in pRow
		set ^OPNLib.Game.CWLF(..World,0,tRow(2)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(2))|rowLine2)	

	}
}

/// Still life patterns
/// pType = 1 (default) square / 2 - beehive
/// 0123456    01234567
/// 1------    1-------
/// 2--x---    2---x---
/// 3--xx--    3--x-x--
/// 4------	  4--x-x--
///           5---x---
/// 	      6-------
Method StillLife(pType As %Integer = 1, pIniRow As %Integer = 3, pIniCol As %Integer = 3)
{
	for i = 1:1:6 set tRow(i)=pIniRow+i
	for i = 1:1:7 set tCol(i)=pIniCol+i

	if pType=2 // beehive
	{
		set $bit(rowLine2,tCol(4))=1
		set $bit(rowLine3,tCol(3))=1
		set $bit(rowLine3,tCol(5))=1
		set $bit(rowLine4,tCol(3))=1
		set $bit(rowLine4,tCol(5))=1
		set $bit(rowLine5,tCol(4))=1
	
		// It positions bit lines from row pIniRow
		set ^OPNLib.Game.CWLF(..World,0,tRow(2)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(2))|rowLine2)
		set ^OPNLib.Game.CWLF(..World,0,tRow(3)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(3))|rowLine3)		
		set ^OPNLib.Game.CWLF(..World,0,tRow(4)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(4))|rowLine4)
		set ^OPNLib.Game.CWLF(..World,0,tRow(5)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(5))|rowLine5)		
	}
	else // square
	{
		set $bit(rowLine2,tCol(3))=1
		set $bit(rowLine3,tCol(3))=1
		set $bit(rowLine3,tCol(4))=1
	
		// It positions bit lines from row 2
		set ^OPNLib.Game.CWLF(..World,0,tRow(2)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(2))|rowLine2)
		set ^OPNLib.Game.CWLF(..World,0,tRow(3)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(3))|rowLine3)		
	}
}

/// Glider pattern
/// pType = 1 (default) | 2 - R-pentomino
/// 012345678   01234567
/// 1--------   1-------
/// 2----x---   2---xx--
/// 3--x-x---   3--xx---
/// 4---xx---   4---x---
/// 5--------   5-------
Method Glider(pType As %Integer = 1, pIniRow As %Integer = 3, pIniCol As %Integer = 3)
{
	for i = 1:1:5 set tRow(i)=pIniRow+i
	for i = 1:1:8 set tCol(i)=pIniCol+i

	if pType = 2
	{
		set $bit(rowLine2,tCol(4))=1
		set $bit(rowLine2,tCol(5))=1
		set $bit(rowLine3,tCol(3))=1
		set $bit(rowLine3,tCol(4))=1
		set $bit(rowLine4,tCol(4))=1
	
		// It positions bit lines from pRow
		set ^OPNLib.Game.CWLF(..World,0,tRow(2)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(2))|rowLine2)
		set ^OPNLib.Game.CWLF(..World,0,tRow(3)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(3))|rowLine3)
		set ^OPNLib.Game.CWLF(..World,0,tRow(4)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(4))|rowLine4)		
	}
	else 
	{
		set $bit(rowLine2,tCol(5))=1
		set $bit(rowLine3,tCol(3))=1
		set $bit(rowLine3,tCol(5))=1
		set $bit(rowLine4,tCol(4))=1
		set $bit(rowLine4,tCol(5))=1
	
		// It positions bit lines from pRow		
		set ^OPNLib.Game.CWLF(..World,0,tRow(2)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(2))|rowLine2)
		set ^OPNLib.Game.CWLF(..World,0,tRow(3)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(3))|rowLine3)
		set ^OPNLib.Game.CWLF(..World,0,tRow(4)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(4))|rowLine4)	
	}
}

/// Introduces a "Glider machine gun" form... after a while it generates a glider that leaves the group, meanwhile the machine gun starts again.
/// 01234567890123456789012345678901234567890
/// 1----------------------------------------
/// 2---------------------------x------------
/// 3------------------------xxxx----x-------
/// 4---------------x-------xxxx-----x-------
/// 5--------------x-x------x--x---------xx--
/// 6-------------x---xx----xxxx---------xx--
/// 7--xx---------x---xx-----xxxx------------
/// 8--xx---------x---xx--------x------------
/// 9--------------x-x-----------------------
/// 0---------------x------------------------
/// 1----------------------------------------
Method GliderMachineGun(pIniRow As %Integer = 3, pIniCol As %Integer = 3)
{
		for i = 1:1:11 set tRow(i)=pIniRow+i
		for i = 1:1:40 set tCol(i)=pIniCol+i
		
		set $bit(rowLine2,tCol(28))=1

		set $bit(rowLine3,tCol(25))=1
		set $bit(rowLine3,tCol(26))=1
		set $bit(rowLine3,tCol(27))=1
		set $bit(rowLine3,tCol(28))=1
		set $bit(rowLine3,tCol(33))=1

		set $bit(rowLine4,tCol(16))=1
		set $bit(rowLine4,tCol(24))=1
		set $bit(rowLine4,tCol(25))=1
		set $bit(rowLine4,tCol(26))=1
		set $bit(rowLine4,tCol(27))=1
		set $bit(rowLine4,tCol(33))=1

		set $bit(rowLine5,tCol(15))=1
		set $bit(rowLine5,tCol(17))=1
		set $bit(rowLine5,tCol(24))=1
		set $bit(rowLine5,tCol(27))=1
		set $bit(rowLine5,tCol(37))=1
		set $bit(rowLine5,tCol(38))=1
		
		set $bit(rowLine6,tCol(14))=1
		set $bit(rowLine6,tCol(18))=1
		set $bit(rowLine6,tCol(19))=1
		set $bit(rowLine6,tCol(24))=1
		set $bit(rowLine6,tCol(25))=1
		set $bit(rowLine6,tCol(26))=1
		set $bit(rowLine6,tCol(27))=1
		set $bit(rowLine6,tCol(37))=1
		set $bit(rowLine6,tCol(38))=1

		set $bit(rowLine7,tCol(3))=1
		set $bit(rowLine7,tCol(4))=1
		set $bit(rowLine7,tCol(14))=1
		set $bit(rowLine7,tCol(18))=1
		set $bit(rowLine7,tCol(19))=1
		set $bit(rowLine7,tCol(25))=1
		set $bit(rowLine7,tCol(26))=1
		set $bit(rowLine7,tCol(27))=1
		set $bit(rowLine7,tCol(28))=1

		set $bit(rowLine8,tCol(3))=1
		set $bit(rowLine8,tCol(4))=1
		set $bit(rowLine8,tCol(14))=1
		set $bit(rowLine8,tCol(18))=1
		set $bit(rowLine8,tCol(19))=1
		set $bit(rowLine8,tCol(28))=1

		set $bit(rowLine9,tCol(15))=1
		set $bit(rowLine9,tCol(17))=1

		set $bit(rowLine10,tCol(16))=1
		
		// It positions bit lines from row 3		
		set ^OPNLib.Game.CWLF(..World,0,tRow(2)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(2))|rowLine2)
		set ^OPNLib.Game.CWLF(..World,0,tRow(3)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(3))|rowLine3)
		set ^OPNLib.Game.CWLF(..World,0,tRow(4)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(4))|rowLine4)	
		set ^OPNLib.Game.CWLF(..World,0,tRow(5)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(5))|rowLine5)
		set ^OPNLib.Game.CWLF(..World,0,tRow(6)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(6))|rowLine6)
		set ^OPNLib.Game.CWLF(..World,0,tRow(7)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(7))|rowLine7)	
		set ^OPNLib.Game.CWLF(..World,0,tRow(8)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(8))|rowLine8)
		set ^OPNLib.Game.CWLF(..World,0,tRow(9)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(9))|rowLine9)
		set ^OPNLib.Game.CWLF(..World,0,tRow(10)) = $bitlogic(^OPNLib.Game.CWLF(..World,0,tRow(10))|rowLine10)
}

/// It takes the last board for the current world, resulted from last iteration for this world and iterates <i>pNumIterations</i> times
/// It quits if either there is no ID (World property) still defined or there hasn't been initialized 
Method Iterate(pNumIterations As %Integer = 1) As %Status
{
	if ((..World="") || ($data(^OPNLib.Game.CWLF(..World,0))'>0)) quit 0
	
	set tKeepAliveNum1 = +$piece($piece(..RulesOfLife,"/"),".")
	set tKeepAliveNum2 = +$piece($piece(..RulesOfLife,"/"),".",2)
	set tNewBornNum = +$piece(..RulesOfLife,"/",2)
	
	if tKeepAliveNum1 '>0 set tKeepAliveNum1=2
	if tKeepAliveNum2 '>0 set tKeepAliveNum2=3
	if tNewBornNum '>0 set tNewBornNum=3
	
	
	for iter=1:1:pNumIterations
	{
		merge gTemp = ^OPNLib.Game.CWLF(..World,..Iterations)
		
		for i=1:1:..Rows
		{
			if i > 1
			{
				set tPrevRow = gTemp(i-1)
				if i < ..Rows
				{
					set tNextRow = gTemp(i+1)
				}
				else
				{
					set $bit(tNextRow,1)=""
				}
			}
			else
			{
				set $bit(tPrevRow,1)=""
				set tNextRow = gTemp(i+1)
			}
	
			
			for j=1:1:..Columns
			{
				kill tMask
				set:(j>1) $bit(tMask,(j-1))=1
				set $bit(tMask,j)=1, $bit(tMask,(j+1))=1   //  .......111... being the 1 in the middle the position/column in which we are at this moment
				
				//if makes and AND operation in rows up-current-down with a mask that is a chain of 0s but in  (j-1) - j - (j-1) position
				//bitcount of 1's in resulting bitstrings minus the bit value will be the number of surrounding bits
				set tLiveAround = $bitcount($bitlogic(tPrevRow&tMask),1)+$bitcount($bitlogic(gTemp(i)&tMask),1)+$bitcount($bitlogic(tNextRow&tMask),1)-$bit(gTemp(i),j)
				
				//John Conway game live model
				//  1 dead surrounded by 3 or more, make a new "baby"
				//  1 alive with 2 or 3 live neighbors keeps alive
				//  1 alive with more than 3 live neighbors deads (super population)
				//  1 alive with 1 or none neighbors deads
				//  Otherwise, the cell remains equal
				
				if $bit(gTemp(i),j) // alive
				{
					set $bit(tRowNew,j)=$case(tLiveAround,tKeepAliveNum1:1,tKeepAliveNum2:1,:0)  //it dies unless there is tKeepAliveNum1 or tKeepAliveNum2 around
				}
				else // dead
				{
					set $bit(tRowNew,j)=$select(tLiveAround=tNewBornNum:1,1:0) // new born if there is exactly tNewBornNum alive around
				}			
			}
			
			set gNew(i) = tRowNew
		}
		
		merge ^OPNLib.Game.CWLF(..World,(..Iterations)+1) = gNew
		kill gNew
		
		set ..Iterations = ..Iterations + 1	
	}
	
	do ..%Save()
	
	quit $$$OK
}

/// It displays the board resulting of one particular iteration stored, from vector: pFromVector to pToVector
/// WARNING: This method assumes that vectors are previously verified
Method Display(pIteration As %Integer = 0, pFromVector As %String = "", pToVector As %String = "")
{
	
	if pIteration > ..Iterations set pIteration = ..Iterations
	
	if (..World="") || ($data(^OPNLib.Game.CWLF(..World,pIteration))'>0) quit 
	
	set tColIni = $p(pFromVector,",")
	set tColFin = $p(pToVector,",")
	set tRowIni = $p(pFromVector,",",2)
	set tRowFin = $p(pToVector,",",2)
	
	for i = tRowIni:1:tRowFin
	{	
		write !," "
		for j = tColIni:1:tColFin
		{
			write $case($bit(^OPNLib.Game.CWLF(..World,pIteration,i),j),"1":$c(164),:"-")
		}
	}
}

/// We're assuming a bidimensional board with positive coordinates in both x and y-axis
/// When is displayed in terminal window, the axis is considered to be in left-up corner so,
/// growing x and y ordinates would move the vector down right in our window
Method ValidateRange(ByRef pFromVector As %String = "", ByRef pToVector As %String = "") As %Status
{
	set:'(pFromVector?1.N1","1.N) pFromVector="1,1"
	set:'(pToVector?1.N1","1.N) pToVector=..Columns_","_..Rows
	
	set tColIni = $p(pFromVector,",")
	set tColFin = $p(pToVector,",")
	set tRowIni = $p(pFromVector,",",2)
	set tRowFin = $p(pToVector,",",2)

	if tColIni < 1 set tColIni = 1
	if tColFin > ..Columns set tColFin = ..Columns
	if tRowIni < 1 set tRowIni = 1
	if tRowFin > ..Rows set tRowFin = ..Rows
	
	if (tColIni>tColFin)||(tRowIni>tRowFin) 
	{
		set pFromVector="", pToVector = ""
		quit 0
	}
	else
	{
		set pFromVector = tColIni_","_tRowIni
		set pToVector = tColFin_","_tRowFin
	}	
	
	quit $$$OK
}

/// It displays in sequence, each pRefresh seconds, the iteration between pFrom and pTo, in the board area limited by pFromVector and pToVector
/// pFromVector/pToVector will have the format "<col>,<row>"
/// Examples: do g.DisplayRange(0,200,"10,10","1000,40")
Method DisplayRange(pFrom As %Integer = 0, pTo As %Integer = 0, pFromVector As %String = "", pToVector As %String = "", pRefresh As %Decimal = 0.5) As %Status
{
	quit:'(..ValidateRange(.pFromVector,.pToVector)) "0 - Vector range incorrect"
	
	for i=pFrom:1:pTo
	{
		w #
		do ..Display(i, pFromVector, pToVector)
		h pRefresh
	}
	quit $$$OK
}

/// pTest is a JSON object with params and config to run the test. It assumes that the workd (ID) has been created beforehand
///  {"ID":1,  //object ID
///   "From":0,"To":200, //Range of iterations to display
///   "Iterations":200,  //Number of times that we have to iterate from the current state on
///   "InitialConfig":5,  // Patterns to define before "big-bang"   (see Initialize())
///   "Rows":80,"Columns":150,  // Size of our universe in Rows and Columns
///   "Vector0":"1,1","VectorN":"120,47"  // Vector (Column,Row) that define the area to display in our terminal
ClassMethod Test(pTest As %DynamicObject = "") as %Status
{
	#dim e as %Exception.General
	#dim tSC as %Status = $$$OK
	
	try
	{
		if '($IsObject(pTest)&&(pTest.%ClassName()="%DynamicObject")) 
		{
			set pTest = {"ID":1,"From":0,"To":200,"Iterations":200,"InitialConfig":5,"Rows":80,"Columns":150,"Vector0":"1,1","VectorN":"100,40"}
		}
		
		write !,"These are the settings for the test:",!
		do pTest.%ToJSON()
		read !,"Press any key to continue... (Ctrl-C to stop)",x
		
		set g = ##class(OPNLib.Game.ConwayLifeGame).%OpenId(pTest.ID)
		
		$$$TOE(tSC,$IsObject(g))
		
		set g.Rows = pTest.Rows
		set g.Columns = pTest.Columns
		
		do g.Initialize(pTest.InitialConfig)
		do g.Iterate(pTest.Iterations)
				
		do g.DisplayRange(pTest.From,pTest.To,pTest.Vector0,pTest.VectorN)
	}
	catch e
	{
		return e.AsStatus()
	}
	return tSC
}

Storage Default
{
<Data name="ConwayLifeGameDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>World</Value>
</Value>
<Value name="3">
<Value>Rows</Value>
</Value>
<Value name="4">
<Value>Columns</Value>
</Value>
<Value name="5">
<Value>Iterations</Value>
</Value>
<Value name="6">
<Value>RulesOfLife</Value>
</Value>
</Data>
<DataLocation>^OPNLib.Game.ConwayLifeGameD</DataLocation>
<DefaultData>ConwayLifeGameDefaultData</DefaultData>
<IdLocation>^OPNLib.Game.ConwayLifeGameD</IdLocation>
<IndexLocation>^OPNLib.Game.ConwayLifeGameI</IndexLocation>
<StreamLocation>^OPNLib.Game.ConwayLifeGameS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
