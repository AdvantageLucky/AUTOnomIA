package com.common.f10sdk;

import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.common.pos.api.util.PosUtil;

public class RelayActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_relay);

        TextView title_tv = findViewById(R.id.title_tv);
        title_tv.setText("Relay Test");
    }

    public void onrelayclick(View view) {
        int ret = -1;
        switch (view.getId()){
            case R.id.relay_open:
                ret = PosUtil.setRelayPower(1);
                if(ret==0) {
                    Toast.makeText(RelayActivity.this, "open relay success!", Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(RelayActivity.this, "open relay failed!", Toast.LENGTH_SHORT).show();
                }
                break;
            case R.id.relay_close:
                ret = PosUtil.setRelayPower(0);
                if(ret==0) {
                    Toast.makeText(RelayActivity.this, "close relay success!", Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(RelayActivity.this, "close relay failed!", Toast.LENGTH_SHORT).show();
                }
                break;
        }
    }
}
