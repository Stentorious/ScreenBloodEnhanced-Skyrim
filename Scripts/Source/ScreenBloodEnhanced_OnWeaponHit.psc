Scriptname ScreenBloodEnhanced_OnWeaponHit extends ReferenceAlias

; #### PROPERTIES ####

; globalvariables
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
; internal
; hit flags
int Property iHitFlag_Block = 1 AutoReadOnly
int Property iHitFlag_BlockWeapon = 2 AutoReadOnly
int Property iHitFlag_Bash = 16384 AutoReadOnly
int Property iHitFlag_TimedBash = 32768 AutoReadOnly
int Property iHitFlag_PowerAttack = 65536 AutoReadOnly
; states
String Property sState_Default = "" AutoReadOnly
String Property sState_ProcessingHit = "ProcessingHit" AutoReadOnly

Event OnWeaponHit(ObjectReference akTarget, Form akSource, Projectile akProjectile, Int aiHitFlagMask)

	GoToState(sState_ProcessingHit)

	; Validate weapon
	Weapon aWeapon = akSource as Weapon
	if !aWeapon
		return
	endif
	int iWeaponType = aWeapon.GetWeaponType()

	; Validate actors
	if(!akTarget || akTarget.IsDisabled() || akTarget.IsDeleted() || !akTarget.Is3DLoaded())
		return
	endif
	Actor aTarget = akTarget.GetSelfAsActor()
	if !aTarget
		return
	elseif !aTarget.GetRace().HasKeywordString("SBE_ApplyScreenBlood")
		return
	endif
	Actor aPlayer = Game.GetPlayer()

	int iHitFlags = aiHitFlagMask

	; Ignore blocked hits
	if Math.LogicalAnd(iHitFlags, iHitFlag_Block) != 0 || Math.LogicalAnd(iHitFlags, iHitFlag_BlockWeapon) != 0
		return
	endif

	float fSplatter = ScreenBloodEnhancedGlobal_SplatterCount.GetValue()

	; Damage calculation
	;float fDamageResistance = aTarget.GetAV("DamageResist")
	;float fDamage = aWeapon.GetBaseDamage()
	;Debug.Trace("SBH fDamageResistance: " + fDamageResistance)
	;Debug.Trace("SBH fDamage: " + fDamage)

	; Hit data calculation
	; 0 = Fists
	; 1 = Swords
	; 2 = Daggers
	; 3 = War Axes
	; 4 = Maces
	; 5 = Greatswords
	; 6 = Battleaxes AND Warhammers
	; 7 = Bows
	; 8 = Staff
	; 9 = Crossbows
	; Unarmed
	if iWeaponType == 0
			fSplatter *= ScreenBloodEnhancedGlobal_Unarmed.GetValue()
	; Bash / Blunt
	elseif iWeaponType == 4 || aWeapon.IsWarhammer() || Math.LogicalAnd(iHitFlags, iHitFlag_Bash) != 0 || Math.LogicalAnd(iHitFlags, iHitFlag_TimedBash) != 0
		fSplatter *= ScreenBloodEnhancedGlobal_Blunt.GetValue()
	; Projectile
	elseif iWeaponType > 6
		fSplatter *= ScreenBloodEnhancedGlobal_Projectile.GetValue()
	; Blade
	else
		fSplatter *= ScreenBloodEnhancedGlobal_Blade.GetValue()
	endif
	; Power attack
	if Math.LogicalAnd(iHitFlags, iHitFlag_PowerAttack) != 0
		fSplatter *= ScreenBloodEnhancedGlobal_PowerAttack.GetValue()
	endif

	; Position calculation
	float fDistance = 1
	float fHeading = 1
	if aTarget != aPlayer
		float fDistanceMax = ScreenBloodEnhancedGlobal_Distance.GetValue() * 69.99104
		float fHeadingMax = ScreenBloodEnhancedGlobal_Heading.GetValue()
		fDistance = (GetMax(0, (fDistanceMax - (aPlayer.GetDistance(aTarget))))) / fDistanceMax
		fHeading = (GetMax(0, (fHeadingMax - (Math.abs(aPlayer.GetHeadingAngle(aTarget)))))) / fHeadingMax
	endif

	; Trigger splatter
	if fDistance > 0 && fHeading > 0
		fSplatter *= ApplyEasing(fDistance, 2, 0)
		fSplatter *= ApplyEasing(fHeading, 2, 1)
		int iSplatter = Math.Floor(fSplatter + 0.5) as int
		if iSplatter > 0
			Game.TriggerScreenBlood(iSplatter)
		endif
	endif

EndEvent

float Function GetMax(float a, float b)
	if a > b
		return a
	else
		return b
	endif
EndFunction

float Function ApplyEasing(float fInput, int easingFunc, int easingMode)

	; easingFunc
	; Sine = 0
	; Quad = 1
	; Cubic = 2
	; Quart = 3
	; Quint = 4
	; Circ = 5
	; Expo = 6
	; Back = 7
	; Elastic = 8
	; Bounce = 9

	; easingMode
	; 0 = EaseIn
	; 1 = EaseOut
	; 2 = EaseInOut

	if easingMode == 0
		if easingFunc == 2
			return fInput * fInput * fInput
		endif
	elseif easingMode == 1
		if easingFunc == 2
			return 1 - Math.pow(1 - fInput, 3)
		endif
	endif

EndFunction

; #### STATES ####

State ProcessingHit

	Event OnBeginState()
		RegisterForSingleUpdate(1)
	EndEvent

	Event OnUpdate()
	    GoToState(sState_Default)
	EndEvent

	Event OnWeaponHit(ObjectReference akTarget, Form akSource, Projectile akProjectile, Int aiHitFlagMask)
	EndEvent

EndState