Scriptname ScreenBloodEnhanced_EffectCombat extends ActiveMagicEffect

; #### PROPERTIES ####
; script
ScreenBloodEnhanced_MenuScript Property QuestScript Auto

; globalvariables
GlobalVariable Property ScreenBloodEnhancedGlobal_AutoWipe Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_AutoWipeDelay Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	debug.trace("Combat End")
	if ScreenBloodEnhancedGlobal_AutoWipe.GetValueInt() == 1 && QuestScript.bCombatState == true
		RegisterForSingleUpdate(ScreenBloodEnhancedGlobal_AutoWipeDelay.GetValue())
	endif
	QuestScript.bCombatState = false
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	debug.trace("Combat Start")
	QuestScript.bCombatState = true
EndEvent


Event OnUpdate()
    QuestScript.InitAnimation()
EndEvent
