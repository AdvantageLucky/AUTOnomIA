package com.common.f10sdk;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import com.common.pos.api.util.PosUtil;
import com.common.pos.api.util.ShellUtils;

public class LedActivity extends AppCompatActivity {

    SeekBar seekbarR, seekbarG, seekbarB, seekbarW;
    int r, g, b, w;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_led);

        TextView title_tv = findViewById(R.id.title_tv);
        title_tv.setText("Led Test");

        seekbarR = (SeekBar) findViewById(R.id.seekbarR);
        seekbarR.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, final int progress, boolean fromUser) {
                // 当拖动条的滑块位置发生改变时触发该方法,在这里直接使用参数progress，即当前滑块代表的进度值
                new Thread(new Runnable() {
                    public void run() {
                        r = progress;
                        PosUtil.controlLedBright(0, r);
                    }
                }).start();
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });

        seekbarG = (SeekBar) findViewById(R.id.seekbarG);
        seekbarG.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, final int progress, boolean fromUser) {
                // 当拖动条的滑块位置发生改变时触发该方法,在这里直接使用参数progress，即当前滑块代表的进度值
                new Thread(new Runnable() {
                    public void run() {
                        g = progress;
                        PosUtil.controlLedBright(1, g);
                    }
                }).start();
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });

        seekbarB = (SeekBar) findViewById(R.id.seekbarB);
        seekbarB.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, final int progress, boolean fromUser) {
                // 当拖动条的滑块位置发生改变时触发该方法,在这里直接使用参数progress，即当前滑块代表的进度值
                new Thread(new Runnable() {
                    public void run() {
                        b = progress;
                        PosUtil.controlLedBright(2, b);
                    }
                }).start();
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });

        seekbarW = (SeekBar) findViewById(R.id.seekbarW);
        seekbarW.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, final int progress, boolean fromUser) {
                // 当拖动条的滑块位置发生改变时触发该方法,在这里直接使用参数progress，即当前滑块代表的进度值
                new Thread(new Runnable() {
                    public void run() {
                        w = progress;
                        PosUtil.controlLedBright(3, w);
                    }
                }).start();
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });

    }

    public void closeAllControl(View view){
        PosUtil.controlLedBright(4, 1);
        seekbarR.setProgress(0);
        seekbarG.setProgress(0);
        seekbarB.setProgress(0);
        seekbarW.setProgress(0);
    }

}
