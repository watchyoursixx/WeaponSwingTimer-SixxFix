local addon_name, addon_data = ...

local L = setmetatable({}, {
    __index = function(table, key)
        if key then
            table[key] = tostring(key)
        end
        return tostring(key)
    end,
})

addon_data.localization_table = L

GetLocale() == "enUS" then
	--Core
	L["Thank you for installing WeaponSwingTimer Version"]	=	TRUE
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."]	= TRUE
	L["Unexpected Unit Type in MissHandler()."]	=	TRUE
	L["Unexpected Unit Type in SpellHandler()."]	=	TRUE

	--Config
	L["Global Bar Settings"]	=	TRUE
	L["Melee Settings"]	=	TRUE
	L["Hunter & Wand Settings"]	=	TRUE
	L["Lock All Bars"]	=	TRUE
	L[" Welcome Message"]	=	TRUE
	L["Locks all of the swing bar frames, preventing them from being dragged."]	=	TRUE
	L["Displays the welcome message upon login/reload. Uncheck to disable."]	=	TRUE
	L["Click the + on the left for more options"]	=	TRUE

	--Player
	L["Player Swing Bar Settings"]	=	TRUE
	L["Enables the player's swing bars."]	=	TRUE
	L["Enables the player's off-hand swing bar."]	=	TRUE
	L["Enables the player bar's border."]	=	TRUE
	L["Enables the classic texture for the player's bars."]	=	TRUE
	L["Enables the player's left side text."]	=	TRUE
	L["Enables the player's right side text."]	=	TRUE

	--Target
	L["Target Swing Bar Settings"]	=	TRUE
	L["Enables the target's swing bars."]	=	TRUE
	L["Enables the target's off-hand swing bar."]	=	TRUE
	L["Enables the target bar's border."]	=	TRUE
	L["Enables the classic texture for the target's bars."]	=	TRUE
	L["Enables the target's left side text."]	=	TRUE
	L["Enables the target's right side text."]	=	TRUE

	--Shot
	L["Failed"] 	=	TRUE
	L["Interrupted"] 	=	TRUE
	L["Hunter & Wand Shot Bar Settings"]	=	TRUE
	L["General Settings"]	=	TRUE
	L["YaHT / One bar"]	=	TRUE
	L["Changes the Auto Shot bar to a single bar that fills from left to right"]	=	TRUE
	L["Show Text"]	=	TRUE
	L["Enables the shot bar text."]	=	TRUE
	L["Auto Shot Cooldown Color"]	=	TRUE
	L["Auto Shot Cast Color"]	=	TRUE
	L["Hunter Specific Settings"]	=	TRUE
	L["Aimed Shot cast bar"]	=	TRUE
	L["Allows the cast bar to show Aimed Shot casts."]	=	TRUE
	L["Multi-Shot cast bar"]	=	TRUE
	L["Allows the cast bar to show Multi-Shot casts."]	=	TRUE
	L["Latency bar"]	=	TRUE
	L["Shows a bar that represents latency on cast bar."]	=	TRUE
	L["Multi-Shot clip bar"]	=	TRUE
	L["Shows a bar that represents when a Multi-Shot would clip an Auto Shot."]	=	TRUE
	L["Auto Shot delay timer"] 	=	TRUE
	L["Shows a timer that represents when Auto shot is delayed."] 	=	TRUE
	L["Multi-Shot Clip Color"]	=	TRUE

	--Common
	L["Main-Hand"]	=	TRUE
	L["Off-Hand"]	=	TRUE
	L["Enable"]	=	TRUE
	L["Show Off-Hand"]	=	TRUE
	L["Show border"]	=	TRUE
	L["Classic bars"]	=	TRUE
	L["Fill / Empty"]	=	TRUE
	L["Determines if the bar is full or empty when a swing is ready."]	=	TRUE
	L["Show Left Text"]	=	TRUE
	L["Show Right Text"]	=	TRUE
	L["Bar Width"]	=	TRUE
	L["Bar Height"]	=	TRUE
	L["X Offset"]	=	TRUE
	L["Y Offset"]	=	TRUE
	L["Main-hand Bar Color"]	=	TRUE
	L["Main-hand Bar Text Color"]	=	TRUE
	L["Off-hand Bar Color"]	=	TRUE
	L["Off-hand Bar Text Color"]	=	TRUE
	L["In Combat Alpha"]	=	TRUE
	L["Out of Combat Alpha"]	=	TRUE
	L["Backplane Alpha"]	=	TRUE
	L["Bar Explanation"]	=	TRUE

	--Buffs
	L["Auto Shot"]	=	TRUE
	L["Feign Death"] 	=	TRUE
	L["Trueshot Aura"] 	=	TRUE
	L["Multi-Shot"]	=	TRUE
	L["Aimed Shot"]	=	TRUE
	L["Shoot"]	=	TRUE
	L["Quick Shots"]	=	TRUE
	L["Rapid Shot"]	=	TRUE
	L["Berserking"]	=	TRUE
	L["Kiss of the Spider"]	=	TRUE
	L["Curse of Tongues"]	=	TRUE

