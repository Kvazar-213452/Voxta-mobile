import 'package:flutter/material.dart';

class AppColors {
  static String theme = "";

  static void changeTheme(String theme_new) {
    theme = theme_new;
  }

  static Color get gradientStart => theme == "white" ? _AppColorsWhite.gradientStart : _AppColorsDark.gradientStart;
  static Color get gradientMiddle => theme == "white" ? _AppColorsWhite.gradientMiddle : _AppColorsDark.gradientMiddle;
  static Color get gradientEnd => theme == "white" ? _AppColorsWhite.gradientEnd : _AppColorsDark.gradientEnd;
  
  static Color get chatItemBackground => theme == "white" ? _AppColorsWhite.chatItemBackground : _AppColorsDark.chatItemBackground;
  static Color get whiteText => theme == "white" ? _AppColorsWhite.whiteText : _AppColorsDark.whiteText;
  static Color get loadingIndicator => theme == "white" ? _AppColorsWhite.loadingIndicator : _AppColorsDark.loadingIndicator;
  
  static Color get brandGreen => theme == "white" ? _AppColorsWhite.brandGreen : _AppColorsDark.brandGreen;
  static Color get blackText => theme == "white" ? _AppColorsWhite.blackText : _AppColorsDark.blackText;
  
  static Color get white54 => theme == "white" ? _AppColorsWhite.white54 : _AppColorsDark.white54;
  static Color get white70 => theme == "white" ? _AppColorsWhite.white70 : _AppColorsDark.white70;
  
  static Color get darkBackground => theme == "white" ? _AppColorsWhite.darkBackground : _AppColorsDark.darkBackground;
  static Color get lightGray => theme == "white" ? _AppColorsWhite.lightGray : _AppColorsDark.lightGray;
  static Color get transparentWhite => theme == "white" ? _AppColorsWhite.transparentWhite : _AppColorsDark.transparentWhite;
  static Color get errorRed => theme == "white" ? _AppColorsWhite.errorRed : _AppColorsDark.errorRed;
  
  static Color get profileBackground => theme == "white" ? _AppColorsWhite.profileBackground : _AppColorsDark.profileBackground;
  
  static Color get modalBackground => theme == "white" ? _AppColorsWhite.modalBackground : _AppColorsDark.modalBackground;
  static Color get modalDivider => theme == "white" ? _AppColorsWhite.modalDivider : _AppColorsDark.modalDivider;
  static Color get modalHandle => theme == "white" ? _AppColorsWhite.modalHandle : _AppColorsDark.modalHandle;
  static Color get destructiveRed => theme == "white" ? _AppColorsWhite.destructiveRed : _AppColorsDark.destructiveRed;
  static Color get modalBorder => theme == "white" ? _AppColorsWhite.modalBorder : _AppColorsDark.modalBorder;
  static Color get transparent => theme == "white" ? _AppColorsWhite.transparent : _AppColorsDark.transparent;
  static Color get overlayBackground => theme == "white" ? _AppColorsWhite.overlayBackground : _AppColorsDark.overlayBackground;
  
  static Color get warningRed => theme == "white" ? _AppColorsWhite.warningRed : _AppColorsDark.warningRed;
  static Color get warningRedLight => theme == "white" ? _AppColorsWhite.warningRedLight : _AppColorsDark.warningRedLight;
  static Color get grayText => theme == "white" ? _AppColorsWhite.grayText : _AppColorsDark.grayText;
  static Color get dialogOverlay => theme == "white" ? _AppColorsWhite.dialogOverlay : _AppColorsDark.dialogOverlay;
  static Color get whiteTransparent08 => theme == "white" ? _AppColorsWhite.whiteTransparent08 : _AppColorsDark.whiteTransparent08;
  
  static Color get brandGreenTransparent => theme == "white" ? _AppColorsWhite.brandGreenTransparent : _AppColorsDark.brandGreenTransparent;
  static Color get whiteTransparent50 => theme == "white" ? _AppColorsWhite.whiteTransparent50 : _AppColorsDark.whiteTransparent50;
  static Color get whiteTransparent30 => theme == "white" ? _AppColorsWhite.whiteTransparent30 : _AppColorsDark.whiteTransparent30;
  
