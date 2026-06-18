import UIAbility from "@ohos:app.ability.UIAbility";
import type Want from "@ohos:app.ability.Want";
import type AbilityConstant from "@ohos:app.ability.AbilityConstant";
import type window from "@ohos:window";
import hilog from "@ohos:hilog";
import { HistoryRepository } from "@normalized:N&&&entry/src/main/ets/services/HistoryRepository&";
export default class MainAbility extends UIAbility {
    private windowStage: window.WindowStage | null = null;
    onCreate(want: Want, param: AbilityConstant.LaunchParam): void {
        hilog.info(0x0001, 'ToShare', 'MainAbility onCreate');
        HistoryRepository.getInstance().init(this.context);
    }
    onDestroy(): void {
        hilog.info(0x0001, 'ToShare', 'MainAbility onDestroy');
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        hilog.info(0x0001, 'ToShare', 'MainAbility onWindowStageCreate');
        this.windowStage = windowStage;
        windowStage.loadContent('pages/HomePage', (err) => {
            if (err.code) {
                hilog.error(0x0001, 'ToShare', 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
                return;
            }
            hilog.info(0x0001, 'ToShare', 'HomePage loaded successfully.');
            // 配置沉浸式窗口 — 状态栏/导航栏透明，内容延伸到系统栏下方
            this.setupImmersiveWindow(windowStage);
        });
    }
    /**
     * 沉浸式窗口配置
     * 让内容延伸到状态栏和导航栏，配合毛玻璃材质实现沉浸光效
     */
    private async setupImmersiveWindow(windowStage: window.WindowStage): Promise<void> {
        try {
            const win = windowStage.getMainWindowSync();
            if (!win) {
                return;
            }
            // 1. 启用全屏沉浸式布局 — 内容延伸到系统栏区域
            win.setWindowLayoutFullScreen(true);
            // 2. 状态栏设为透明 — 让渐变背景透出
            win.setWindowSystemBarProperties({
                statusBarColor: '#00000000',
                navigationBarColor: '#00000000',
                statusBarContentColor: '#FFFFFF',
                navigationBarContentColor: '#FF1C1B1F'
            });
            hilog.info(0x0001, 'ToShare', 'Immersive window configured');
        }
        catch (err) {
            hilog.error(0x0001, 'ToShare', 'Failed to setup immersive window: %{public}s', JSON.stringify(err));
        }
    }
    onWindowStageDestroy(): void {
        hilog.info(0x0001, 'ToShare', 'MainAbility onWindowStageDestroy');
    }
    onForeground(): void {
        hilog.info(0x0001, 'ToShare', 'MainAbility onForeground');
    }
    onBackground(): void {
        hilog.info(0x0001, 'ToShare', 'MainAbility onBackground');
    }
}
