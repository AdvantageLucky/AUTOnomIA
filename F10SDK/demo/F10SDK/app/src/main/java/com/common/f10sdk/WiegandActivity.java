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

public class WiegandActivity extends AppCompatActivity {

    PosUtil posutil;
    TextView tv_receive,title_tv;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_wiegand);

        tv_receive = findViewById(R.id.tv_receive);
        title_tv = findViewById(R.id.title_tv);
        title_tv.setText("Wiegand Test");

        posutil = new PosUtil(this);//构造函数,传入Context
        posutil.registerBroadcastWiegandInput();//注册广播
        posutil.getWiegandInput(new PosUtil.WiegandInputListener() {//监听韦根输入

            @Override
            public void wiegandInput(byte[] inputData) {
                // TODO Auto-generated method stub
                //韦根输入的数据:inputData
                Log.e("wiegandInput",inputData.length+"-"+ toHexString(inputData)+"-"+bin2hex(toHexString(inputData)));
                String data = toHexString(inputData);
                tv_receive.setText("Receive:\n" +bin2hex(data));
            }
        });

    }

    public void onwiegandclick(View view) {
        int ret = -1;
        switch (view.getId()){
            case R.id.wiegand_26:
                long cardnum = 12345678;
                ret = PosUtil.getWg26Status(cardnum);
                if(ret==0) {
                    Toast.makeText(WiegandActivity.this, "send WG26 success!", Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(WiegandActivity.this, "send WG26 failed!", Toast.LENGTH_SHORT).show();
                }
                break;
            case R.id.wiegand_34:
                long cardnum2 = 1234567812;
                ret = PosUtil.getWg34Status(cardnum2);
                if(ret==0) {
                    Toast.makeText(WiegandActivity.this, "send WG34 success!", Toast.LENGTH_SHORT).show();
                }else{
                    Toast.makeText(WiegandActivity.this, "send WG34 failed!", Toast.LENGTH_SHORT).show();
                }
                break;
        }
    }

    public static String bin2hex(String input) {
        StringBuilder sb = new StringBuilder();
        int len = input.length();

        for (int i = 0; i < len / 4; i++) {
            //每4个二进制位转换为1个十六进制位
            String temp = input.substring(i * 4, (i + 1) * 4);
            int tempInt = Integer.parseInt(temp, 2);
            String tempHex = Integer.toHexString(tempInt).toUpperCase();
            sb.append(tempHex);
        }

        return sb.toString();
    }

    //输出字节数组的16进制字符串
    public static String toHexString(byte[] data) {
        if (data == null) {
            return "";
        }
        String string;
        StringBuilder stringBuilder = new StringBuilder();
        for (int i = 1; i < data.length-1; i++) {
            string = Integer.toHexString(data[i] & 0xFF);
            stringBuilder.append(string.toUpperCase());
        }
        return stringBuilder.toString();
    }

    @Override
    protected void onDestroy() {
        posutil.unRegisterBroadcastWiegandInput();//调用结束时,注销广播
        super.onDestroy();
    }
}
