import { AppColors } from './AppColors';

/**
 * 沉浸光效主题系统
 */
export class AppTheme {
  static getColors(isDark: boolean): ResourceColor {
    return isDark ? '#1C1B1F' : '#F5F5F5';
  }

  static getCardBackground(isDark: boolean): ResourceColor {
    return isDark ? AppColors.CARD_BG_DARK : AppColors.CARD_BG_LIGHT;
  }

  static getBackground(isDark: boolean): ResourceColor {
    return isDark ? AppColors.BACKGROUND_DARK : AppColors.BACKGROUND_LIGHT;
  }

  static getTextPrimary(isDark: boolean): ResourceColor {
    return isDark ? AppColors.TEXT_PRIMARY_DARK : AppColors.TEXT_PRIMARY_LIGHT;
  }

  static getTextSecondary(isDark: boolean): ResourceColor {
    return isDark ? AppColors.TEXT_SECONDARY_DARK : AppColors.TEXT_SECONDARY_LIGHT;
  }

  static getSurface(isDark: boolean): ResourceColor {
    return isDark ? AppColors.SURFACE_DARK : AppColors.SURFACE_LIGHT;
  }

  static getDivider(isDark: boolean): ResourceColor {
    return isDark ? AppColors.DIVIDER_DARK : AppColors.DIVIDER_LIGHT;
  }

  static frostCardBg(isDark: boolean): ResourceColor {
    return isDark ? AppColors.FROST_CARD_DARK : AppColors.FROST_CARD_LIGHT;
  }

  static frostPanelBg(isDark: boolean): ResourceColor {
    return isDark ? AppColors.FROST_DARK : AppColors.FROST_LIGHT;
  }
}

/**
 * 品牌渐变配置
 */
export class BrandGradient {
  angle: number = 135;
  colors: [string, number][] = [
    [AppColors.GRADIENT_PRIMARY_START, 0.0],
    [AppColors.GRADIENT_PRIMARY_END, 1.0]
  ];
}

/**
 * 强调色渐变
 */
export class AccentGradient {
  angle: number = 135;
  colors: [string, number][] = [
    [AppColors.GRADIENT_ACCENT_START, 0.0],
    [AppColors.GRADIENT_ACCENT_END, 1.0]
  ];
}

/**
 * 暖色渐变
 */
export class WarmGradient {
  angle: number = 135;
  colors: [string, number][] = [
    [AppColors.GRADIENT_WARM_START, 0.0],
    [AppColors.GRADIENT_WARM_END, 1.0]
  ];
}

/**
 * 标题栏渐变 (竖向)
 */
export class HeaderGradient {
  angle: number = 180;
  colors: [string, number][] = [
    [AppColors.GRADIENT_HEADER_START, 0.0],
    [AppColors.GRADIENT_HEADER_MID, 0.5],
    [AppColors.GRADIENT_HEADER_END, 1.0]
  ];
}
