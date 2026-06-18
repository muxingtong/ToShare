import { AbilityStage, Want } from '@kit.AbilityKit';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    hilog.info(0x0001, 'ToShare', 'AbilityStage onCreate');
  }

  onAcceptWant(want: Want): string {
    return 'MyAbilityStage';
  }
}
