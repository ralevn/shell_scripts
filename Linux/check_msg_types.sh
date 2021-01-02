awk '{msg_type[$5] ++} END {for (mt in msg_type) print mt,msg_type[mt]}' /var/log/messages|sort -nk 2