elseif GetLocale() == "deDE" then
	L["Thank you for installing WeaponSwingTimer Version"] = "Vielen Dank, dass Sie die WeaponSwingTimer-Version installiert haben"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "von WatchYourSixx! Verwenden Sie |cFFFFC300/wst|r für weitere Optionen."
elseif GetLocale() == "esES" then
	L["Thank you for installing WeaponSwingTimer Version"] = "Gracias por instalar la versión WeaponSwingTimer"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "por WatchYourSixx! Use |cFFFFC300/wst|r para más opciones."
elseif GetLocale() == "esMX" then
	L["Thank you for installing WeaponSwingTimer Version"] = "Gracias por instalar la versión WeaponSwingTimer"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "por WatchYourSixx! Use |cFFFFC300/wst|r para más opciones."
elseif GetLocale() == "frFR" then
	L["Thank you for installing WeaponSwingTimer Version"] = "Merci d’avoir installé la version WeaponSwingTimer"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "par WatchYourSixx! Utilisez |cFFFFC300/wst|r pour plus d'options."
elseif GetLocale() == "itIT" then
	L["Thank you for installing WeaponSwingTimer Version"] = "Grazie per aver installato la versione di WeaponSwingTimer"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "di WatchYourSixx! Utilizzare |cFFFFC300/wst|r per ulteriori opzioni."
elseif GetLocale() == "koKR" then
	L["Thank you for installing WeaponSwingTimer Version"] = "WeaponSwingTimer 버전을 설치해 주셔서 감사합니다"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "WatchYourSixx 제작 더 많은 옵션을 보려면 |cFFFFC300/wst|r을 사용하십시오."
elseif GetLocale() == "ptBR" then
	L["Thank you for installing WeaponSwingTimer Version"] = "Obrigado por instalar a versão WeaponSwingTimer"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "por WatchYourSixx! Use |cFFFFC300/wst|r para obter mais opções."
elseif GetLocale() == "ruRU" then
	L["Thank you for installing WeaponSwingTimer Version"] = "Спасибо за установку версии WeaponSwingTimer"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "WatchYourSixx! Используйте |cFFFFC300/wst|r для получения дополнительных опций."
