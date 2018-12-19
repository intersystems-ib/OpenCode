# OpenCode
## John Conway's Game of Life

With this class you could simulate Game of Life world that John Conway invented in 1970. We can see how John Conway universe evolves in our terminal just executing:

```javascript
     do ##class(OPNLib.Game.ConwayLifeGame).Test()
```

We can alter the initial conditions (and then, future evolution) of our universe, just adding a JSON object as a parameter of `Test` method. The JSON object to stablish the settings by default is:

```javascript
    {
       "ID":1,
       "From":0,
       "To":200,
       "Iterations":200,
       "InitialConfig":5,
       "Rows":80,
       "Columns":150,
       "Vector0":"1,1",
       "VectorN":"100,40"
    }
```


### Technical bites

Just take into account that the JC world is bidimensional and that we implement that world like a matrix using `GLOBALS` (disperse arrays of IS IRIS). Each row is a node of level 1 that contains a string of bits where each bit represents the value of the cell (alive=1, dead=0) in a column in that row.

You can define different universes or worlds, and keep several iterations stored. The class uses standard storage for a persistent class, where we would have the general settings for the world and the number of iterations already executed for that particular world.
Besides, the `Iterate()` method stores the results of each iteration for each world in a different global: `OPNLib.Game.CWLF`

The rules that JC defined for the evolution where very simple (in fact he wanted to show how from very basic fundamental rules explained with a basic model, the "universe" could evolve to more complex "things" that could derive in higher level models to explain that "new" reality)... well, the rules are:
- A block is `alive`(A) or `dead`(D)
- Each block is surrounded by 8 blocks
- An alive block surrounded by exactly 2 or 3 blocks survive
- An alive block dies if it's surrounded by 0 or just 1 alive block 
- A dead block surrounded by exactly 3 blocks becomes alive (new born)
- An alive block surrounded by more than 3 alive blocks dies (over population)

This rules are applied by default, as stated in property `RulesOfLife` property (2.3/3), where the piece before "/" represents the exact number of alive blocks to survive and the piece after "/" represents the number of alive blocks that have to surround a dead block to get a new born.

### Different patterns

There are many different patterns discovered in random iterations in John Conway worlds... some of them are already implemented as methods in the clase, like `Oscillators`, `Gliders`, `Still patterns`,... but you can take those as examples and add more methods that implement new patterns of your choice.

`Initialize(<Pattern>)` initialize the current world that represents the object we have in memory. We can choose to insert different patterns or mix of them in the new blank board,... Currently there are some patterns implemented:

Pattern Code | Description
-------------|-----------------------
1| Oscillator   (bar or toad)
2| Still life (square or beehive)
3| Glider (default or R-pentomino)
4| Glider's Machine gun
5| Random mix of above patterns
6| Pure random universe (no predefined patterns)

---

_**Example:**_ 

From the terminal, in the namespace where you loaded and compiled the class :

```javascript
     Set obj = ##class(OPNLib.Game.ConwayLifeGame).%New()
     do obj.Initialize(4)  //we'll create an empty board with a Glider's machine gun patter in it as the initial seed
     do obj.Iterate(150)
     do obj.DisplayRange(0,100,0.5) // shows iterations from 0 to 100, one each 0.5 seconds
```
you'll see the initial pattern that evolves, generating a Glider after a while, and then another, and another,... 

```javascript
     Set obj2 = = ##class(OPNLib.Game.ConwayLifeGame).%New()
     // set a different size of our "universe"
     Set obj2.Rows = 30
     Set obj2.Columns = 30 
     
     Do obj2.Initialize()  // we'll create an empty board with an initial seed (set of death and alive blocks) pure random
     Do obj2.Iterate(200)
     Do obj2.DisplayRange(10,130,0.2)
 ```
you'll see an initial random universe that evolves... creating new evolving life forms... ehem... patterns :-)... or dissapearing... or getting still with no evolution.

---

Have fun!

