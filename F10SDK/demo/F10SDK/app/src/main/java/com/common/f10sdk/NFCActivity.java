package com.common.f10sdk;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.nfc.NfcAdapter;
import android.nfc.NfcManager;
import android.nfc.Tag;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.common.pos.api.util.Utils;

public class NFCActivity extends AppCompatActivity {

    private TextView show_nfc_message;
    private NfcAdapter mNfcAdapter;
    private PendingIntent mPendingIntent;
    private String mIDString;
    TextView title_tv;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_nfc);

        initUI();
        NfcManager mNfcManager = (NfcManager) getSystemService(Context.NFC_SERVICE);
        mNfcAdapter = mNfcManager.getDefaultAdapter();
        if (mNfcAdapter == null) {
            show_nfc_message.setText(R.string.tv_nfc_notsupport);
        } else if ((mNfcAdapter != null) && (!mNfcAdapter.isEnabled())) {
            show_nfc_message.setText(R.string.tv_nfc_notwork);
        } else if ((mNfcAdapter != null) && (mNfcAdapter.isEnabled())) {
            show_nfc_message.setText(R.string.tv_nfc_working);
        }
        mPendingIntent = PendingIntent.getActivity(this, 0, new Intent(this, getClass()), 0);
        init_NFC();
    }

    private void initUI() {
        show_nfc_message = (TextView) findViewById(R.id.show_nfc_message);
        title_tv = findViewById(R.id.title_tv);
        title_tv.setText("NFC Test");

    }

    @Override
    public void onResume() {
        super.onResume();
        if (mNfcAdapter != null) {
            mNfcAdapter.enableForegroundDispatch(this, mPendingIntent, null, null);
            if (NfcAdapter.ACTION_TECH_DISCOVERED.equals(this.getIntent().getAction())) {
                processIntent(this.getIntent());
            }
        }
    }

    @Override
    public void onNewIntent(Intent intent) {
        processIntent(intent);
        super.onNewIntent(intent);
    }

    public void processIntent(Intent intent) {
        String data = null;
        Tag tag = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG);
        String[] techList = tag.getTechList();
        byte[] ID = new byte[20];
        data = tag.toString();
        ID = tag.getId();
        String UID = Utils.toHexString(ID);
        String IDString = bytearray2Str(hexStringToBytes(UID.substring(2, UID.length())), 0, 4, 10);
        mIDString = IDString;
        data += "\n\nUID:\n" + UID;
        data += "\n\nID:\n" + IDString;
        data += "\nData format:";
        for (String tech : techList) {
            data += "\n" + tech;
        }
        /*data += "\nwg26status:-->" + PosUtil.getWg26Status(Long.parseLong(IDString)) + "\n";
        data += "wg34status:-->" + PosUtil.getWg34Status(Long.parseLong(IDString)) + "\n";
        data += "wg32status:-->" + PosUtil.getWg32Status(Long.parseLong(IDString)) + "\n";*/
        show_nfc_message.setText(data);
    }

    @Override
    public void onPause() {
        super.onPause();
        if (mNfcAdapter != null) {
            stopNFC_Listener();
        }
    }

    private void init_NFC() {
        IntentFilter tagDetected = new IntentFilter(NfcAdapter.ACTION_TECH_DISCOVERED);
        tagDetected.addCategory(Intent.CATEGORY_DEFAULT);
    }

    private void stopNFC_Listener() {
        mNfcAdapter.disableForegroundDispatch(this);
    }


    private static byte[] hexStringToBytes(String hexString) {
        if (hexString == null || hexString.equals("")) {
            return null;
        }
        hexString = hexString.toUpperCase();
        int length = hexString.length() / 2;
        char[] hexChars = hexString.toCharArray();
        byte[] d = new byte[length];
        for (int i = 0; i < length; i++) {
            int pos = i * 2;
            d[i] = (byte) (charToByte(hexChars[pos]) << 4 | charToByte(hexChars[pos + 1]));
        }
        return d;
    }

    private static byte charToByte(char c) {
        return (byte) "0123456789ABCDEF".indexOf(c);
    }

    private static String bytearray2Str(byte[] data, int start, int length, int targetLength) {
        long number = 0;
        if (data.length < start + length) {
            return "";
        }
        for (int i = 1; i <= length; i++) {
            number *= 0x100;
            number += (data[start + length - i] & 0xFF);
        }
        return String.format("%0" + targetLength + "d", number);
    }

}
