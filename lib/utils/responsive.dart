import 'package:flutter/material.dart';
import 'constants.dart';

enum ScreenType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  ScreenType get screenType {
    final w = MediaQuery.of(this).size.width;
    if (w < Constants.mobileBreakpoint) return ScreenType.mobile;
    if (w < Constants.tabletBreakpoint) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;
  bool get isWide => !isMobile;

  EdgeInsets get responsivePadding => EdgeInsets.all(isMobile ? 12 : 24);

  EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24);

  double get gridColumnCount {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
  }

  double get contentWidth {
    final w = MediaQuery.of(this).size.width;
    final horizontalPad = (isMobile ? 12 : 24) * 2;
    if (isDesktop)
      return (w - horizontalPad - Constants.sidebarExpanded).clamp(400, 1200);
    return w - horizontalPad;
  }

  double get iconSm => isMobile ? 16 : 20;
  double get iconMd => isMobile ? 20 : 24;
  double get iconLg => isMobile ? 24 : 32;
  double get iconNav => isMobile ? 20 : 22;

  double get fontSizeSm => isMobile ? 11 : 13;
  double get fontSizeMd => isMobile ? 13 : 15;
  double get fontSizeLg => isMobile ? 16 : 20;
  double get fontSizeXl => isMobile ? 20 : 28;
  double get fontSizeNav => isMobile ? 8 : 9;
  double get fontSizeCaption => isMobile ? 10 : 12;
}
