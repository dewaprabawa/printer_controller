package com.majoo.`package`.printer_controller

import android.os.Build
import android.util.Log
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.majoo.`package`.printer_controller.UsbPrintHelper
import java.util.ArrayList
import java.util.HashMap

/** PrinterControllerPlugin */
class PrinterControllerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private val TSC_COMMAND_CHANNEL = "com.klopos/tsc_command"
  private val USB_PRINTER_CHANNEL = "com.klopos/usb_printer"
  private lateinit var usbChannel : MethodChannel
  private  lateinit var usbPrintHelper: UsbPrintHelper


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    usbPrintHelper = UsbPrintHelper();
    usbChannel = MethodChannel(flutterPluginBinding.binaryMessenger, USB_PRINTER_CHANNEL)
    usbChannel.setMethodCallHandler(this)
  }


  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method.equals("getUSBDeviceList")) {
      Log.d("keadaan", "terpanggil")
      val usbDevices = usbPrintHelper.deviceList
      val list = ArrayList<HashMap<*, *>>()
      for (usbDevice in usbDevices) {
        val deviceMap = HashMap<String, String>()
        deviceMap.put("name", usbDevice.deviceName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          deviceMap.put("manufacturer", if (usbDevice.manufacturerName != null) usbDevice.manufacturerName.toString() else "")
          deviceMap.put("product", if (usbDevice.productName != null) usbDevice.productName.toString() else "")
        }
        deviceMap.put("deviceid", Integer.toString(usbDevice.deviceId))
        deviceMap.put("vendorid", Integer.toString(usbDevice.vendorId))
        deviceMap.put("productid", Integer.toString(usbDevice.productId))
        list.add(deviceMap)
      }
      result.success(list)
    } else if (call.method.equals("connectPrinter")) {
      val vendor = "" + call.argument("vendor")
      val product = "" + call.argument("product")
      if (!usbPrintHelper.selectDevice(vendor.toInt(), product.toInt())) {
        result.success(false)
      } else {
        result.success(true)
      }
    } else if (call.method.equals("closeConn")) {
      usbPrintHelper.closeConnectionIfExists()
      result.success(true)
    } else if (call.method.equals("printText")) {
      val text = "" + call.argument("text")
      usbPrintHelper.printText(text)
      result.success(true)
    } else if (call.method.equals("printRawData")) {
      val raw: ByteArray? = call.argument("raw")
      result.success(usbPrintHelper.printRawData(raw))
    } else if (call.method.equals("printImage")) {
      val text = "" + call.argument("text")
      val driver = "" + call.argument("driver")
      usbPrintHelper.printImage(text, driver)
      result.success(true)
    } else if (call.method.equals("printQRBarcode")) {
      val text = "" + call.argument("text")
      val driver = "" + call.argument("driver")
      usbPrintHelper.printQRBarcode(text, driver)
      result.success(true)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    usbChannel.setMethodCallHandler(null)
  }
}