  static Color get brandGreenTransparent03 => theme == "white" ? _AppColorsWhite.brandGreenTransparent03 : _AppColorsDark.brandGreenTransparent03;
  static Color get whiteTransparent07 => theme == "white" ? _AppColorsWhite.whiteTransparent07 : _AppColorsDark.whiteTransparent07;
  static Color get whiteTransparent10 => theme == "white" ? _AppColorsWhite.whiteTransparent10 : _AppColorsDark.whiteTransparent10;
  static Color get whiteTransparent05 => theme == "white" ? _AppColorsWhite.whiteTransparent05 : _AppColorsDark.whiteTransparent05;
  static Color get warningRedTransparent10 => theme == "white" ? _AppColorsWhite.warningRedTransparent10 : _AppColorsDark.warningRedTransparent10;
  static Color get brandGreenTransparent10 => theme == "white" ? _AppColorsWhite.brandGreenTransparent10 : _AppColorsDark.brandGreenTransparent10;
  
  static Color get whiteTransparent20 => theme == "white" ? _AppColorsWhite.whiteTransparent20 : _AppColorsDark.whiteTransparent20;
  static Color get whiteTransparent60 => theme == "white" ? _AppColorsWhite.whiteTransparent60 : _AppColorsDark.whiteTransparent60;
  
  static Color get errorRedTransparent20 => theme == "white" ? _AppColorsWhite.errorRedTransparent20 : _AppColorsDark.errorRedTransparent20;
  static Color get errorRedLight => theme == "white" ? _AppColorsWhite.errorRedLight : _AppColorsDark.errorRedLight;
  static Color get overlayBlack50 => theme == "white" ? _AppColorsWhite.overlayBlack50 : _AppColorsDark.overlayBlack50;
  
  static Color get brandGreenTransparent20 => theme == "white" ? _AppColorsWhite.brandGreenTransparent20 : _AppColorsDark.brandGreenTransparent20;
  static Color get brandGreenTransparent07 => theme == "white" ? _AppColorsWhite.brandGreenTransparent07 : _AppColorsDark.brandGreenTransparent07;
  static Color get brandGreenTransparent30 => theme == "white" ? _AppColorsWhite.brandGreenTransparent30 : _AppColorsDark.brandGreenTransparent30;
  static Color get blackTransparent50 => theme == "white" ? _AppColorsWhite.blackTransparent50 : _AppColorsDark.blackTransparent50;
  
  static Color get hintGray => theme == "white" ? _AppColorsWhite.hintGray : _AppColorsDark.hintGray;
  static Color get glowColor => theme == "white" ? _AppColorsWhite.glowColor : _AppColorsDark.glowColor;
  static Color get panelBackground => theme == "white" ? _AppColorsWhite.panelBackground : _AppColorsDark.panelBackground;
  static Color get shadowBlack30 => theme == "white" ? _AppColorsWhite.shadowBlack30 : _AppColorsDark.shadowBlack30;
}

class _AppColorsWhite {
  static const Color gradientStart = Color(0xFFFFFFFF);
  static const Color gradientMiddle = Color(0xFFFCFCFC);
  static const Color gradientEnd = Color(0xFFF8F8F8);
  
  static const Color chatItemBackground = Color(0xFFFFFFFF);
  static const Color whiteText = Colors.black;
  static const Color loadingIndicator = Colors.black54;
  
  static const Color brandGreen = Color(0xFF22BB66);
  static const Color blackText = Colors.black;
  
  static const Color white54 = Colors.black54;
  static const Color white70 = Colors.black87;
  
  static const Color darkBackground = Color(0xFFFFFFFF);
  static const Color lightGray = Color.fromARGB(255, 0, 0, 0);
  static const Color transparentWhite = Color(0x1A000000);
  static const Color errorRed = Colors.red;
  
  static const Color profileBackground = Color(0xFFFAFAFA);
  
  static const Color modalBackground = Color(0xFFFFFFFF);
  static const Color modalDivider = Color(0x1A000000);
  static const Color modalHandle = Color(0x4D000000);
  static const Color destructiveRed = Color(0xFFE57373);
  static const Color modalBorder = Color(0x1A000000);
  static const Color transparent = Colors.transparent;
  static const Color overlayBackground = Color(0x80000000);
  
  static const Color warningRed = Color(0xFFD32F2F);
  static const Color warningRedLight = Color(0xFFFF6666);
  static const Color grayText = Color(0xFF666666);
  static const Color dialogOverlay = Color(0xDE000000);
  static const Color whiteTransparent08 = Color(0x14000000);
  
  static const Color brandGreenTransparent = Color(0x1A22BB66);
  static const Color whiteTransparent50 = Color(0x80000000);
  static const Color whiteTransparent30 = Color(0x4D000000);
  
