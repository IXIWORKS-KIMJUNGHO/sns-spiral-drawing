package com.mangoslab.nemonicsdk.nemonic_sdk;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Handler;
import android.os.Looper;

import com.mangoslab.nemonicsdk.constants.NBatteryStatus;
import com.mangoslab.nemonicsdk.constants.NCartridgeType;
import com.mangoslab.nemonicsdk.constants.NConnectState;
import com.mangoslab.nemonicsdk.constants.NPrinterType;
import com.mangoslab.nemonicsdk.constants.NResult;
import com.mangoslab.nemonicsdk.constants.NResultString;
import com.mangoslab.nemonicsdk.INPrinterControllerCallback;
import com.mangoslab.nemonicsdk.NPrinter;
import com.mangoslab.nemonicsdk.NPrinterController;
import com.mangoslab.nemonicsdk.NPrintInfo;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class NemonicSdkController implements INPrinterControllerCallback {
    private static final String TAG = "NemonicSdkController";
    private MethodChannel channel;
    private NPrinterController printerController;

    public NemonicSdkController(MethodChannel channel, Context context) {
        this.channel = channel;
        printerController = new NPrinterController(context, this);
    }

    public int getDefaultConnectDelay() {
        return printerController.getDefaultConnectDelay();
    }

    public int getConnectDelay() {
        return printerController.getConnectDelay();
    }

    public void setConnectDelay(int msec) {
        printerController.setConnectDelay(msec);
    }

    public int connect(NPrinter printer) {
        return printerController.connect(printer);
    }

    public void disconnect() {
        printerController.disconnect();
    }

    public int getConnectState() {
        return printerController.getConnectState();
    }

    public void cancel() {
        printerController.cancel();
    }

    public void setPrintTimeout(boolean enableAuto, int manualTimeout) {
        printerController.setPrintTimeout(enableAuto, manualTimeout);
    }

    public int print(NPrintInfo printInfo) {
        return printerController.print(printInfo);
    }

    public int setTemplate(Bitmap image, boolean withPrint, boolean enableDither) {
        return printerController.setTemplate(image, withPrint, enableDither);
    }

    public int clearTemplate() {
        return printerController.clearTemplate();
    }

    public int getPrinterStatus() {
        return printerController.getPrinterStatus();
    }

    public int getCartridgeType() {
        return printerController.getCartridgeType();
    }

    public NResultString getPrinterName() {
        return printerController.getPrinterName();
    }

    public int getBatteryLevel() {
        return printerController.getBatteryLevel();
    }

    public int getBatteryStatus() {
        return printerController.getBatteryStatus();
    }

    @Override
    public void disconnected() {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod("disconnected", null);
            }
        });
    }

    @Override
    public void printProgress(int index, int total, int result) {
        Map<String, Object> data = new HashMap<String, Object>();
        data.put("index", index);
        data.put("total", total);
        data.put("result", result);

        // channel.invokeMethod("printProgress", data);
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod("printProgress", data);
            }
        });
    }

    @Override
    public void printComplete(int result) {
        Map<String, Object> data = new HashMap<String, Object>();
        data.put("result", result);

        // channel.invokeMethod("printComplete", data);
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod("printComplete", data);
            }
        });
    }
}
