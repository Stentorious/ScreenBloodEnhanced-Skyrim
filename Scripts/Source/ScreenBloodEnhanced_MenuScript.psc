Scriptname ScreenBloodEnhanced_MenuScript extends MCM_ConfigBase


; #### VARIABLES ####
float modVersion = 0.0
int animStage = 0

; #### PROPERTIES ####

; Base
Actor Property PlayerRef Auto
ImageSpaceModifier Property GetHit Auto
ReferenceAlias Property PlayerAlias Auto

; mod
GlobalVariable Property ScreenBloodEnhancedGlobal_AnimTrigger Auto

; Config
GlobalVariable Property ScreenBloodEnhancedGlobal_SplatterCount Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_SplatterDuration Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_Distance Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_Heading Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_Unarmed Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_Blunt Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_Blade Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_Projectile Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_PowerAttack Auto
GlobalVariable Property ScreenBloodEnhancedGlobal_LimbDismembered Auto
;GlobalVariable Property ScreenBloodEnhancedGlobal_AnimDefault Auto
;GlobalVariable Property ScreenBloodEnhancedGlobal_AnimCombat Auto

; Internal
; mod version
float property fModVersion = 1.00 autoReadOnly
; anim parameters
float Property fAnimLength_Default = 2.2 autoReadOnly
float Property fAnimLength_Fast = 0.9 autoReadOnly
float Property fAnimTime_ClearScreen = 0.6 autoReadOnly
float Property fAnimTime_End = 0.5 autoReadOnly

; states
String Property sState_Default = "" AutoReadOnly
String Property sState_PlayingAnimation = "PlayingAnimation" AutoReadOnly

Event OnConfigInit()
	Utility.Wait(5)
EndEvent


Event OnGameReload()
	parent.OnGameReload()
	Utility.Wait(0.25)

	; Requirements check
	if !MCM.IsInstalled()
		Debug.MessageBox("Screen Blood Enhanced missing requirement!\nMCM Helper is not installed or not correctly loaded.")
		return
	elseif SKSE.GetPluginVersion("powerofthree's Papyrus Extender") == -1
		Debug.MessageBox("Screen Blood Enhanced missing requirement!\npowerofthree's Papyrus Extender is not installed or not correctly loaded.")
		return
	elseif SKSE.GetPluginVersion("ConsoleUtilSSE") == -1
		Debug.MessageBox("Screen Blood Enhanced missing requirement!\nConsoleUtilSSE is not installed or not correctly loaded.")
		return
	elseif SKSE.GetPluginVersion("Skypatcher") == -1
		Debug.MessageBox("Screen Blood Enhanced missing requirement!\nSkyPatcher is not installed or not correctly loaded.")
		return
	elseif PlayerRef.GetAnimationVariableBool("bGPMAInstalled") == false
		Debug.MessageBox("Screen Blood Enhanced missing requirement!\nOffset Movement Animations are installed or not correctly loaded.")
		return
	endIf

	OnGameLoad()

EndEvent


; Updates MCM settings on menu close
Event OnConfigClose()
	LoadSettings()
EndEvent

; #### FUNCTIONS ####

Function OnGameLoad()

	; Release Version
	if modVersion < 1.00
		Debug.Trace("Screen Blood Enhanced: Init")
	endif
	modVersion = fModVersion

	; Reset input layer if active
	Game.EnablePlayerControls()
	UnregisterForUpdate()
	animStage = 0

	LoadSettings()

EndFunction


