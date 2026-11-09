Scriptname GenerateNPCAlias extends Quest

RefCollectionAlias[] Property aliasManagers Auto Const
ActorValue Property HasAlias Auto Const

Struct NamesDatum
	FormList namesList ; used to fill cache
	FormList namesCache ; used to pull random names from
	Message name ; static override name, if set will always use
	Message prefix ; static override name, if set will always use
	Message suffix ; static override name, if set will always use
	int percentNone ; chance to skip entirely
	float selectBylevelMax ; if set, will assign the namesList statically by level, instead of randomly from the cache
endStruct

Bool Function generateAlias(Actor akTarget, NamesDatum[] NamesLists)

	if akTarget.getValue(HasAlias) > 0
		debug.trace(self + " Skipping already aliased NPC")
		return none
	endIf

	akTarget.setValue(HasAlias, 1)
	debug.trace(self + "OnEffectStart() Building NPC Alias: " + akTarget.getActorBase().getName())
	
	int i = 0
	int nextTokenNumber = 0
	
	while i < namesLists.length
		debug.trace(self + " Name-"+i+ ": Picking name")
		if (namesLists[i].percentNone && Utility.randomInt(0, 99) < namesLists[i].percentNone)
			debug.trace(self + " Name-"+i+ ": Skipping because percent none")
		else
			if namesLists[i].prefix ; Adds a static prefix as a linker
				addAliasData("prefix", i, akTarget, nextTokenNumber, namesLists[i].prefix)
				nextTokenNumber += 1
			endIf
			
			if namesLists[i].name ; Static name, requires that name be set
				addAliasData("single static", i,  akTarget, nextTokenNumber, namesLists[i].name)
				nextTokenNumber += 1
					
			elseif (namesLists[i].selectBylevelMax)	; Assigns the name as a rank based on NPC level, does not use cache
				int rank = Math.floor(akTarget.getLevel() / namesLists[i].selectBylevelMax * namesLists[i].namesList.getSize())
				if rank >= namesLists[i].namesList.getSize()
					rank = namesLists[i].namesList.getSize()
				endIf
				addAliasData("levelled rank ", i, akTarget, nextTokenNumber, namesLists[i].namesList.getAt(rank))
				nextTokenNumber += 1
							
			elseif namesLists[i].namesCache == none ; If there is no cache, just pick randomly from the list
				if (Utility.randomInt(0, 99) > namesLists[i].percentNone)
					int random = Utility.randomInt(0, namesLists[i].namesList.getSize()-1)
					addAliasData("cachless ", i, akTarget, nextTokenNumber, namesLists[i].namesList.getAt(random))
					nextTokenNumber += 1
				endIf
			
			else ; Standard cached procedure
				;Fill the cache if its empty
				if namesLists[i].namesCache.getSize() < 1
					debug.trace(self + " Name-"+i+ ": Empty cache found, refreshing cache ")
					fillCache(namesLists[i].namesList, namesLists[i].namesCache)
				endIf
				int random = Utility.randomInt(0, namesLists[i].namesCache.getSize()-1)
				addAliasData("cached ", i, akTarget, nextTokenNumber, namesLists[i].namesCache.getAt(random))
				nextTokenNumber += 1
				namesLists[i].namesCache.removeAddedForm(namesLists[i].namesCache.getAt(random))
			endIf
			
			if namesLists[i].suffix ; adds a static suffix as a linker
				addAliasData("suffix", i, akTarget, nextTokenNumber, namesLists[i].suffix)
				nextTokenNumber += 1
			endIf
		endIf
		i += 1
	endWhile
	
	int numTokens = nextTokenNumber - 1 ; past this we want the last token used
	
	aliasManagers[numTokens].addRef(akTarget)
	aliasManagers[numTokens].removeRef(akTarget)
	
EndFunction

Function FillCache(FormList namesList, FormList cache)
	int i = 0
	while i < namesList.getSize()
		if (namesList.getAt(i) as FormList) ; if it's another formlist, call recursively
			FillCache(namesList.getAt(i) as FormList, cache)
		elseif (namesList.getAt(i) as Message)
			cache.addForm(namesList.getAt(i))
		endIf
		i += 1
	endWhile
endFunction

Function addAliasData(String logType, int i, Actor akTarget, int nextTokenNumber, Form msg)
	akTarget.AddTextReplacementData("name"+nextTokenNumber, msg)
	debug.trace(self + "NPC Alias Name-"+i+ ": Assigned "+ logType +" nameOverride="+ msg)
endFunction