elseif GetLocale() == "zhCN" then
	--Core
	L["Thank you for installing WeaponSwingTimer Version"] = "感谢您安装WeaponSwingTimer版本！"
	L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."] = "作者：LeftHandedGlove，持续更新：WatchYourSixx，汉化：Cyanokaze。使用|cFFFFC300/wst|r获取更多选项。"
	L["Unexpected Unit Type in MissHandler()."]="Unexpected Unit Type in MissHandler()."
	L["Unexpected Unit Type in SpellHandler()."]="Unexpected Unit Type in SpellHandler()."

	--Config
	L["Global Bar Settings"]="全局设定"
	L["Melee Settings"]="近战武器监控"
	L["Hunter & Wand Settings"]="远程武器监控"
	L["Lock All Bars"]=" 全部锁定"
	L["Locks all of the swing bar frames, preventing them from being dragged."]="锁定所有进度条和窗口，防止它们被移动。"
	L["Click the + on the left for more options"]="点击左侧+显示更多选项。"

	--Player
	L["Player Swing Bar Settings"]="设置自身武器进度条"
	L["Enables the player's swing bars."]="启用主手武器进度条。"
	L["Enables the player's off-hand swing bar."]="显示副手武器进度条。"
	L["Enables the player bar's border."]="显示进度条边框。"
	L["Enables the classic texture for the player's bars."]="在进度条上启用职业纹理。"
	L["Enables the player's left side text."]="允许在进度条左侧显示武器位置。"
	L["Enables the player's right side text."]="允许在进度右侧显示计时器。"
	--Target
	L["Target Swing Bar Settings"]="设置目标武器进度条"
	L["Enables the target's swing bars."]="启用目标武器进度条。"
    	L["Enables the target's off-hand swing bar."]="显示目标副手武器进度条。"
  	L["Enables the target bar's border."]="显示目标进度条边框。"
    	L["Enables the classic texture for the target's bars."]="在目标进度条上启用职业纹理。"
    	L["Enables the target's left side text."]="允许在目标进度条左侧显示武器位置。"
    	L["Enables the target's right side text."]="允许在目标进度右侧显示计时器。"
	--Shot
	L["Failed"] = "失败"
	L["Interrupted"] = "打断"
	L["Hunter & Wand Shot Bar Settings"]="设置远程武器进度条"
	L["General Settings"]="基础设置"
	L["YaHT / One bar"]=" 双向/单向"
    	L["Changes the Auto Shot bar to a single bar that fills from left to right"]="切换自动射击条为双向/单向。"
    	L["Show Text"]=" 计时器"
    	L["Enables the shot bar text."]="启用射击进度条文字。"
    	L["Auto Shot Cooldown Color"]="自动射击冷却颜色"
    	L["Auto Shot Cast Color"]="自动射击颜色"
	L["Hunter Specific Settings"]="猎人特殊设置"
    	L["Aimed Shot cast bar"]=" 瞄准射击条"
    	L["Allows the cast bar to show Aimed Shot casts."]="允许显示瞄准射击条。"
    	L["Multi-Shot cast bar"]=" 多重射击条"
    	L["Allows the cast bar to show Multi-Shot casts."]="允许显示多重射击条。"
    	L["Latency bar"]=" 延迟条"
    	L["Shows a bar that represents latency on cast bar."]="允许显示延迟条。"
    	L["Multi-Shot clip bar"]=" 多重射击覆盖区间"
	L["Shows a bar that represents when a Multi-Shot would clip an Auto Shot."]="允许显示多重射击覆盖区间。"
	L["Auto Shot delay timer"] = " 自动射击延时器"
	L["Shows a timer that represents when Auto shot is delayed."] = "为自动射击延时显示一个计时器。"
    	L["Multi-Shot Clip Color"]="多重射击覆盖区间颜色"
	
    	--Common
	L["Main-Hand"]="主手"
	L["Off-Hand"]="副手"
    	L["Enable"]=" 启用"
    	L["Show Off-Hand"]=" 副手"
    	L["Show border"]=" 边框"
    	L["Classic bars"]=" 职业纹理"
    	L["Fill / Empty"]=" 填充/空白"
    	L["Determines if the bar is full or empty when a swing is ready."]="决定武器可用时武器条是填充状态还是空白状态。"
    	L["Show Left Text"]=" 武器位置"
    	L["Show Right Text"]=" 计时器"
	L["Bar Width"]="宽度"
    	L["Bar Height"]="高度"
    	L["X Offset"]="X坐标"
    	L["Y Offset"]="Y坐标"
	L["Main-hand Bar Color"]="主武器进度条颜色"
    	L["Main-hand Bar Text Color"]="主武器文本颜色"
    	L["Off-hand Bar Color"]="副武器进度条颜色"
    	L["Off-hand Bar Text Color"]="副武器文本颜色"
    	L["In Combat Alpha"]="战斗时透明度"
    	L["Out of Combat Alpha"]="脱离战斗透明度"
    	L["Backplane Alpha"]="底板透明度"
	L["Bar Explanation"]="图片说明："

	--Buffs
	L["Auto Shot"]="自动射击"
	L["Feign Death"] = "假死"
	L["Trueshot Aura"] = "强击光环"
	L["Multi-Shot"]="多重射击"
	L["Aimed Shot"]="瞄准射击"
	L["Shoot"]="射击"
	L["Quick Shots"]="快速射击"
	L["Rapid Shot"]="急速射击"
	L["Berserking"]="狂暴"
	L["Kiss of the Spider"]="蜘蛛之吻"
	L["Curse of Tongues"]="语言诅咒"
	
