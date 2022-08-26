import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';

class PrintData {
  final String name;
  final String address;
  //Todo: ini better enum saja avoid mistyping
  final ConnectionType connectionType;
  final PrinterDriver selectedDriver;
  //Todo: "ini pakek abstak kelas ntr supaya bisa nerima childrennya yg exten abstrak class"
  final PaperSize selectedPaperSize;
  final String printTitle;
  final String printAction;
  final List<String> printContent;

  PrintData(
      {required this.name,
      required this.address,
      required this.connectionType,
      required this.selectedDriver,
      required this.selectedPaperSize,
      required this.printTitle,
      required this.printAction,
      required this.printContent});

  PrintData copyWith({required String printActionParams, required String printTitleParams}){
    return PrintData(
      name: name,
      address: address,
      connectionType: connectionType,
      selectedDriver: selectedDriver,
      selectedPaperSize: selectedPaperSize,
      printAction: printActionParams,
      printContent: printContent,
      printTitle: printTitleParams
      );
  }    
}

enum ConnectionType{
  USB,BLUETOOTH,WIFI
}