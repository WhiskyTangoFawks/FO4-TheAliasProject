Scriptname GenerateNPCAlias extends Quest

RefCollectionAlias[] Property aliasManagers Auto Const

Struct NamesDatum
	FormList namesList ; used to fill cache
	FormList namesCache ; used to pull random names from
	Message name ; static override name, if set will always use
	Message prefix ; static override name, if set will always use
	Message suffix ; static override name, if set will always use
	int percentNone ; chance to skip entirely
	float selectBylevelMax ; if set, will assign the namesList statically by level, instead of randomly from the cache
endStruct

Keyword Property FeaturedItem const auto
Keyword Property EncTypeLegendary const auto
FormList[] Property itemSuffixes const auto ; a formlist where position 0 is the keyword to match, and subsequent positions are messages to use

Function generateAlias(Actor akTarget, NamesDatum[] NamesLists)
	debug.trace(self + "OnEffectStart() Building NPC Alias")
	ObjectReference LegendaryItem = none
	
	;(quest has an override form that supplies the possible weapon suffixes, if it's filled then this function is called)
	if itemSuffixes && akTarget.hasKeyword(EncTypeLegendary)
		debug.trace(self + " EncTypeLegendary found, looking for legendary item")
				
		int i = 0
		while i < 3 && LegendaryItem == none
			Utility.wait(3)
			LegendaryItem = getLegendaryItem(akTarget)
			i += 1
		endWhile
		if LegendaryItem == none
			debug.trace(self + "No legendary item found after 3 attempts")
		endIf
	endIf
	
	int i = 0
	int nextTokenNumber = 0
	
	while i < namesLists.length
		debug.trace(self + " Name-"+i+ ": Picking name")
		if (namesLists[i].percentNone && Utility.randomInt(0, 99) < namesLists[i].percentNone)
			debug.trace(self + " Name-"+i+ ": Skipping because percent none")
		else
			if namesLists[i].prefix ; Adds a static prefix as a linker
				addAliasData("prefix", i, akTarget, LegendaryItem, nextTokenNumber, namesLists[i].prefix)
				nextTokenNumber += 1
			endIf
			
			if namesLists[i].name ; Static name, requires that name be set
				addAliasData("single static", i,  akTarget, LegendaryItem, nextTokenNumber, namesLists[i].name)
				nextTokenNumber += 1
					
			elseif (namesLists[i].selectBylevelMax)	; Assigns the name as a rank based on NPC level, does not use cache
				int rank = Math.floor(akTarget.getLevel() / namesLists[i].selectBylevelMax * namesLists[i].namesList.getSize())
				if rank >= namesLists[i].namesList.getSize()
					rank = namesLists[i].namesList.getSize()
				endIf
				addAliasData("levelled rank ", i, akTarget, LegendaryItem, nextTokenNumber, namesLists[i].namesList.getAt(rank))
				nextTokenNumber += 1
							
			elseif namesLists[i].namesCache == none ; If there is no cache, just pick randomly from the list
				if (Utility.randomInt(0, 99) > namesLists[i].percentNone)
					int random = Utility.randomInt(0, namesLists[i].namesList.getSize()-1)
					addAliasData("cachless ", i, akTarget, LegendaryItem, nextTokenNumber, namesLists[i].namesList.getAt(random))
					nextTokenNumber += 1
				endIf
			
			else ; Standard cached procedure
				;Fill the cache if its empty
				if namesLists[i].namesCache.getSize() < 1
					debug.trace(self + " Name-"+i+ ": Empty cache found, refreshing cache ")
					fillCache(namesLists[i].namesList, namesLists[i].namesCache)
				endIf
				int random = Utility.randomInt(0, namesLists[i].namesCache.getSize()-1)
				addAliasData("cached ", i, akTarget, LegendaryItem, nextTokenNumber, namesLists[i].namesList.getAt(random))
				nextTokenNumber += 1
				namesLists[i].namesCache.removeAddedForm(namesLists[i].namesCache.getAt(random))
			endIf
			
			if namesLists[i].suffix ; adds a static suffix as a linker
				addAliasData("suffix", i, akTarget, LegendaryItem, nextTokenNumber, namesLists[i].suffix)
				nextTokenNumber += 1
			endIf
		endIf
		i += 1
	endWhile
	
	int numTokens = nextTokenNumber - 1 ; past this we want the last token used
	
	aliasManagers[numTokens].addRef(akTarget)
	aliasManagers[numTokens].removeRef(akTarget)
	
	if LegendaryItem
		debug.trace(self + " Adding featured item suffix")
		int j = 0
		while j < itemSuffixes.length
			int firstMessage = getFirstMessageIfHasReqKeywords(akTarget, LegendaryItem, itemSuffixes[j])
			if firstMessage > -1
				debug.trace(self + " Found sufix to use")
				int random = Utility.randomInt(firstMessage, itemSuffixes[j].getSize()-1)
				LegendaryItem.AddTextReplacementData("name"+nextTokenNumber, itemSuffixes[j].getAt(random))
				nextTokenNumber += 1
				aliasManagers[numTokens].addRef(LegendaryItem)
				aliasManagers[numTokens].removeRef(LegendaryItem)
				j = itemSuffixes.length ; exit early
			endIf
			j += 1
		endWhile
	endIf

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

Function addAliasData(String logType, int i, Actor akTarget, ObjectReference item, int nextTokenNumber, Form msg)
	akTarget.AddTextReplacementData("name"+nextTokenNumber, msg)
	debug.trace(self + "NPC Alias Name-"+i+ ": Assigned "+ logType +" nameOverride="+ msg)
	if item
		item.AddTextReplacementData("name"+nextTokenNumber, msg)
		debug.trace(self + "Item Alias Name-"+i+ ": Assigned "+ logType +" nameOverride="+ msg)
	endIf
endFunction

ObjectReference Function getLegendaryItem(actor akTarget)

	debug.trace(self + " Searching for featured item on legendary NPC")
	Form[] inventory = akTarget.GetInventoryItems()	
	if inventory.length == 0
		return none
	endIf

	int i = 0
	while (i < inventory.length)
		Weapon weap = inventory[i] as Weapon
		Armor armo = inventory[i] as Armor
		If (weap || armo) && akTarget.GetItemCount(inventory[i]) == 1
			bool isEquipped = akTarget.IsEquipped(inventory[i])
			ObjectReference itemRef = akTarget.dropObject(inventory[i]);drop the object to get it's objRef
			akTarget.addItem(itemRef); put it back on the NPC
			if isEquipped
				akTarget.equipItem(itemRef) ; and Equip it
			endIf
			if itemRef.hasKeyword(FeaturedItem); has to run on the objRef, not on the base form, because featuredKeyword is added by omods
				debug.trace(self + "Found featured item: " + itemRef)
				return itemRef
			endIf
		endIf
		i += 1
	endWhile
	debug.trace(self + " Unable to find featured item")
	return none
endFunction

int Function getFirstMessageIfHasReqKeywords(Actor akTarget, ObjectReference item, FormList itemSufix)
	int i = 0
	while i < itemSufix.getSize() && (itemSufix.getAt(i) as Keyword)
		Keyword keywordToCheck = itemSufix.getAt(i) as Keyword
		if !akTarget.hasKeyword(keywordToCheck) || !item.hasKeyword(keywordToCheck)
			return -1
		endIF
		i += 1
	endWhile
	return i
endFunction