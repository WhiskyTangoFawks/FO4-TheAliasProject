Scriptname RenameNpcEffect extends activemagiceffect

GenerateNPCAlias Property aliasScript Auto Const
GenerateNPCAlias:NamesDatum[] Property NamesLists Auto Const

Event OnEffectStart(Actor akTarget, Actor akCaster)
	aliasScript.generateAlias(akTarget, NamesLists)
EndEvent

