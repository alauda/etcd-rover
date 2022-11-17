resource etcd {
protocol C;
on host1-need-config {
                device /dev/drbd0;
                disk disk1-need-config;
                address ip1-need-config:7788;
                meta-disk internal;
     }
on host2-need-config {
                device /dev/drbd0;
                disk disk2-need-config;
                address ip2-need-config:7788;
                meta-disk internal;
     }
}