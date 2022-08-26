package com.majoo.`package`.printer_controller

import android.annotation.TargetApi
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.BitmapFactory
import android.hardware.usb.*
import android.os.Build
import android.util.Log
import android.widget.Toast
import java.nio.charset.Charset
import java.util.ArrayList
import java.util.HashMap


@TargetApi(Build.VERSION_CODES.HONEYCOMB_MR1)
class UsbPrintHelper{

    private val LOG_TAG = "USB Printer"
    private var mContext: Context? = null
    private var mUSBManager: UsbManager? = null
    private var mPermissionIndent: PendingIntent? = null
    private var mUsbDevice: UsbDevice? = null
    private var mUsbDeviceConnection: UsbDeviceConnection? = null
    private var mUsbInterface: UsbInterface? = null
    private var mEndPoint: UsbEndpoint? = null
    private var usbPrintCommand: UsbPrintCommand = UsbPrintCommand()
    private var STATUS_USB_ATTACHED = "attached"
    private var STATUS_USB_DETACHED = "detached"

    private val mUsbDeviceReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.getAction()
            if (ACTION_USB_PERMISSION == action) {
                synchronized(this) {
                    val usbDevice: UsbDevice = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)!!
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        Log.i(
                            LOG_TAG,
                            "Success to grant permission for device " + usbDevice.getDeviceId() + ", vendor_id: " + usbDevice.getVendorId() + " product_id: " + usbDevice.getProductId()
                        )
                        mUsbDevice = usbDevice
                    } else {
                        Toast.makeText(
                            context,
                            "User refused to give USB device permissions" + usbDevice.getDeviceName(),
                            Toast.LENGTH_LONG
                        ).show()
                    }
                }
            } else if (UsbManager.ACTION_USB_DEVICE_ATTACHED == action) {
                Toast.makeText(context, "USB device has been attached", Toast.LENGTH_LONG).show()
                synchronized(this) {
                    val usbDevice: UsbDevice = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)!!
                    mUsbDevice = usbDevice
                    val mapUsbDevice = generateUsbDevice(usbDevice)
                }
                openConnection()
            } else if (UsbManager.ACTION_USB_DEVICE_DETACHED == action) {
                if (mUsbDevice != null) {
                    Toast.makeText(context, "USB device has been turned off", Toast.LENGTH_LONG)
                        .show()
                    closeConnectionIfExists()
                }
            }
        }
    }

    val deviceList: List<UsbDevice>
        get() {
            if (mUSBManager == null) {
                Toast.makeText(
                    mContext,
                    "USB Manager is not initialized while get device list",
                    Toast.LENGTH_LONG
                ).show()
                return emptyList<UsbDevice>()
            }
            return ArrayList<UsbDevice>(mUSBManager!!.getDeviceList().values)
        }

    fun generateUsbDevice(device: UsbDevice): HashMap<String, String> {
        val deviceMap = HashMap<String, String>()
        deviceMap.put("name", device.deviceName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            deviceMap.put("manufacturer", if (device.manufacturerName != null) device.manufacturerName.toString() else "")
            deviceMap.put("product", if (device.productName != null) device.productName.toString() else "")
        }
        deviceMap.put("deviceid", Integer.toString(device.deviceId))
        deviceMap.put("vendorid", Integer.toString(device.vendorId))
        deviceMap.put("productid", Integer.toString(device.productId))
        return deviceMap
    }

    fun init(reactContext: Context) {
        this.mContext = reactContext
        this.mUSBManager = this.mContext!!.getSystemService(Context.USB_SERVICE) as UsbManager
        this.mPermissionIndent =
            PendingIntent.getBroadcast(mContext, 0, Intent(ACTION_USB_PERMISSION), PendingIntent.FLAG_MUTABLE)
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        mContext!!.registerReceiver(mUsbDeviceReceiver, filter)
        Log.v(LOG_TAG, "ESC POS Printer initialized")
    }


    fun closeConnectionIfExists() {
        if (mUsbDeviceConnection != null) {
            mUsbDeviceConnection!!.releaseInterface(mUsbInterface)
            mUsbDeviceConnection!!.close()
            mUsbInterface = null
            mEndPoint = null
            mUsbDeviceConnection = null
        }
    }

    fun selectDevice(vendorId: Int?, productId: Int?): Boolean {

        if (mUsbDevice == null || mUsbDevice!!.getVendorId() != vendorId || mUsbDevice!!.getProductId() != productId) {
            closeConnectionIfExists()
            val usbDevices = deviceList
            for (usbDevice in usbDevices) {
                if (usbDevice.getVendorId() == vendorId && usbDevice.getProductId() == productId) {
                    Log.v(
                        LOG_TAG,
                        "Request for device: vendor_id: " + usbDevice.getVendorId() + ", product_id: " + usbDevice.getProductId()
                    )
                    closeConnectionIfExists()
                    mUSBManager!!.requestPermission(usbDevice, mPermissionIndent)
                    return true
                }
            }
            return false
        }
        return true
    }

    fun openConnection(): Boolean {
        if (mUsbDevice == null) {
            Log.e(LOG_TAG, "USB Deivce is not initialized")
            return false
        }
        if (mUSBManager == null) {
            Log.e(LOG_TAG, "USB Manager is not initialized")
            return false
        }

        if (mUsbDeviceConnection != null) {
            Log.i(LOG_TAG, "USB Connection already connected")
            return true
        }

        val usbInterface = mUsbDevice!!.getInterface(0)
        for (i in 0 until usbInterface.getEndpointCount()) {
            val ep = usbInterface.getEndpoint(i)
            if (ep.getType() == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                if (ep.getDirection() == UsbConstants.USB_DIR_OUT) {
                    val usbDeviceConnection = mUSBManager!!.openDevice(mUsbDevice)
                    if (usbDeviceConnection == null) {
                        Log.e(LOG_TAG, "failed to open USB Connection")
                        return false
                    }
                    Toast.makeText(mContext, "Device connected", Toast.LENGTH_SHORT).show()
                    if (usbDeviceConnection!!.claimInterface(usbInterface, true)) {
                        mEndPoint = ep
                        mUsbInterface = usbInterface
                        mUsbDeviceConnection = usbDeviceConnection
                        return true
                    } else {
                        usbDeviceConnection!!.close()
                        Log.e(LOG_TAG, "failed to claim usb connection")
                        return false
                    }
                }
            }
        }
        return true
    }

    fun printText(text: String): Boolean {
        Log.v(LOG_TAG, "start to print text")
        val isConnected = openConnection()
        if (isConnected) {
            Log.v(LOG_TAG, "Connected to device")
            val byte = text.toByteArray(Charset.forName("UTF-8"))
            val format = byteArrayOf(0x1B.toByte(), 0x21.toByte(), 0x00.toByte())
            val ESC_ALIGN_CENTER = byteArrayOf(0x1b, 'a'.toByte(), 0x01)
            val b = mUsbDeviceConnection!!.bulkTransfer(
                mEndPoint,
                ESC_ALIGN_CENTER,
                ESC_ALIGN_CENTER.size,
                100000
            )
            val c = mUsbDeviceConnection!!.bulkTransfer(mEndPoint, format, format.size, 100000)
            val d = mUsbDeviceConnection!!.bulkTransfer(mEndPoint, byte, byte.size, 100000)
            Log.i(LOG_TAG, "Return Status: b-->$byte")
            return true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            return false
        }
    }

    fun printRawData(data: ByteArray?): Boolean {
        Log.v(LOG_TAG, "start to print raw data $data")
        val isConnected = openConnection()
        if (isConnected) {
            Log.v(LOG_TAG, "Connected to device")
            Thread(object : Runnable {
                override fun run() {
                    val d =
                        mUsbDeviceConnection!!.bulkTransfer(mEndPoint, data!!, data!!.size, 100000)
                    Log.i(LOG_TAG, "Return Status: $d")
                }
            }).start()
            return true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            return false
        }
    }

    fun printImage(imagePath: String, driver: String): Boolean {
        Log.v(
            LOG_TAG, "start to print image " +
                    " $imagePath"
        )
        val isConnected = openConnection()
        if (isConnected) {
            Log.v(LOG_TAG, "Connected to device image")
            try {
                val bmp = BitmapFactory.decodeFile(imagePath)
                if (bmp != null) {
                    val command = Utils.decodeBitmap(bmp, driver)

//                            val bytes = Base64.decode(command, Base64.DEFAULT)
                    val format = byteArrayOf(0x1B.toByte(), 0x21.toByte(), 0x00.toByte())
                    val ESC_ALIGN_CENTER = byteArrayOf(0x1b, 'a'.toByte(), 0x01)
                    val b = mUsbDeviceConnection!!.bulkTransfer(
                        mEndPoint,
                        ESC_ALIGN_CENTER,
                        ESC_ALIGN_CENTER.size,
                        100000
                    )
                    val c = mUsbDeviceConnection!!.bulkTransfer(
                        mEndPoint,
                        format,
                        format.size,
                        100000
                    )
                    val d = mUsbDeviceConnection!!.bulkTransfer(
                        mEndPoint,
                        command,
                        command.size,
                        100000
                    )
                    Log.i(LOG_TAG, "Return Status Image USB: $b")
                } else {
                    Log.e("Print Photo error", "the file isn't exists")
                    return false
                }
                return true
            } catch (ex: Exception) {
                Log.v(LOG_TAG, "failed to print image $ex")
                return false
            }
            return true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            return false
        }
    }

    fun printQRBarcode(qrPath: String, driver: String): Boolean {
        Log.v(
            LOG_TAG, "start to print image " +
                    " $qrPath"
        )
        val isConnected = openConnection()
        if (isConnected) {
            Log.v(LOG_TAG, "Connected to device image")
            try {
                val bmp = BitmapFactory.decodeFile(qrPath)
                if (bmp != null) {
                    val command = Utils.decodeBitmap(bmp, driver)
                    Thread(object : Runnable {
                        override fun run() {
//                            val bytes = Base64.decode(command, Base64.DEFAULT)
                            val format = byteArrayOf(0x1B.toByte(), 0x21.toByte(), 0x00.toByte())
                            val ESC_ALIGN_CENTER = byteArrayOf(0x1b, 'a'.toByte(), 0x01)
                            val b = mUsbDeviceConnection!!.bulkTransfer(
                                mEndPoint,
                                ESC_ALIGN_CENTER,
                                ESC_ALIGN_CENTER.size,
                                100000
                            )
                            val c = mUsbDeviceConnection!!.bulkTransfer(
                                mEndPoint,
                                format,
                                format.size,
                                100000
                            )
                            val d = mUsbDeviceConnection!!.bulkTransfer(
                                mEndPoint,
                                command,
                                command.size,
                                100000
                            )
                            Log.i(LOG_TAG, "Return Status Image USB: $b")
                        }
                    }).start()
                } else {
                    Log.e("Print Photo error", "the file isn't exists")
                    return false
                }
                return true
            } catch (ex: Exception) {
                Log.v(LOG_TAG, "failed to print image $ex")
                return false
            }
            return true
        } else {
            Log.v(LOG_TAG, "failed to connected to device")
            return false
        }
    }

    companion object {

        private var mInstance: UsbPrintHelper = UsbPrintHelper()

        //private static final String ACTION_USB_PERMISSION = "com.pinmi.react.USBPrinter.USB_PERMISSION";
        private val ACTION_USB_PERMISSION = "br.com.samhaus.escposprinter.USB_PERMISSION"

        val instance: UsbPrintHelper
            get() {
                if (mInstance == null) {
                    mInstance = UsbPrintHelper()
                }
                return mInstance
            }
    }
}