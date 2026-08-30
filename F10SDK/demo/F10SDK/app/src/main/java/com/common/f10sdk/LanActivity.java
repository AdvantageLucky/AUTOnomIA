package com.common.f10sdk;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.Toast;

import com.common.pos.api.util.PosUtil;

public class LanActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_lan);

        TextView title_tv = findViewById(R.id.title_tv);
        title_tv.setText("Lan Test");
    }

    public void onlanclick(View view) {
        int ret = -1;
        switch (view.getId()){
            case R.id.lan_open:
                ret = PosUtil.setLanPower(1);//1-5
                Log.e("ret---",ret+"");
                if(ret==0){
                    Toast.makeText(LanActivity.this,"Lan power on success!",Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(LanActivity.this,"Lan power on failed!",Toast.LENGTH_SHORT).show();
                }
                break;
            case R.id.lan_close:
                ret = PosUtil.setLanPower(0);
                Log.e("ret---",ret+"");
                if(ret==0){
                    Toast.makeText(LanActivity.this,"Lan power off success!",Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(LanActivity.this,"Lan power off failed!",Toast.LENGTH_SHORT).show();
                }
                break;
        }
    }

}