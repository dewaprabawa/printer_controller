package id.kakzaki.blue_thermal_printer;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.RectF;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;

public class BlueThermalPrinterPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, RequestPermissionsResultListener {

    private static final String TAG = "BThermalPrinterPlugin";
    private static final String NAMESPACE = "blue_thermal_printer";
    private static final int REQUEST_COARSE_LOCATION_PERMISSIONS = 1451;
    private static final UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");
    private static HashMap<String, ConnectedThread> THREAD = new HashMap<String, ConnectedThread>();
    private BluetoothAdapter mBluetoothAdapter;

    private Result pendingResult;

    private EventSink readSink;
    private EventSink statusSink;

    private FlutterPluginBinding pluginBinding;
    private ActivityPluginBinding activityBinding;
    private Object initializationLock = new Object();
    private Context context;
    private MethodChannel channel;

    private EventChannel stateChannel;
    private EventChannel readChannel;
    private BluetoothManager mBluetoothManager;

    private Application application;
    private Activity activity;

    public static void registerWith(Registrar registrar) {
        final BlueThermalPrinterPlugin instance = new BlueThermalPrinterPlugin();
        //registrar.addRequestPermissionsResultListener(instance);
        Activity activity = registrar.activity();
        Application application = null;
        instance.setup(registrar.messenger(), application, activity, registrar, null);

    }

