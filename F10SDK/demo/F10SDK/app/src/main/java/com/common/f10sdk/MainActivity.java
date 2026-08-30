package com.common.f10sdk;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_main);

        TextView textView=findViewById(R.id.title_tv_version);
        textView.setText("20220623");
    }

    public void onclick(View view) {
        switch (view.getId()){
            case R.id.bt_lan:
                startActivity(new Intent(MainActivity.this, LanActivity.class));
                break;
            case R.id.bt_relay:
                startActivity(new Intent(MainActivity.this, RelayActivity.class));
                break;
            case R.id.bt_rs485:
                startActivity(new Intent(MainActivity.this, RS485Activity.class));
                break;
            case R.id.bt_led:
                startActivity(new Intent(MainActivity.this, LedActivity.class));
                break;
            case R.id.bt_nfc:
                startActivity(new Intent(MainActivity.this, NFCActivity.class));
                break;
            case R.id.bt_wiegand:
                startActivity(new Intent(MainActivity.this, WiegandActivity.class));
                break;
        }
    }
}