elseif GetLocale() == "zhTW" then -- 供中国香港、中国澳门和中国台湾省同胞使用

	--Core
	L["Thank you for installing WeaponSwingTimer Version"] = "感謝您安裝WeaponSwingTimer版本(Translated by Cyanokaze，Taiwan is part of China）"
	L["by LeftHandedGlove! Use |cFFFFC300/wst|r for more options."] = "by LeftHandedGlove！使用|cFFFFC300/wst|r獲取更多選項。"
	L["Unexpected Unit Type in MissHandler()."]="Unexpected Unit Type in MissHandler()."
	L["Unexpected Unit Type in SpellHandler()."]="Unexpected Unit Type in SpellHandler()."

	--Config
	L["Global Bar Settings"]="全域設定"
	L["Melee Settings"]="近戰武器監控"
	L["Hunter & Wand Settings"]="遠端武器監控"
	L["Lock All Bars"]=" 全部鎖定"
	L["Locks all of the swing bar frames, preventing them from being dragged."]="鎖定所有進度條和視窗，防止它們被移動。"
	L["Click the + on the left for more options"]="點擊左側+顯示更多選項。"

	--Player
	L["Player Swing Bar Settings"]="設置自身武器進度條"
	L["Enables the player's swing bars."]="啟用主手武器進度條。"
	L["Enables the player's off-hand swing bar."]="顯示副手武器進度條。"
	L["Enables the player bar's border."]="顯示進度條邊框。"
	L["Enables the classic texture for the player's bars."]="在進度條上啟用職業紋理。"
	L["Enables the player's left side text."]="允許在進度條左側顯示武器位置。"
	L["Enables the player's right side text."]="允許在進度右側顯示計時器。"
	--Target
	L["Target Swing Bar Settings"]="設置目標武器進度條"
	L["Enables the target's swing bars."]="啟用目標武器進度條。"
    	L["Enables the target's off-hand swing bar."]="顯示目標副手武器進度條。"
  	L["Enables the target bar's border."]="顯示目標進度條邊框。"
    	L["Enables the classic texture for the target's bars."]="在目標進度條上啟用職業紋理。"
    	L["Enables the target's left side text."]="允許在目標進度條左側顯示武器位置。"
    	L["Enables the target's right side text."]="允許在目標進度右側顯示計時器。"
	--Shot
	L["Failed"] = "失敗"
	L["Interrupted"] = "打斷"
	L["Hunter & Wand Shot Bar Settings"]="設置遠端武器進度條"
	L["General Settings"]="基礎設置"
	L["YaHT / One bar"]=" 雙向/單向"
    	L["Changes the Auto Shot bar to a single bar that fills from left to right"]="切換自動射擊條為雙向/單向。"
    	L["Show Text"]=" 計時器"
    	L["Enables the shot bar text."]="啟用射擊進度條文字。"
    	L["Auto Shot Cooldown Color"]="自動射擊冷卻顏色"
    	L["Auto Shot Cast Color"]="自動射擊顏色"
	L["Hunter Specific Settings"]="獵人特殊設置"
    	L["Aimed Shot cast bar"]=" 瞄準射擊條"
    	L["Allows the cast bar to show Aimed Shot casts."]="允許顯示瞄準射擊條。"
    	L["Multi-Shot cast bar"]=" 多重射擊條"
    	L["Allows the cast bar to show Multi-Shot casts."]="允許顯示多重射擊條。"
    	L["Latency bar"]=" 延遲條"
    	L["Shows a bar that represents latency on cast bar."]="允許顯示延遲條。"
    	L["Multi-Shot clip bar"]=" 多重射擊覆蓋區間"
	L["Shows a bar that represents when a Multi-Shot would clip an Auto Shot."]="允許顯示多重射擊覆蓋區間。"
	L["Auto Shot delay timer"] = " 自動射擊延時器"
	L["Shows a timer that represents when Auto shot is delayed."] = "為自動射擊延時顯示一個計時器。"
    	L["Multi-Shot Clip Color"]="多重射擊覆蓋區間顏色"
	
    	--Common
	L["Main-Hand"]="主手"
	L["Off-Hand"]="副手"
    	L["Enable"]=" 啟用"
    	L["Show Off-Hand"]=" 副手"
    	L["Show border"]=" 邊框"
    	L["Classic bars"]=" 職業紋理"
    	L["Fill / Empty"]=" 填充/空白"
    	L["Determines if the bar is full or empty when a swing is ready."]="決定武器可用時武器條是填充狀態還是空白狀態。"
    	L["Show Left Text"]=" 武器位置"
    	L["Show Right Text"]=" 計時器"
	L["Bar Width"]="寬度"
    	L["Bar Height"]="高度"
    	L["X Offset"]="X座標"
    	L["Y Offset"]="Y座標"
	L["Main-hand Bar Color"]="主武器進度條顏色"
    	L["Main-hand Bar Text Color"]="主武器文本顏色"
    	L["Off-hand Bar Color"]="副武器進度條顏色"
    	L["Off-hand Bar Text Color"]="副武器文本顏色"
    	L["In Combat Alpha"]="戰鬥時透明度"
    	L["Out of Combat Alpha"]="脫離戰鬥透明度"
    	L["Backplane Alpha"]="底板透明度"
	L["Bar Explanation"]="圖片說明："

	--Buffs need true name.
	--[[
	L["Auto Shot"]="自動射擊"
	L["Feign Death"] = "假死"
	L["Trueshot Aura"] = "強擊光環"
	L["Multi-Shot"]="多重射擊"
	L["Aimed Shot"]="瞄準射擊"
	L["Shoot"]="射擊"
	L["Quick Shots"]="快速射擊"
	L["Rapid Shot"]="急速射擊"
	L["Berserking"]="狂暴"
	L["Kiss of the Spider"]="蜘蛛之吻"
	L["Curse of Tongues"]="語言詛咒"
	]]
	
end

