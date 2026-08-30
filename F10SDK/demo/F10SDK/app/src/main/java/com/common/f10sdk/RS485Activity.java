package com.common.f10sdk;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.Toast;

import com.common.pos.api.util.PosUtil;

public class RS485Activity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_rs485);

        TextView title_tv = findViewById(R.id.title_tv);
        title_tv.setText("RS485 Test");
    }

    public void onrs485click(View view) {
        int ret = -1;
        switch (view.getId()) {
            case R.id.rs485_send:
                ret = PosUtil.setRs485Status(1);
                if(ret==0) {
                    Toast.makeText(RS485Activity.this, "switch to send mode success!", Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(RS485Activity.this, "switch to send mode failed!", Toast.LENGTH_SHORT).show();
                }
                break;
            case R.id.rs485_receive:
                ret = PosUtil.setRs485Status(0);
                if(ret==0) {
                    Toast.makeText(RS485Activity.this, "switch to receive mode success!", Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(RS485Activity.this, "switch to receive mode failed!", Toast.LENGTH_SHORT).show();
                }
                break;
        }
    }
}
