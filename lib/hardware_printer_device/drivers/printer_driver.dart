import 'package:flutter/material.dart';
import 'package:printer_controller/hardware_printer_device/drivers/advan_harvard_o1_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/bellav_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/epson_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/generic_2_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/generic_3_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/generic_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/honeywell_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/imin_d2_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/janz_label_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/panda_prj_58d_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/panda_prj_80bl_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/sano_2054tb_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/star_mpop_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/sunmi_t2_mini_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart' ;
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_58mm.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_76mm.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_80mm.dart';
import 'package:printer_controller/shared/printer_helper_constant.dart';
import 'package:image/image.dart' as prefix;
import 'package:printer_controller/shared/image_extension.dart' as imageExtension;


enum PrinterCommand { ESC, TSC }

abstract class PrinterDriver {
  final PrinterCommand commandType = PrinterCommand.ESC;

  PrinterDriver();

  final int HT = 0x9;
  final int LF = 0x0A;
  final int CR = 0x0D;
  final int ESC = 0x1B;
  final int DLE = 0x10;
  final int GS = 0x1D;
  final int FS = 0x1C;
  final int STX = 0x02;
  final int US = 0x1F;
  final int CAN = 0x18;
  final int CLR = 0x0C;
  final int EOT = 0x04;

  final bool isCutLine = true;
  final List<int> INIT = [27, 64];
  final List<int> ESC_FONT_COLOR_DEFAULT = [0x1B, 0x72, 0x00];
  final List<int> FS_FONT_ALIGN = [0x1C, 0x21, 1, 0x1B, 0x21, 1];
  final List<int> ESC_ALIGN_LEFT = [0x1b, 0x61, 0x00];
  final List<int> ESC_ALIGN_RIGHT = [0x1b, 0x61, 0x02];
  final List<int> ESC_ALIGN_CENTER = [0x1b, 0x61, 0x01];
  final List<int> ESC_CANCEL_BOLD = [0x1B, 0x45, 0];

  /*********************************************/
  final List<int> ESC_HORIZONTAL_CENTERS = [0x1B, 0x44, 20, 28, 00];
  final List<int> ESC_CANCEL_HORIZONTAL_CENTERS = [0x1B, 0x44, 00];

  /*********************************************/

  final List<int> ESC_ENTER = [0x1B, 0x4A, 0x40];
  final List<int> PRINTER_TEST = [0x1D, 0x28, 0x41];
  List<int> FEED_LINE = [10];
  List<int> SELECT_FONT_A = [20, 33, 0];
  List<int> SET_BAR_CODE_HEIGHT = [29, 104, 100];
  List<int> PRINT_BAR_CODE_1 = [29, 107, 2];
  List<int> SEND_NULL_BYTE = [0x00];
  List<int> SELECT_PRINT_SHEET = [0x1B, 0x63, 0x30, 0x02];
  List<int> FEED_PAPER_AND_CUT = [0x1D, 0x56, 66, 0x00];
  List<int> SELECT_CYRILLIC_CHARACTER_CODE_TABLE = [0x1B, 0x74, 0x11];
  List<int> SELECT_BIT_IMAGE_MODE = [0x1B, 0x2A, 33, -128, 0];
  List<int> SET_LINE_SPACING_24 = [0x1B, 0x33, 24];
  List<int> SET_LINE_SPACING_30 = [0x1B, 0x33, 30];
  List<int> TRANSMIT_DLE_PRINTER_STATUS = [0x10, 0x04, 0x01];
  List<int> TRANSMIT_DLE_OFFLINE_PRINTER_STATUS = [0x10, 0x04, 0x02];
  List<int> TRANSMIT_DLE_ERROR_STATUS = [0x10, 0x04, 0x03];
  List<int> TRANSMIT_DLE_ROLL_PAPER_SENSOR_STATUS = [0x10, 0x04, 0x04];
  List<int> PRE_TEXT = [];
  List<int> POST_PRINT = [];

  // ------------------------

  final List<int> CASHDRAWER_1 = [27, 112, 0, 200, 250];
  final List<int> CASHDRAWER_2 = [27, 112, 1, 200, 250];

  // ------------------------

  final int imagePadding = 0;

  // ------------------------

  prefix.Image? preprintImageProcess(prefix.Image? image, int maxImageWidth) {
    prefix.Image resizedImage = image!.width > maxImageWidth
        ? prefix.copyResize(image, width: maxImageWidth)
        : prefix.Image.from(image);
    return resizedImage;
  }

  // ------------------------

  // INFO: some printer need to be delayed ech time we send data, to prevent sliced image
  bool isNeedDelay = false;

  // INFO: some printer needed to be restart first to prevent connection error
  bool isNeedRestart = false;

  // ------------------------

  final List<PaperSize> paperSizeList = [
    PaperSize58mm(),
    PaperSize76mm(),
    PaperSize80mm(),
  ];

  factory PrinterDriver.of(String driverType) {
    if (driverType == PrinterHelperConstant.PRINTER_DRIVER_GENERIC_2) {
      return Generic2PrinterDriver();
    } else if (driverType == PrinterHelperConstant.PRINTER_DRIVER_GENERIC_3) {
      return Generic3PrinterDriver();
    } else if (driverType ==
        PrinterHelperConstant.PRINTER_DRIVER_EPSON_TM_T82) {
      return GenericPrinterDriver();
    } else if (driverType ==
        PrinterHelperConstant.PRINTER_DRIVER_ADVAN_HARVARD_O1) {
      return AdvanHarvardPrinterDriver();
    } else if (driverType == PrinterHelperConstant.PRINTER_DRIVER_JANZ_LABEL) {
      return JanzLabelPrinterDriver();
    } else if (driverType ==
        PrinterHelperConstant.PRINTER_DRIVER_SUNMI_T2_MINI) {
      return SunmiT2MiniPrinterDriver();
    } else if (driverType ==
        PrinterHelperConstant.PRINTER_DRIVER_PANDA_PRJ_80BL) {
      return PandaPrj80BlDriver();
    } else if (driverType == PrinterHelperConstant.PRINTER_DRIVER_SANO_2054TB) {
      return Sano2054TbDriver();
    } else if (driverType ==
        PrinterHelperConstant.PRINTER_DRIVER_HONEYWELL_PC42T) {
      return HoneywellDriver();
    } else if (driverType == PrinterHelperConstant.PRINTER_DRIVER_STAR_MPOP) {
      return StarMPopPrinterDriver();
    } else if (driverType == PrinterHelperConstant.PRINTER_DRIVER_EPSON_TM) {
      return EpsonPrinterDriver();
    } else if (driverType ==
        PrinterHelperConstant.PRINTER_DRIVER_PANDA_PRJ_58D) {
      return PandaPRJ58DPrinterDriver();
    } else if (driverType ==
        PrinterHelperConstant.PRINTER_DRIVER_BELLAV_ZCS_103) {
      return BellavPrinterDriver();
    } else if (driverType == PrinterHelperConstant.PRINTER_DRIVER_IMIN_D2) {
      return IminD2PrinterDriver();
    } else {
      return GenericPrinterDriver();
    }
  }
}