; Load default/saved MCM settings
Function LoadSettings()

	; Update globals
	;ScreenBloodEnhancedGlobal_AnimDefault.SetValue(GetModSettingInt("iVariantDefault:Animation"))
	;ScreenBloodEnhancedGlobal_AnimCombat.SetValue(GetModSettingInt("iVariantCombat:Animation"))
	ScreenBloodEnhancedGlobal_Distance.SetValue(GetModSettingFloat("fDistance:Visibility"))
	ScreenBloodEnhancedGlobal_Heading.SetValue(GetModSettingFloat("fHeadingAngle:Visibility"))
	ScreenBloodEnhancedGlobal_SplatterCount.SetValueInt(GetModSettingInt("iCount:BloodSplatter"))
	ScreenBloodEnhancedGlobal_Unarmed.SetValue(GetModSettingFloat("fUnarmed:BloodSplatter"))
	ScreenBloodEnhancedGlobal_Blunt.SetValue(GetModSettingFloat("fBlunt:BloodSplatter"))
	ScreenBloodEnhancedGlobal_Blade.SetValue(GetModSettingFloat("fBlade:BloodSplatter"))
	ScreenBloodEnhancedGlobal_Projectile.SetValue(GetModSettingFloat("fProjectile:BloodSplatter"))
	ScreenBloodEnhancedGlobal_PowerAttack.SetValue(GetModSettingFloat("fPowerAttack:BloodSplatter"))
	ScreenBloodEnhancedGlobal_LimbDismembered.SetValue(GetModSettingFloat("fLimbDismembered:BloodSplatter"))

	; Update GameSettings
	Game.SetGameSettingInt("iBloodSplatterMaxCount", 200)
	Game.SetGameSettingFloat("fBloodSplatterOpacityChance", 0.3)

	; Splatter duration
	Game.SetGameSettingFloat("fBloodSplatterDuration", GetModSettingFloat("fDuration:BloodSplatter"))

	; Splatter alpha
	Game.SetGameSettingFloat("fBloodSplatterMinSize", GetModSettingFloat("fSizeMin:BloodSplatter") * 0.15)
	Game.SetGameSettingFloat("fBloodSplatterMaxSize", GetModSettingFloat("fSizeMax:BloodSplatter") * 0.15)
	Game.SetGameSettingFloat("fBloodSplatterFlareSize", GetModSettingFloat("fFlareSize:BloodSplatter") * 0.065)

	; Splatter size
	float fMin = GetModSettingFloat("fAlphaMin:BloodSplatter")
	float fMax = GetModSettingFloat("fAlphaMax:BloodSplatter")
	Game.SetGameSettingFloat("fBloodSplatterMinOpacity", fMin)
	Game.SetGameSettingFloat("fBloodSplatterMaxOpacity", fMax)
	Game.SetGameSettingFloat("fBloodSplatterMinOpacity2", fMin * 0.6)
	Game.SetGameSettingFloat("fBloodSplatterMaxOpacity2", fMax * 0.6)
	Game.SetGameSettingFloat("fBloodSplatterFlareMult", GetModSettingFloat("fFlareAlpha:BloodSplatter"))

	; Disable vanilla splatters on damage taken
	if GetModSettingInt("iEffectReceive:General") == 0
		Game.SetGameSettingFloat("fBloodSplatterCountBase", 0)
		Game.SetGameSettingFloat("fBloodSplatterCountDamageMult", 0)
	else
		Game.SetGameSettingFloat("fBloodSplatterCountBase", 2)
		Game.SetGameSettingFloat("fBloodSplatterCountDamageMult", 0.1)
	endif

	; Update event handlers
	RegisterEvents(abRegister = true)

EndFunction


; Update event handlers
Function RegisterEvents(bool abRegister = true)
	if (abRegister)
		UnregisterForAllKeys()
		RegisterForKey(GetModSettingInt("iKeybind:Controls"))
		if GetModSettingInt("iEffectDeal:General") == 1
			PO3_Events_Alias.RegisterForWeaponHit(PlayerAlias)
		else
			PO3_Events_Alias.UnregisterForWeaponHit(PlayerAlias)
		endif
	else
		UnregisterForAllKeys()
		PO3_Events_Alias.UnregisterForWeaponHit(PlayerAlias)
	endif
EndFunction


Function PlayAnimation(int animIndex, float animLength)

	; Anim start
	animStage = 1
	GoToState(sState_PlayingAnimation)

	ScreenBloodEnhancedGlobal_AnimTrigger.SetValue(animIndex)
	int iOffsetType = 0
	if GetModSettingBool("bLeftArmOnly:Animation")
		iOffsetType = 2
	endif
	PlayerRef.SetAnimationVariableInt("iGPMAOffsetType", iOffsetType)
	Debug.SendAnimationEvent(PlayerRef, "OffsetGPMA")

	Game.DisablePlayerControls(abMovement = false, abFighting = false, abCamSwitch = true, abLooking = false, \
		abSneaking = false, abMenu = false, abActivate = false, abJournalTabs = false, aiDisablePOVType = 0)

	; Clear screen
	Utility.Wait(fAnimTime_ClearScreen)
	ConsoleUtil.ExecuteCommand("ClearScreenBlood")
	GetHit.Apply()

	; Anim finish
	Utility.Wait(animLength - fAnimTime_ClearScreen)
	Debug.SendAnimationEvent(PlayerRef, "OffsetGPMAStop")

	; Anim cooldown
	Utility.Wait(fAnimTime_End)
	ScreenBloodEnhancedGlobal_AnimTrigger.SetValue(0)
	Game.EnablePlayerControls()
	animStage = 0
	GoToState(sState_Default)

EndFunction

Event OnKeyDown(int keyCode)

	if animStage > 0 || Game.GetCameraState() != 0 || Utility.IsInMenuMode() || UI.IsMenuOpen("Dialogue Menu") || PlayerRef.IsDead() || PlayerRef.IsInKillMove() || PlayerRef.IsSwimming() || !Game.IsFightingControlsEnabled()
		return
	endif

	int iAnim = 0
	if PlayerRef.GetCombatState() == 0
		iAnim = GetModSettingInt("iVariantDefault:Animation")
	else
		iAnim = GetModSettingInt("iVariantCombat:Animation")
	endif
	if iAnim == 1
		PlayAnimation(10, fAnimLength_Fast)
	else
		PlayAnimation(20, fAnimLength_Default)
	endif

EndEvent

State PlayingAnimation

	Event OnKeyDown(int keyCode)
	EndEvent

EndState