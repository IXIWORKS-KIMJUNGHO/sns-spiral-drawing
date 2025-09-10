package com.mangoslab.nemonicsdk.nemonic_sdk;

import android.content.Context;
import android.util.Log;

import com.mangoslab.nemonicsdk.INPrinterScanControllerCallback;
import com.mangoslab.nemonicsdk.NPrinter;
import com.mangoslab.nemonicsdk.NPrinterScanController;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class NemonicSdkScanController implements INPrinterScanControllerCallback {
    private static final String TAG = "NemonicSdkScanController";
    private MethodChannel channel;
    private NPrinterScanController printerScanController;

    public NemonicSdkScanController(MethodChannel channel, Context context) {
        this.channel = channel;
        printerScanController = new NPrinterScanController(context, this);
    }

    public int startScan() {
        return printerScanController.startScan();
    }

    public void stopScan() {
        printerScanController.stopScan();
    }

    @Override
    public void deviceFound(NPrinter printer) {
        // Log.d(TAG, "deviceFound name = %s", printer.getName());
        Map<String, Object> data = new HashMap<String, Object>();

        data.put("name", printer.getName());
        data.put("macAddress", printer.getMacAddress());
        data.put("type", printer.getType().getValue());

        channel.invokeMethod("deviceFound", data);
    }
}
