import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printer_controller/repository/printer_device_factory.dart';
import 'package:printer_controller/repository/printer_repository.dart';

import '../hardware_printer_device/print_data.dart';



class PrinterRepositoryImpl implements PrinterRepository {

  StreamController<PrintData> _streamController = StreamController();
  StreamSubscription<PrintData>? _streamSubscription;
  bool _stillListening = false;

  PrinterRepositoryImpl(){
    _listenPrintToDevice();
  }

  @override
  Future<bool> startPrintToAllConnectedDevice(PrintData data) async {
    bool isCompletedPrinted = false;
    // TODO: implement startPrintToAllConnectedDevice
    try{
      _stillListening = true;
      if(_streamController.isClosed){
        _streamController = StreamController();
      }
      _streamController.add(data);
      _streamSubscription?.onDone(() {
        isCompletedPrinted = true;
      });
      _streamSubscription?.onError((e){
        isCompletedPrinted = false;
      });
      return isCompletedPrinted;
    }catch(e){
      debugPrint("$e");
      rethrow;
    }
  }

  void _listenPrintToDevice(){
    final localStrem = _streamController.stream;
    _streamSubscription = localStrem.listen((event) async {
      _stillListening = true;
      _streamSubscription?.pause();
      var printerDevice = PrinterDeviceFactory.createPrinterDevice(connectionType: event.connectionType);
      Timer.periodic(const Duration(seconds: 1), (timer) async {
       if(!printerDevice.stillPrinting){
         await printerDevice.printToDevice(event).catchError((error) async {
           if(error == "errorByConnection"){
             await printerDevice.printToDevice(event);
           }
         });
         timer.cancel();
       }
      });
      _stillListening = false;
      _streamSubscription?.resume();
    }, onError: (err) => debugPrint(err),
       onDone: () => _streamSubscription?.cancel()
    );

    Timer.periodic(const Duration(minutes: 1), (timer) {
      if(!_stillListening){
        _streamController.close();
        timer.cancel();
      }
    });
  }


}
