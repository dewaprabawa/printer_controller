class PrinterHelperConstant {

    static const String HARDWARE_KONEKSI_BLUETOOTH = 'Bluetooth';
  static const String HARDWARE_KONEKSI_LAN_WIFI = 'Lan/Wi-Fi';
  static const String HARDWARE_KONEKSI_USB_SERIAL = 'Usb/Serial';
  static const String HARDWARE_KONEKSI_APPLICATION = 'Aplikasi';

  static const String CONNECTION_BLUETOOTH = "Bluetooth connection";
  static const String CONNECTION_WIFILAN = "Wifi/LAN connection";
  static const String CONNECTION_USB = "USB connection";
  static const String CONNECTION_SERIAL = "Serial connection";
  static const String CONNECTION_INTERNAL = "Internal connection";

  static const String PRINTER_TIPE_KERTAS_58MM = '58mm';
  static const String PRINTER_TIPE_KERTAS_76MM = '76mm';
  static const String PRINTER_TIPE_KERTAS_80MM = '80mm';

  static const String PRINTER_TIPE_KERTAS_LABEL_80x50MM = '80x50mm';
  static const String PRINTER_TIPE_KERTAS_LABEL_100x75MM = '100x75mm';
  static const String PRINTER_TIPE_KERTAS_LABEL_100x60MM = '100x60mm';

  static const int PRINTER_JUMLAHKARAKTER_TIPE_KERTAS_58MM = 32;
  static const int PRINTER_JUMLAHKARAKTER_TIPE_KERTAS_76MM = 40;
  static const int PRINTER_JUMLAHKARAKTER_TIPE_KERTAS_80MM = 48;

  static const int PRINTER_JUMLAHKARAKTER_TIPE_KERTAS_LABEL_80x50MM = 48;
  static const int PRINTER_JUMLAHKARAKTER_TIPE_KERTAS_LABEL_100x75MM = 60;
  static const int PRINTER_JUMLAHKARAKTER_TIPE_KERTAS_LABEL_100x60MM = 60;
  

  static const List<int> BAUD_RATE_LIST = <int>[
    2400,
    4800,
    9600,
    14400,
    19200,
    38400,
    57600,
    115200,
    128000
  ];
  
  static const String PRINTER_DRIVER_GENERIC_1 = "Generic 1";
  static const String PRINTER_DRIVER_GENERIC_2 = "Generic 2";
  static const String PRINTER_DRIVER_GENERIC_3 = "Generic 3";
  static const String PRINTER_DRIVER_JANZ_LABEL = "Gainscha GS-2208D";
  static const String PRINTER_DRIVER_ADVAN_HARVARD_O1 = "Advan Harvard O1";
  static const String PRINTER_DRIVER_SUNMI_T2_MINI = "Sunmi T2 Mini";
  static const String PRINTER_DRIVER_IMIN_D2 = "Imin D2";
  static const String PRINTER_DRIVER_PANDA_PRJ_80BL = "Panda PRJ-80BL";
  static const String PRINTER_DRIVER_PANDA_PRJ_58D = "Panda PRJ-58D";
  static const String PRINTER_DRIVER_HONEYWELL_PC42T = "Honeywell PC42T";
  static const String PRINTER_DRIVER_SANO_2054TB = "Sano 2054TB";
  static const String PRINTER_DRIVER_BELLAV_ZCS_103 = "Bellav ZCS 103";
  static const String PRINTER_DRIVER_EPSON_TM = "Epson TM";
  static const String PRINTER_DRIVER_EPSON_TM_M10 = "Epson TM M10";
  static const String PRINTER_DRIVER_EPSON_TM_M30 = "Epson TM M30";
  static const String PRINTER_DRIVER_EPSON_TM_P20 = "Epson TM P20";
  static const String PRINTER_DRIVER_EPSON_TM_P60 = "Epson TM P60";
  static const String PRINTER_DRIVER_EPSON_TM_P60II = "Epson TM P60II";
  static const String PRINTER_DRIVER_EPSON_TM_P80 = "Epson TM P80";
  static const String PRINTER_DRIVER_EPSON_TM_T20 = "Epson TM T20";
  static const String PRINTER_DRIVER_EPSON_TM_T60 = "Epson TM T60";
  static const String PRINTER_DRIVER_EPSON_TM_T70 = "Epson TM T70";
  static const String PRINTER_DRIVER_EPSON_TM_T81 = "Epson TM T81";
  static const String PRINTER_DRIVER_EPSON_TM_T82 = "Epson TM T82";
  static const String PRINTER_DRIVER_EPSON_TM_T83 = "Epson TM T83";
  static const String PRINTER_DRIVER_EPSON_TM_T88 = "Epson TM T88";
  static const String PRINTER_DRIVER_EPSON_TM_T90 = "Epson TM T90";
  static const String PRINTER_DRIVER_EPSON_TM_T90KP = "Epson TM T90KP";
  static const String PRINTER_DRIVER_EPSON_TM_U220 = "Epson TM U220";
  static const String PRINTER_DRIVER_EPSON_TM_U330 = "Epson TM U330";
  static const String PRINTER_DRIVER_EPSON_TM_L90 = "Epson TM L90";
  static const String PRINTER_DRIVER_EPSON_TM_H6000 = "Epson TM H6000";
  static const String PRINTER_DRIVER_STAR_MPOP = "Star mPOP";
  static const String PRINTER_DRIVER_PTKSAI = "PTKSAI";
  static const String PRINTER_DRIVER_SUNMI = "SUNMI";
  static const String PRINTER_DRIVER_X = "Printer X";

  static const List<String> PRINTER_DRIVER_LIST = [
    PRINTER_DRIVER_GENERIC_1,
    PRINTER_DRIVER_GENERIC_2,
    PRINTER_DRIVER_GENERIC_3,
    PRINTER_DRIVER_BELLAV_ZCS_103,
    PRINTER_DRIVER_PANDA_PRJ_58D,
    PRINTER_DRIVER_ADVAN_HARVARD_O1,
    PRINTER_DRIVER_SUNMI_T2_MINI,
    PRINTER_DRIVER_JANZ_LABEL,
    PRINTER_DRIVER_STAR_MPOP,
    PRINTER_DRIVER_EPSON_TM,
    PRINTER_DRIVER_IMIN_D2,
  ];

  static const List<String> ALAMAT_PRINTER_DRIVER_LIST = [
    PRINTER_DRIVER_PANDA_PRJ_80BL,
    PRINTER_DRIVER_SANO_2054TB,
    // PRINTER_DRIVER_HONEYWELL_LABEL,
  ];

  static const String PRINTER_SERVER = "Printer server";

  static const String ACTION_PRINT_COMPLETE =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_COMPLETE";
  static const String ACTION_PRINT_ERROR =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_ERROR";
  static const String ACTION_PRINT_LIMIT =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_LIMIT";
  static const String ACTION_PRINT_START =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_START";
  static const String ACTION_OPEN_CASHDRAWER_COMPLETED =
      "com.klopos.setting.hardware.printer.CONST.ACTION_OPEN_CASHDRAWER_COMPLETED";

  static const String ACTION_PRINT_STRUK =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_STRUK";
  static const String ACTION_PRINT_BILL =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_BILL";
  static const String ACTION_PRINT_CHECKER =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_CHECKER";
  static const String ACTION_PRINT_DAPUR =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_DAPUR";
  static const String ACTION_PRINT_SURAT_JALAN =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_DELIVERY";
  static const String ACTION_PRINT_LABEL =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_LABEL";

  static const String ACTION_AUTO_PRINT_ORDER =
      "com.klopos.setting.hardware.printer.CONST.ACTION_AUTO_PRINT_ORDER";
  static const String ACTION_AUTO_PRINT_BAYAR =
      "com.klopos.setting.hardware.printer.CONST.ACTION_AUTO_PRINT_BAYAR";
  static const String ACTION_AUTO_PRINT_SHARED =
      "com.klopos.setting.hardware.printer.CONST.ACTION_AUTO_PRINT_SHARED";

  static const String ACTION_STOP_SERVICE =
      "com.klopos.setting.hardware.printer.CONST.ACTION_STOP_SERVICE";
  static const String ACTION_START_SERVICE =
      "com.klopos.setting.hardware.printer.CONST.ACTION_START_SERVICE";

  static const String DATA_RAW_BYTES =
      "com.klopos.setting.hardware.printer.CONST.DATA_RAW_BYTES";
  static const String DATA_LINE =
      "com.klopos.setting.hardware.printer.CONST.DATA_LINE";
  static const String DATA_MULTILINE =
      "com.klopos.setting.hardware.printer.CONST.DATA_MULTILINE";
  static const String DATA_ITEM =
      "com.klopos.setting.hardware.printer.CONST.DATA_ITEM";
  static const String DATA_ITEM_SOLD =
      "com.klopos.setting.hardware.printer.CONST.DATA_ITEM_SOLD";
  static const String DATA_TYPE_JASA =
      "com.klopos.setting.hardware.printer.CONST.DATA_TYPE_JASA";
  static const String DATA_SEPARATOR =
      "com.klopos.setting.hardware.printer.CONST.DATA_SEPARATOR";
  static const String DATA_PAYMENT =
      "com.klopos.setting.hardware.printer.CONST.DATA_PAYMENT";
  static const String DATA_PAYMENT_INFO =
      "com.klopos.setting.hardware.printer.CONST.DATA_PAYMENT_INFO";
  static const String DATA_INFO =
      "com.klopos.setting.hardware.printer.CONST.DATA_INFO";
  static const String DATA_NOTE =
      "com.klopos.setting.hardware.printer.CONST.DATA_NOTE";
  static const String DATA_RECEIPT_TYPE =
      "com.klopos.setting.hardware.printer.CONST.DATA_RECEIPT_TYPE";
  static const String DATA_RECEIPT_TYPE_OPEN = "open";
  static const String DATA_RECEIPT_TYPE_CLOSE = "close";
  static const String DATA_RECEIPT_TIME =
      "com.klopos.setting.hardware.printer.CONST.DATA_RECEIPT_TIME";
  static const String DATA_LF =
      "com.klopos.setting.hardware.printer.CONST.DATA_LF";
  static const String DATA_LINE_ALIGNMENT =
      "com.klopos.setting.hardware.printer.CONST.DATA_LINE_ALIGNMENT";
  static const String DATA_LINE_CUT =
      "com.klopos.setting.hardware.printer.CONST.DATA_LINE_CUT";
  static const String DATA_IKLAN =
      "com.klopos.setting.hardware.printer.CONST.DATA_IKLAN";
  static const String DATA_LOGO =
      "com.klopos.setting.hardware.printer.CONST.DATA_LOGO";
  static const String DATA_IMAGE_FILE =
      "com.klopos.setting.hardware.printer.CONST.DATA_IMAGE_FILE";
  static const String DATA_IMAGE_ASSET =
      "com.klopos.setting.hardware.printer.CONST.DATA_IMAGE_ASSET";
  static const String DATA_QR =
      "com.klopos.setting.hardware.printer.CONST.DATA_QR";
  static const String DATA_BARCODE =
      "com.klopos.setting.hardware.printer.CONST.DATA_BARCODE";
  static const String DATA_TEST_PRINT =
      "com.klopos.setting.hardware.printer.CONST.DATA_TEST_PRINT";
  static const String DATA_DRAWER =
      "com.klopos.setting.hardware.printer.CONST.DATA_DRAWER";
  static const String DATA_JENIS_PRINTER =
      "com.klopos.setting.hardware.printer.CONST.DATA_JENIS_PRINTER";
  static const String DATA_AUTO_PRINT =
      "com.klopos.setting.hardware.printer.CONST.DATA_AUTO_PRINT";
  static const String DATA_DATA_TYPE =
      "com.klopos.setting.hardware.printer.CONST.DATA_DATA_TYPE";
  static const String DATA_DO_PRINT =
      "com.klopos.setting.hardware.printer.CONST.DATA_DO_PRINT";

  static const String PRINT_STRUK_LABEL = " Terbayar ";
  static const String PRINT_STRUK_LABEL_COPY = "COPY";

  static const String ACTION_OPEN_CASHDRAWER =
      "com.klopos.setting.hardware.printer.CONST.ACTION_OPEN_CASHDRAWER";
  static const String ACTION_PRINT_TUTUP_KASIR =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_TUTUP_KASIR";

  static const String ACTION_PRINT_JASA =
      "com.klopos.setting.hardware.printer.CONST.ACTION_PRINT_JASA";

  static const String PRINT_PRICE_INCLUDE_TAX_LABEL =
      "#Harga sudah termasuk pajak senilai ";

  static final String PREFS_USAHA_LOGO_CABANG_BILL =
      "prefs_usaha_logo_cabang_bill"; 

  static final String PREF_TEMP_URL_LOGO_BILL = "prefs_temp_url_logo_bill";

   static final String PREF_TEMP_PATH_LOCAL_LOGO_BILL =
      "prefs_temp_path_local_logo_bill";       
}