    public BlueThermalPrinterPlugin() {
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        pluginBinding = binding;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        pluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activityBinding = binding;
        setup(
                pluginBinding.getBinaryMessenger(),
                (Application) pluginBinding.getApplicationContext(),
                activityBinding.getActivity(),
                null,
                activityBinding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        detach();
    }

    private void setup(
            final BinaryMessenger messenger,
            final Application application,
            final Activity activity,
            final PluginRegistry.Registrar registrar,
            final ActivityPluginBinding activityBinding) {
        synchronized (initializationLock) {
            Log.i(TAG, "setup");
            this.activity = activity;
            this.application = application;
            this.context = application;
            channel = new MethodChannel(messenger, NAMESPACE + "/methods");
            channel.setMethodCallHandler(this);
            stateChannel = new EventChannel(messenger, NAMESPACE + "/state");
            stateChannel.setStreamHandler(stateStreamHandler);
            readChannel = new EventChannel(messenger, NAMESPACE + "/state");
            readChannel.setStreamHandler(readResultsHandler);
            mBluetoothManager = (BluetoothManager) application.getSystemService(Context.BLUETOOTH_SERVICE);
            mBluetoothAdapter = mBluetoothManager.getAdapter();
            if (registrar != null) {
                // V1 embedding setup for activity listeners.
                registrar.addRequestPermissionsResultListener(this);
            } else {
                // V2 embedding setup for activity listeners.
                activityBinding.addRequestPermissionsResultListener(this);
            }
        }
    }


    private void detach() {
        Log.i(TAG, "detach");
        context = null;
        activityBinding.removeRequestPermissionsResultListener(this);
        activityBinding = null;
        channel.setMethodCallHandler(null);
        channel = null;
        stateChannel.setStreamHandler(null);
        stateChannel = null;
        mBluetoothAdapter = null;
        mBluetoothManager = null;
        application = null;
    }

    // MethodChannel.Result wrapper that responds on the platform thread.
    private static class MethodResultWrapper implements Result {
        private final Result methodResult;
        private final Handler handler;

        MethodResultWrapper(Result result) {
            methodResult = result;
            handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object result) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.success(result);
                }
            });
        }

        @Override
        public void error(final String errorCode, final String errorMessage, final Object errorDetails) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.error(errorCode, errorMessage, errorDetails);
                }
            });
        }

        @Override
        public void notImplemented() {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.notImplemented();
                }
            });
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result rawResult) {
        Result result = new MethodResultWrapper(rawResult);

        if (mBluetoothAdapter == null && !"isAvailable".equals(call.method)) {
            result.error("bluetooth_unavailable", "the device does not have bluetooth", null);
            return;
        }

        final Map<String, Object> arguments = call.arguments();

        switch (call.method) {

            case "isAvailable":
                result.success(mBluetoothAdapter != null);
                break;

            case "isOn":
                try {

                    assert mBluetoothAdapter != null;
                    result.success(mBluetoothAdapter.isEnabled());
                } catch (Exception ex) {
                    result.error("Error", ex.getMessage(), exceptionToString(ex));
                }
                break;

            case "isConnected":
                if (arguments.containsKey("address")) {
                    String address = (String) arguments.get("address");
                    result.success(THREAD != null && THREAD.get(address) != null);
                } else {
                    result.error("invalid_argument", "argument 'address' not found", null);
                }
                break;

            case "isDeviceConnected":
                if (arguments.containsKey("address")) {
                    String address = (String) arguments.get("address");
                    isDeviceConnected(result, address);
                } else {
                    result.error("invalid_argument", "argument 'address' not found", null);
                }
                break;

            case "openSettings":
                ContextCompat.startActivity(context, new Intent(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS),
                        null);
                result.success(true);
                break;

            case "getBondedDevices":
                try {

                    if (ContextCompat.checkSelfPermission(activity,
                            Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {

                        ActivityCompat.requestPermissions(activity,
                                new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, REQUEST_COARSE_LOCATION_PERMISSIONS);

                        pendingResult = result;
                        break;
                    }

                    getBondedDevices(result);

                } catch (Exception ex) {
                    result.error("Error", ex.getMessage(), exceptionToString(ex));
                }

                break;

            case "connect":
                if (arguments.containsKey("address")) {
                    String address = (String) arguments.get("address");
                    connect(result, address);
                } else {
                    result.error("invalid_argument", "argument 'address' not found", null);
                }
                break;

            case "disconnect":
                if (arguments.containsKey("address")) {
                    String address = (String) arguments.get("address");
                    disconnect(result, address);
                } else {
                    result.error("invalid_argument", "argument 'address' not found", null);
                }
                break;

            case "write":
                if (arguments.containsKey("message") && arguments.containsKey("message")) {
                    String address = (String) arguments.get("address");
                    String message = (String) arguments.get("message");
                    write(result, address, message);
                } else {
                    result.error("invalid_argument", "argument 'address' or 'message' not found", null);
                }
                break;

            case "writeBytes":
                if (arguments.containsKey("address") && arguments.containsKey("message")) {
                    String address = (String) arguments.get("address");
                    byte[] message = (byte[]) arguments.get("message");
                    writeBytes(result, address, message);
                } else {
                    result.error("invalid_argument", "argument 'address' not found", null);
                }
                break;

            case "printImage":
                if (arguments.containsKey("address") && arguments.containsKey("pathImage")) {
                    String address = (String) arguments.get("address");
                    String pathImage = (String) arguments.get("pathImage");
                    String driver = (String) arguments.get("driver");
                    int leftMargin = (int) arguments.get("leftMargin");
                    printImage(result, address, pathImage, leftMargin, driver);
                } else {
                    result.error("invalid_argument", "argument 'pathImage' or 'address' not found", null);
                }
                break;

            case "printNewLine":
                if (arguments.containsKey("address")) {
                    String address = (String) arguments.get("address");
                    printNewLine(result, address);
                } else {
                    result.error("invalid_argument", "argument 'address' not found", null);
                }

                break;

            case "paperCut":
                if (arguments.containsKey("address")) {
                    String address = (String) arguments.get("address");
                    writeBytes(result, address, PrinterCommands.FEED_PAPER_AND_CUT);
                } else {
                    result.error("invalid_argument", "argument 'address' or 'message' not found", null);
                }
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    /**
     * @param requestCode  requestCode
     * @param permissions  permissions
     * @param grantResults grantResults
     * @return boolean
     */
    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {

        if (requestCode == REQUEST_COARSE_LOCATION_PERMISSIONS) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                getBondedDevices(pendingResult);
            } else {
                pendingResult.error("no_permissions", "this plugin requires location permissions for scanning", null);
                pendingResult = null;
            }
            return true;
        }
        return false;
    }

    /**
     * @param result result
     */
    private void getBondedDevices(Result result) {

        List<Map<String, Object>> list = new ArrayList<>();

        for (BluetoothDevice device : mBluetoothAdapter.getBondedDevices()) {
            Map<String, Object> ret = new HashMap<>();
            ret.put("address", device.getAddress());
            ret.put("name", device.getName());
            ret.put("type", device.getType());
            list.add(ret);
        }

        result.success(list);
    }

    /**
     * @param result  result
     * @param address address
     */
    private void isDeviceConnected(Result result, String address) {

        AsyncTask.execute(() -> {
            try {
                BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(address);

                if (device == null) {
                    result.error("connect_error", "device not found", null);
                    return;
                }

                if (THREAD.isEmpty() || THREAD.get(address) == null) {
                    result.success(false);
                    return;
                }

                if (THREAD != null && device.ACTION_ACL_CONNECTED.equals(new Intent(BluetoothDevice.ACTION_ACL_CONNECTED).getAction())) {
                    result.success(true);
                } else {
                    THREAD.remove(address);
                    result.success(false);
                }
                return;

            } catch (Exception ex) {
                Log.e(TAG, ex.getMessage(), ex);
                result.error("connect_error", ex.getMessage(), exceptionToString(ex));
            }
        });
    }


    private String exceptionToString(Exception ex) {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        ex.printStackTrace(pw);
        return sw.toString();
    }

    /**
     * @param result  result
     * @param address address
     */
    private void connect(Result result, String address) {

        if (THREAD != null && THREAD.get(address) != null) {
            result.error("connect_error", "already connected", null);
            return;
        }
        AsyncTask.execute(() -> {
            try {
                BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(address);
                Log.d("address : ", "" + address);

                Method e3;
                BluetoothSocket socket = null;

                if (device == null) {
                    result.error("connect_error", "device not found", null);
                    return;
                }

                Log.d(TAG, "" + device.getUuids());

                if (device.getUuids() != null && device.getUuids().length > 0) {
                    socket = device.createRfcommSocketToServiceRecord(MY_UUID);
                    Log.d(TAG, "bener bener Pake UUID");
                } else {
                    // Reference:
                    // https://stackoverflow.com/questions/16457693/the-differences-between-createrfcommsockettoservicerecord-and-createrfcommsocket
                    // https://stackoverflow.com/questions/30813854/how-do-bluetooth-sdp-and-uuids-work-specifically-for-android
                    Log.d(TAG, "nggak pake uuid");
                    e3 = device.getClass().getMethod("createRfcommSocket", Integer.TYPE);
                    socket = (BluetoothSocket) e3.invoke(device, new Object[]{Integer.valueOf(1)});
                }

                if (socket == null) {
                    result.error("connect_error", "socket connection not established", null);
                    return;
                }

                // Cancel bt discovery, even though we didn't start it
                mBluetoothAdapter.cancelDiscovery();

                try {
                    Log.d(TAG, "Socket connecting");
                    socket.connect();
                    THREAD.put(address, new ConnectedThread(socket));
                    Log.d(TAG, "Socket connection : success");
                    THREAD.get(address).start();
                    result.success(true);
                } catch (Exception ex) {
                    try {
                        Log.e(TAG, ex.getMessage(), ex);
                        Log.d(TAG, "Using Socket 2 connection : connecting");
                        Method e4 = device.getClass().getMethod("createRfcommSocket", Integer.TYPE);
                        BluetoothSocket socket_2 = (BluetoothSocket) e4.invoke(device, new Object[]{Integer.valueOf(1)});

                        socket_2.connect();
                        THREAD.put(address, new ConnectedThread(socket_2));
                        Log.d(TAG, "Using Socket 2 connection : success");
                        THREAD.get(address).start();
                        result.success(true);
                    } catch (Exception exs) {
                        Log.e(TAG, exs.getMessage(), exs);
                        result.error("connect_error", exs.getMessage(), exceptionToString(exs));
                    }
                }
            } catch (Exception ex) {
                Log.e(TAG, ex.getMessage(), ex);
                result.error("connect_error", ex.getMessage(), exceptionToString(ex));
            }
        });
    }

    /**
     * @param result result
     */
    private void disconnect(Result result, String address) {

        if (THREAD.get(address) == null) {
            result.error("disconnection_error", "not connected", null);
            return;
        }
        AsyncTask.execute(() -> {
            try {
                THREAD.get(address).interrupt();
                THREAD.get(address).cancel();
                THREAD.remove(address);
            } catch (Exception ex) {
                Log.e(TAG, ex.getMessage(), ex);
                result.error("disconnection_error", ex.getMessage(), exceptionToString(ex));
            }
        });
    }

    /**
     * @param result result
     */
    private void reconnect(Result result, String address) throws Exception {

        if (THREAD.get(address) == null) {
            throw new Exception("address_not_found");
        }
        AsyncTask.execute(() -> {
            try {
                THREAD.get(address).interrupt();
                THREAD.get(address).cancel();
                THREAD.remove(address);

                connect(result, address);
            } catch (Exception ex) {
                Log.e(TAG, ex.getMessage(), ex);
                throw ex;
            }
        });
    }

    /**
     * @param result  result
     * @param message message
     */
    private void write(Result result, String address, String message) {
        if (THREAD == null) {
            result.error("write_error", "not connected", null);
            return;
        }

        try {
            THREAD.get(address).write(message.getBytes());
            result.success(true);
        } catch (Exception ex) {
            Log.e(TAG, ex.getMessage(), ex);
            result.error("write_error", ex.getMessage(), exceptionToString(ex));
        }
    }

    private void writeBytes(Result result, String address, byte[] message) {
        if (THREAD.get(address) == null) {
            result.error("write_error", "not connected", null);
            return;
        }

        try {
            if (message.length != 0) THREAD.get(address).write(message);
            result.success(true);
        } catch (IOException e) {
            try {
                reconnect(result, address);
            } catch (Exception ex) {
                Log.e(TAG, ex.getMessage(), ex);
                result.error("write_error", ex.getMessage(), exceptionToString(ex));
            }
        } catch (Exception ex) {
            Log.e(TAG, ex.getMessage(), ex);
            result.error("write_error", ex.getMessage(), exceptionToString(ex));
        }
    }

    private void printImage(Result result, String address, String pathImage, int leftMargin, String driver) {
        if (THREAD.get(address) == null) {
            result.error("write_error", "not connected", null);
            return;
        }

        try {
            Bitmap bmp = BitmapFactory.decodeFile(pathImage);
            if (bmp != null) {
                Bitmap newBmp = padImage(bmp, leftMargin);
                byte[] command = Utils.decodeBitmap(newBmp, driver);
                if (command != null) {
                    THREAD.get(address).write(PrinterCommands.ESC_ALIGN_CENTER);
                    THREAD.get(address).write(command);
                    THREAD.get(address).write(PrinterCommands.ESC_ALIGN_LEFT);
                }
            } else {
                Log.e("Print Photo error", "the file isn't exists");
            }
            result.success(true);
        } catch (Exception ex) {
            Log.e(TAG, ex.getMessage(), ex);
            result.error("write_error", ex.getMessage(), exceptionToString(ex));
        }
    }

    private void printNewLine(Result result, String address) {
        if (THREAD.get(address) == null) {
            result.error("write_error", "not connected", null);
            return;
        }

        try {
            THREAD.get(address).write(PrinterCommands.FEED_LINE);
            result.success(true);
        } catch (Exception ex) {
            Log.e(TAG, ex.getMessage(), ex);
            result.error("write_error", ex.getMessage(), exceptionToString(ex));
        }
    }

    private Bitmap padImage(Bitmap bmp, int leftMargin) {
        Bitmap newBmp;
        if (leftMargin > 0) {
            Matrix m = new Matrix();
            m.setRectToRect(new RectF(0, 0, bmp.getWidth(), bmp.getHeight()), new RectF(0, 0, 200, 200), Matrix.ScaleToFit.CENTER);
            bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), m, true);

            // Add left margin for imaging
            newBmp = Bitmap.createBitmap(bmp.getWidth() + leftMargin, bmp.getHeight(), Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(newBmp);
            canvas.drawARGB(255, 255, 255, 255);
            canvas.drawBitmap(bmp, leftMargin, 0, null);
        } else {
            newBmp = bmp;
        }
        return newBmp;
    }

    private class ConnectedThread extends Thread {
        private final BluetoothSocket mmSocket;
        private final InputStream inputStream;
        private final OutputStream outputStream;

        ConnectedThread(BluetoothSocket socket) {
            mmSocket = socket;
            InputStream tmpIn = null;
            OutputStream tmpOut = null;

            try {
                tmpIn = socket.getInputStream();
                tmpOut = socket.getOutputStream();
            } catch (IOException e) {
                e.printStackTrace();
            }
            inputStream = tmpIn;
            outputStream = tmpOut;
        }

        public void run() {
            byte[] buffer = new byte[1024];
            int bytes;
            while (true) {
                try {
                    inputStream.read(buffer);
                } catch (NullPointerException e) {
                    break;
                } catch (IOException e) {
                    break;
                }
            }
        }

        public void write(byte[] bytes) throws IOException, InterruptedException {
            try {
                outputStream.write(bytes);
                Thread.sleep(40);
            } catch (IOException | InterruptedException e) {
                e.printStackTrace();
                throw e;
            }
        }

        public void wait(int ms) {
            try {
                outputStream.wait(ms);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        public void cancel() {
            try {
                outputStream.flush();
                outputStream.close();

                inputStream.close();

                mmSocket.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }


    }

    private final StreamHandler stateStreamHandler = new StreamHandler() {

        private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                final String action = intent.getAction();

                Log.d(TAG, action);

                if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
                    THREAD.clear();
                    statusSink.success(intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1));
                } else if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
                    statusSink.success(1);
                } else if (BluetoothDevice.ACTION_ACL_DISCONNECTED.equals(action)) {
                    THREAD.clear();
                    statusSink.success(0);
                }
            }
        };

        @Override
        public void onListen(Object o, EventSink eventSink) {
            statusSink = eventSink;
            context.registerReceiver(mReceiver, new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED));

            context.registerReceiver(mReceiver, new IntentFilter(BluetoothDevice.ACTION_ACL_CONNECTED));

            context.registerReceiver(mReceiver, new IntentFilter(BluetoothDevice.ACTION_ACL_DISCONNECTED));
        }

        @Override
        public void onCancel(Object o) {
            statusSink = null;
            context.unregisterReceiver(mReceiver);
        }
    };

    private final StreamHandler readResultsHandler = new StreamHandler() {
        @Override
        public void onListen(Object o, EventSink eventSink) {
            readSink = eventSink;
        }

        @Override
        public void onCancel(Object o) {
            readSink = null;
        }
    };
}