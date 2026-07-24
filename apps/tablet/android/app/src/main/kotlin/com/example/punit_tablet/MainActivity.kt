package com.example.punit_tablet

import android.Manifest
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import com.snbc.sdk.LabelPrinter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private var tvsPrinter: LabelPrinter? = null
    private var tvsConnected = false
    private var tvsSdkLoaded = false
    private var tscUsbConnection: UsbDeviceConnection? = null
    private var tscUsbInterface: UsbInterface? = null
    private var tscUsbEndpoint: UsbEndpoint? = null
    private var tscSerialPort: UsbSerialPort? = null
    private var tscConnected = false
    private var tscMode = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "punit.erp/bluetooth").setMethodCallHandler { call, result ->
            when (call.method) {
                "openBluetoothSettings" -> {
                    startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "punit.erp/tvs_printer").setMethodCallHandler { call, result ->
            when (call.method) {
                "pairedDevices" -> result.success(pairedBluetoothDevices())
                "connect" -> {
                    val mac = call.argument<String>("address") ?: ""
                    val language = call.argument<Int>("language") ?: PRINTER_LANGUAGE_BPLA
                    result.success(tvsConnect(mac, language))
                }
                "disconnect" -> {
                    result.success(tvsDisconnect())
                }
                "isConnected" -> result.success(tvsConnected)
                "printLabel" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    result.success(tvsPrintLabel(args))
                }
                "printRawTspl" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    result.success(tvsPrintRawTspl(args["tspl"]?.toString() ?: ""))
                }
                "printRawTsplBytes" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    val bytes = args["bytes"] as? ByteArray ?: ByteArray(0)
                    result.success(tvsPrintRawBytes(bytes))
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "punit.erp/tsc_printer").setMethodCallHandler { call, result ->
            when (call.method) {
                "devices" -> result.success(tscDevices())
                "connect" -> {
                    val id = call.argument<String>("id") ?: ""
                    val baudRate = call.argument<Int>("baudRate") ?: 9600
                    result.success(tscConnect(id, baudRate))
                }
                "disconnect" -> result.success(tscDisconnect())
                "isConnected" -> result.success(tscConnected)
                "printRawTspl" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    result.success(tscPrintRawTspl(args["tspl"]?.toString() ?: ""))
                }
                "printRawTsplBytes" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    val bytes = args["bytes"] as? ByteArray ?: ByteArray(0)
                    result.success(tscPrintRawBytes(bytes))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun tscDevices(): List<Map<String, String>> {
        val manager = getSystemService(Context.USB_SERVICE) as UsbManager
        val devices = mutableListOf<Map<String, String>>()
        manager.deviceList.values
            .sortedBy { it.deviceName }
            .forEach { device ->
                if (looksLikeUsbPrinter(device)) {
                    devices.add(
                        mapOf(
                            "id" to "tsc_usb:${device.deviceName}",
                            "name" to "[TSC USB] ${usbDisplayName(device)}",
                            "address" to device.deviceName
                        )
                    )
                }
            }

        UsbSerialProber.getDefaultProber().findAllDrivers(manager).forEach { driver ->
            val device = driver.device
            devices.add(
                mapOf(
                    "id" to "tsc_serial:${device.deviceName}",
                    "name" to "[TSC Serial] ${usbDisplayName(device)}",
                    "address" to device.deviceName
                )
            )
        }

        return devices.distinctBy { it["id"] }.sortedBy { it["name"]?.lowercase() ?: "" }
    }

    private fun tscConnect(id: String, baudRate: Int): Map<String, Any> {
        if (!id.startsWith("tsc_usb:") && !id.startsWith("tsc_serial:")) {
            return mapOf("ok" to false, "message" to "Select a TSC USB or TSC Serial printer.")
        }
        val manager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceName = id.substringAfter(":")
        val device = manager.deviceList.values.firstOrNull { it.deviceName == deviceName }
            ?: return mapOf("ok" to false, "message" to "USB printer not found. Reconnect USB OTG cable and refresh.")

        val permission = ensureUsbPermission(manager, device)
        if (!permission.first) {
            return mapOf("ok" to false, "message" to permission.second)
        }

        return try {
            tscDisconnect()
            if (id.startsWith("tsc_serial:")) {
                connectTscSerial(manager, device, baudRate)
            } else {
                connectTscUsb(manager, device)
            }
            tscConnected = true
            tscMode = if (id.startsWith("tsc_serial:")) "serial" else "usb"
            mapOf("ok" to true, "message" to "TSC ${tscMode.uppercase()} printer connected.")
        } catch (error: Throwable) {
            tscDisconnect()
            mapOf("ok" to false, "message" to (error.message ?: error.toString()))
        }
    }

    private fun connectTscUsb(manager: UsbManager, device: UsbDevice) {
        val connection = manager.openDevice(device)
            ?: throw IllegalStateException("Unable to open USB printer.")
        var chosenInterface: UsbInterface? = null
        var outEndpoint: UsbEndpoint? = null
        for (interfaceIndex in 0 until device.interfaceCount) {
            val iface = device.getInterface(interfaceIndex)
            for (endpointIndex in 0 until iface.endpointCount) {
                val endpoint = iface.getEndpoint(endpointIndex)
                if (endpoint.direction == UsbConstants.USB_DIR_OUT) {
                    chosenInterface = iface
                    outEndpoint = endpoint
                    break
                }
            }
            if (outEndpoint != null) break
        }
        val iface = chosenInterface ?: throw IllegalStateException("No USB printer interface found.")
        val endpoint = outEndpoint ?: throw IllegalStateException("No USB OUT endpoint found.")
        if (!connection.claimInterface(iface, true)) {
            connection.close()
            throw IllegalStateException("Unable to claim USB printer interface.")
        }
        tscUsbConnection = connection
        tscUsbInterface = iface
        tscUsbEndpoint = endpoint
    }

    private fun connectTscSerial(manager: UsbManager, device: UsbDevice, baudRate: Int) {
        val driver = UsbSerialProber.getDefaultProber().findAllDrivers(manager)
            .firstOrNull { it.device.deviceName == device.deviceName }
            ?: throw IllegalStateException("No supported USB serial driver found for this printer.")
        val connection = manager.openDevice(driver.device)
            ?: throw IllegalStateException("Unable to open serial printer.")
        val port = driver.ports.firstOrNull()
            ?: throw IllegalStateException("No serial port found.")
        port.open(connection)
        port.setParameters(baudRate, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
        tscSerialPort = port
        tscUsbConnection = connection
    }

    private fun tscDisconnect(): Boolean {
        return try {
            tscSerialPort?.close()
            tscSerialPort = null
            tscUsbInterface?.let { iface ->
                try {
                    tscUsbConnection?.releaseInterface(iface)
                } catch (_: Throwable) {
                }
            }
            tscUsbEndpoint = null
            tscUsbInterface = null
            tscUsbConnection?.close()
            tscUsbConnection = null
            tscConnected = false
            tscMode = ""
            true
        } catch (_: Throwable) {
            tscSerialPort = null
            tscUsbEndpoint = null
            tscUsbInterface = null
            tscUsbConnection = null
            tscConnected = false
            tscMode = ""
            false
        }
    }

    private fun tscPrintRawTspl(rawTspl: String): Map<String, Any> {
        return tscPrintRawBytes(rawTspl.toByteArray(Charsets.US_ASCII))
    }

    private fun tscPrintRawBytes(bytes: ByteArray): Map<String, Any> {
        if (!tscConnected) {
            return mapOf("ok" to false, "message" to "TSC printer is not connected.")
        }
        if (bytes.isEmpty()) {
            return mapOf("ok" to false, "message" to "No label command data was generated.")
        }

        return try {
            val serial = tscSerialPort
            if (serial != null) {
                serial.write(bytes, 5000)
            } else {
                val connection = tscUsbConnection ?: throw IllegalStateException("USB printer connection is closed.")
                val endpoint = tscUsbEndpoint ?: throw IllegalStateException("USB printer write endpoint is missing.")
                var offset = 0
                while (offset < bytes.size) {
                    val length = minOf(endpoint.maxPacketSize.coerceAtLeast(64), bytes.size - offset)
                    val sent = connection.bulkTransfer(endpoint, bytes, offset, length, 5000)
                    if (sent <= 0) {
                        throw IllegalStateException("USB write failed at byte $offset.")
                    }
                    offset += sent
                }
            }
            mapOf("ok" to true, "message" to "TSPL label sent to TSC $tscMode printer.")
        } catch (error: Throwable) {
            mapOf("ok" to false, "message" to (error.message ?: error.toString()))
        }
    }

    private fun ensureUsbPermission(manager: UsbManager, device: UsbDevice): Pair<Boolean, String> {
        if (manager.hasPermission(device)) {
            return true to "USB permission granted."
        }

        val action = "${packageName}.USB_PERMISSION"
        val latch = CountDownLatch(1)
        var granted = false
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != action) return
                val received = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                }
                if (received?.deviceName == device.deviceName) {
                    granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                    latch.countDown()
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, IntentFilter(action), Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, IntentFilter(action))
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val intent = PendingIntent.getBroadcast(this, 0, Intent(action), flags)
        manager.requestPermission(device, intent)
        latch.await(15, TimeUnit.SECONDS)
        try {
            unregisterReceiver(receiver)
        } catch (_: Throwable) {
        }

        return if (granted || manager.hasPermission(device)) {
            true to "USB permission granted."
        } else {
            false to "USB permission denied or timed out. Tap Connect again after allowing USB access."
        }
    }

    private fun looksLikeUsbPrinter(device: UsbDevice): Boolean {
        if (device.deviceClass == UsbConstants.USB_CLASS_PRINTER) return true
        for (index in 0 until device.interfaceCount) {
            if (device.getInterface(index).interfaceClass == UsbConstants.USB_CLASS_PRINTER) {
                return true
            }
        }
        val name = usbDisplayName(device).uppercase()
        return name.contains("TSC") || name.contains("TA-210") || name.contains("TA210") || name.contains("TA-244") || name.contains("TA244")
    }

    private fun usbDisplayName(device: UsbDevice): String {
        val manufacturer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) device.manufacturerName ?: "" else ""
        val product = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) device.productName ?: "" else ""
        val label = "$manufacturer $product".trim()
        return label.ifBlank {
            "USB ${device.vendorId.toString(16).uppercase()}:${device.productId.toString(16).uppercase()}"
        }
    }

    private fun pairedBluetoothDevices(): List<Map<String, String>> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
        ) {
            return emptyList()
        }

        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        return adapter.bondedDevices
            .map {
                mapOf(
                    "id" to it.address,
                    "name" to ((it.name ?: "").ifBlank { it.address }),
                    "address" to it.address
                )
            }
            .sortedBy { it["name"]?.lowercase() ?: "" }
    }

    private fun tvsConnect(mac: String, language: Int): Map<String, Any> {
        if (mac.isBlank()) {
            return mapOf("ok" to false, "code" to -1, "message" to "Missing printer MAC address.")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
        ) {
            return mapOf("ok" to false, "code" to -2, "message" to "Bluetooth connect permission is required.")
        }

        return try {
            ensureTvsSdkLoaded()
            tvsDisconnect()
            val printer = LabelPrinter()
            printer.SetPrintCharset("UTF-8")
            val code = printer.ConnectPrinter(PRINTER_PORT_BLUETOOTH, mac, language)
            tvsPrinter = printer
            tvsConnected = code == 0
            mapOf(
                "ok" to tvsConnected,
                "code" to code,
                "message" to if (tvsConnected) "TVS native printer connected." else "TVS native connect failed with code $code."
            )
        } catch (error: Throwable) {
            tvsPrinter = null
            tvsConnected = false
            mapOf("ok" to false, "code" to -3, "message" to (error.message ?: error.toString()))
        }
    }

    private fun tvsDisconnect(): Boolean {
        return try {
            tvsPrinter?.Disconnect()
            tvsPrinter = null
            tvsConnected = false
            true
        } catch (_: Throwable) {
            tvsPrinter = null
            tvsConnected = false
            false
        }
    }

    private fun tvsPrintLabel(args: Map<*, *>): Map<String, Any> {
        ensureTvsSdkLoaded()
        val printer = tvsPrinter
        if (!tvsConnected || printer == null) {
            return mapOf("ok" to false, "code" to -10, "message" to "TVS native printer is not connected.")
        }

        return try {
            val rawTspl = defaultLabelTspl(args)
            val rawBytes = rawTspl.toByteArray(Charsets.US_ASCII)
            var code = printer.WritePort(rawBytes, rawBytes.size)
            if (code == 0) {
                return mapOf("ok" to true, "code" to 0, "message" to "Default TVS label sent.")
            }

            code = printer.SetLabelSize(600, 600)
            if (code != 0) return failPrint(code, "SetLabelSize")
            printer.SetPrintDensity(10)
            printer.SetPrintSpeed(3)
            printer.SetPrintDirection(0)
            printer.SetEnglishFontName("P18", 0)

            val product = clean(args["product_name"]).ifBlank { "Product" }
            val serial = clean(args["serial_number"]).ifBlank { "PREVIEW" }
            val barcode = clean(args["barcode_value"]).ifBlank { serial }
            val unit = clean(args["unit"]).ifBlank { "kg" }
            code = printer.PrintText(35, 35, "P18", clean(args["company_name"]).ifBlank { "PUNIT ERP" }, 0, 1, 1, 0)
            if (code != 0) return failPrint(code, "PrintText company")
            code = printer.PrintText(35, 78, "P18", "SN: ${limit(serial, 28)}", 0, 1, 1, 0)
            if (code != 0) return failPrint(code, "PrintText serial")
            code = printer.PrintText(35, 125, "P18", limit(product, 18), 0, 2, 2, 0)
            if (code != 0) return failPrint(code, "PrintText product")
            code = printer.PrintText(35, 205, "P18", "Gross: ${weight(args["gross_weight"], unit)}", 0, 1, 1, 0)
            if (code != 0) return failPrint(code, "PrintText gross")
            code = printer.PrintText(300, 205, "P18", "Tare: ${weight(args["tare_weight"], unit)}", 0, 1, 1, 0)
            if (code != 0) return failPrint(code, "PrintText tare")
            code = printer.PrintText(35, 255, "P18", "Net ${weight(args["net_weight"], unit)}", 0, 2, 2, 0)
            if (code != 0) return failPrint(code, "PrintText net")
            val pieces = clean(args["piece_quantity"])
            if (pieces.isNotBlank()) {
                code = printer.PrintText(300, 268, "P18", "PCS: ${limit(pieces, 12)}", 0, 1, 1, 0)
                if (code != 0) return failPrint(code, "PrintText pcs")
            }

            for ((index, field) in dynamicFields(args).take(10).withIndex()) {
                val x = if (index % 2 == 0) 35 else 305
                val y = 318 + ((index / 2) * 35)
                code = printer.PrintText(x, y, "P18", "${limit(field.first, 9)}: ${limit(field.second, 15)}", 0, 1, 1, 0)
                if (code != 0) return failPrint(code, "PrintText field")
            }

            if (barcode.isNotBlank()) {
                printer.PrintBarcode1D(58, 498, BARCODE_TYPE_CODE128, 54, limit(barcode, 24), 0, 1, 2, 0)
                printer.PrintText(35, 565, "P18", limit(barcode, 32), 0, 1, 1, 0)
            }
            code = printer.PrintLabel(1, 1)
            if (code != 0) return failPrint(code, "PrintLabel")

            mapOf("ok" to true, "code" to 0, "message" to "Default label printed through TVS SDK.")
        } catch (error: Throwable) {
            mapOf("ok" to false, "code" to -11, "message" to (error.message ?: error.toString()))
        }
    }

    private fun tvsPrintRawTspl(rawTspl: String): Map<String, Any> {
        return tvsPrintRawBytes(rawTspl.toByteArray(Charsets.US_ASCII))
    }

    private fun tvsPrintRawBytes(bytes: ByteArray): Map<String, Any> {
        ensureTvsSdkLoaded()
        val printer = tvsPrinter
        if (!tvsConnected || printer == null) {
            return mapOf("ok" to false, "code" to -10, "message" to "TVS native printer is not connected.")
        }
        if (bytes.isEmpty()) {
            return mapOf("ok" to false, "code" to -12, "message" to "No label command data was generated.")
        }

        return try {
            val code = printer.WritePort(bytes, bytes.size)
            if (code == 0) {
                mapOf("ok" to true, "code" to 0, "message" to "Selected label template sent to TVS printer.")
            } else {
                failPrint(code, "WritePort template")
            }
        } catch (error: Throwable) {
            mapOf("ok" to false, "code" to -13, "message" to (error.message ?: error.toString()))
        }
    }

    private fun defaultLabelTspl(args: Map<*, *>): String {
        val product = clean(args["product_name"]).ifBlank { "Product" }
        val serial = clean(args["serial_number"]).ifBlank { "PREVIEW" }
        val barcode = clean(args["barcode_value"]).ifBlank { serial }
        val unit = clean(args["unit"]).ifBlank { "kg" }
        val lines = mutableListOf(
            "SIZE 75 mm,75 mm",
            "GAP 2 mm,0 mm",
            "DENSITY 10",
            "SPEED 3",
            "DIRECTION 1",
            "REFERENCE 0,0",
            "CODEPAGE UTF-8",
            "CLS",
            tsplText(34, 28, "3", 1, 1, clean(args["company_name"]).ifBlank { "PUNIT ERP" }),
            tsplText(34, 62, "3", 1, 1, "SN: ${limit(serial, 28)}"),
            tsplText(34, 100, "3", 2, 2, limit(product, 18))
        )
        lines.addAll(
            listOf(
                "BAR 34,172,526,2",
                tsplText(34, 190, "3", 1, 1, "Gross: ${weight(args["gross_weight"], unit)}"),
                tsplText(300, 190, "3", 1, 1, "Tare: ${weight(args["tare_weight"], unit)}"),
                tsplText(34, 228, "3", 2, 2, "Net ${weight(args["net_weight"], unit)}")
            )
        )
        val pieces = clean(args["piece_quantity"])
        if (pieces.isNotBlank()) {
            lines.add(tsplText(300, 240, "3", 1, 1, "PCS: ${limit(pieces, 12)}"))
        }
        lines.add("BAR 34,290,526,2")
        dynamicFields(args).take(10).forEachIndexed { index, field ->
            val x = if (index % 2 == 0) 34 else 304
            val y = 307 + ((index / 2) * 35)
            lines.add(tsplText(x, y, "1", 1, 1, "${limit(field.first, 9)}: ${limit(field.second, 15)}"))
        }
        if (barcode.isNotBlank()) {
            lines.add("BARCODE 58,498,\"128\",54,1,0,1,2,\"${limit(barcode, 24)}\"")
            lines.add(tsplText(34, 562, "1", 1, 1, limit(barcode, 32)))
        }
        lines.add("PRINT 1,1")
        lines.add("")
        return lines.joinToString("\r\n") + "\r\n"
    }

    private fun failPrint(code: Int, step: String): Map<String, Any> {
        return mapOf("ok" to false, "code" to code, "message" to "$step failed with code $code.")
    }

    private fun ensureTvsSdkLoaded() {
        if (tvsSdkLoaded) return
        val nativeDir = applicationInfo.nativeLibraryDir
        val dependencies = listOf(
            "libc++_shared.so",
            "libConfigFileINI.so",
            "libSimpleLogModule.so"
        )
        for (name in dependencies) {
            try {
                System.load("$nativeDir/$name")
            } catch (_: Throwable) {
                // Android may already load dependency libraries. The required JNI
                // entry points live in libLabelPrinterSDK.so below.
            }
        }

        try {
            LabelPrinter.LoadLibrary("$nativeDir/libLabelPrinterSDK.so", true)
        } catch (error: Throwable) {
            try {
                LabelPrinter.LoadLibrary("LabelPrinterSDK")
            } catch (fallback: Throwable) {
                throw IllegalStateException(
                    "TVS SDK native library load failed: ${fallback.message ?: error.message}",
                    fallback
                )
            }
        }
        tvsSdkLoaded = true
    }

    private fun clean(value: Any?): String {
        if (value == null) return ""
        return value.toString().replace("\"", "").replace("\n", " ").replace("\r", " ").trim()
    }

    private fun weight(value: Any?, unit: Any?): String {
        if (value == null) return ""
        val number = value.toString().toDoubleOrNull()
        val text = if (number == null) value.toString() else "%.3f".format(number)
        return "$text ${unit ?: "kg"}"
    }

    private fun dynamicFields(args: Map<*, *>): List<Pair<String, String>> {
        val values = args["dynamic_values"] as? Map<*, *> ?: return emptyList()
        return values.mapNotNull { (key, value) ->
            val cleanValue = clean(value)
            if (cleanValue.isBlank()) {
                null
            } else {
                clean(key).replace("_", " ").uppercase() to cleanValue
            }
        }
    }

    private fun tsplText(x: Int, y: Int, font: String, xMul: Int, yMul: Int, value: String): String {
        return "TEXT $x,$y,\"$font\",0,$xMul,$yMul,\"${tsplEscape(value)}\""
    }

    private fun tsplEscape(value: String): String {
        return value.replace("\"", "").replace("\\", "/")
    }

    private fun limit(value: String, max: Int): String {
        return if (value.length <= max) value else value.substring(0, max)
    }

    companion object {
        private const val PRINTER_PORT_BLUETOOTH = 7
        private const val PRINTER_LANGUAGE_BPLA = 6
        private const val BARCODE_TYPE_CODE128 = 1
    }
}
