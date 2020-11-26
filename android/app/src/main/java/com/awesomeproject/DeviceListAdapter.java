package com.awesomeproject;


import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.awesomeproject.R;
import uk.co.etiltd.thermalib.Device;

class DeviceListAdapter extends BaseAdapter {
    private Set<ListedDeviceViewHolder> mViewHolders = new HashSet<>();
    private final List<Device> mDeviceList;
    private final Context mContext;

    DeviceListAdapter(Context context, List<Device> deviceList) {
        mDeviceList = deviceList;
        mContext = context;
    }

    @Override
    public int getCount() {
        return mDeviceList.size();
    }

    @Override
    public Object getItem(int pos) {
        return mDeviceList.get(pos);
    }

    @Override
    public long getItemId(int pos) {
        return 0;
    }

    @Override
    public View getView(int pos, View recycledView, ViewGroup viewGroup) {
        View view = recycledView;
        Device device = mDeviceList.get(pos);
        ListedDeviceViewHolder viewHolder;

        if (view == null) {
            view = View.inflate(mContext, R.layout.listed_device_layout, null);
            viewHolder = new ListedDeviceViewHolder(view);
            mViewHolders.add(viewHolder);
            view.setTag(viewHolder);
        } else {
            viewHolder = (ListedDeviceViewHolder) view.getTag();
        }
        viewHolder.setDevice(device);
        viewHolder.setFields();
        return view;
    }

    private ListedDeviceViewHolder findViewHolderForDevice(Device device) {
        ListedDeviceViewHolder ans = null;
        for (ListedDeviceViewHolder holder : mViewHolders) {
            if (device == holder.getDevice()) {
                ans = holder;
                break;
            }
        }
        return ans;
    }

    void setFieldsForDevice(Device device) {
        ListedDeviceViewHolder viewHolder = findViewHolderForDevice(device);
        if (viewHolder != null) {
            viewHolder.setFields();
        }
    }


}