  static const Color brandGreenTransparent03 = Color(0x4D22BB66);
  static const Color whiteTransparent07 = Color(0xB3000000);
  static const Color whiteTransparent10 = Color(0x1A000000);
  static const Color whiteTransparent05 = Color(0x0D000000);
  static const Color warningRedTransparent10 = Color(0x1AD32F2F);
  static const Color brandGreenTransparent10 = Color(0x1A22BB66);
  
  static const Color whiteTransparent20 = Color(0x33000000);
  static const Color whiteTransparent60 = Color(0x99000000);
  
  static const Color errorRedTransparent20 = Color(0x33FF0000);
  static const Color errorRedLight = Color(0xFFFF8A80);
  static const Color overlayBlack50 = Color(0x80000000);
  
  static const Color brandGreenTransparent20 = Color(0x3322BB66);
  static const Color brandGreenTransparent07 = Color(0xB322BB66);
  static const Color brandGreenTransparent30 = Color(0x4D22BB66);
  static const Color blackTransparent50 = Color(0x80000000);
  
  static const Color hintGray = Color(0xFF888888);
  static const Color glowColor = Color(0xC722BB66);
  static const Color panelBackground = Colors.white;
  static const Color shadowBlack30 = Color(0x4D000000);
}

class _AppColorsDark {
  static const Color gradientStart = Color(0xFF1f1f1f);
  static const Color gradientMiddle = Color(0xFF2d2d32);
  static const Color gradientEnd = Color(0xFF232338);
  
  static const Color chatItemBackground = Color(0xFF3d3d3d);
  static const Color whiteText = Colors.white;
  static const Color loadingIndicator = Colors.white54;
  
  static const Color brandGreen = Color(0xFF58ff7f);
  static const Color blackText = Colors.black;
  
  static const Color white54 = Colors.white54;
  static const Color white70 = Colors.white70;
  
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color transparentWhite = Color(0x1AFFFFFF);
  static const Color errorRed = Colors.red;
  
  static const Color profileBackground = Color(0xFF1a1a1f);
  
  static const Color modalBackground = Color(0xFF2d2d2d);
  static const Color modalDivider = Color(0x1AFFFFFF);
  static const Color modalHandle = Color(0x4DFFFFFF);
  static const Color destructiveRed = Color(0xFFE57373);
  static const Color modalBorder = Color(0x1AFFFFFF);
  static const Color transparent = Colors.transparent;
  static const Color overlayBackground = Color(0x80000000);
  
  static const Color warningRed = Color(0xFFFF5555);
  static const Color warningRedLight = Color(0xFFFF3333);
  static const Color grayText = Color(0xFFAAAAAA);
  static const Color dialogOverlay = Color(0xDE000000);
  static const Color whiteTransparent08 = Color(0x14FFFFFF);
  
  static const Color brandGreenTransparent = Color(0x1A58FF7F);
  static const Color whiteTransparent50 = Color(0x80FFFFFF);
  static const Color whiteTransparent30 = Color(0x4DFFFFFF);
  
  static const Color brandGreenTransparent03 = Color(0x4D58FF7F);
  static const Color whiteTransparent07 = Color(0xB3FFFFFF);
  static const Color whiteTransparent10 = Color(0x1AFFFFFF);
  static const Color whiteTransparent05 = Color(0x0DFFFFFF);
  static const Color warningRedTransparent10 = Color(0x1AFF5555);
  static const Color brandGreenTransparent10 = Color(0x1A58FF7F);
  
  static const Color whiteTransparent20 = Color(0x33FFFFFF);
  static const Color whiteTransparent60 = Color(0x99FFFFFF);
  
  static const Color errorRedTransparent20 = Color(0x33FF0000);
  static const Color errorRedLight = Color(0xFFFF8A80);
  static const Color overlayBlack50 = Color(0x80000000);
  
  static const Color brandGreenTransparent20 = Color(0x3358FF7F);
  static const Color brandGreenTransparent07 = Color(0xB358FF7F);
  static const Color brandGreenTransparent30 = Color(0x4D58FF7F);
  static const Color blackTransparent50 = Color(0x80000000);
  
  static const Color hintGray = Color(0xFF999999);
  static const Color glowColor = Color(0xC758FF7F);
  static const Color panelBackground = Color(0x14FFFFFF);
  static const Color shadowBlack30 = Color(0x4D000000);
}