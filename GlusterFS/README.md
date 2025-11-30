# GlusterFS Setup Guide

Hướng dẫn cài đặt và cấu hình GlusterFS trên các node trong Docker Swarm.

## 1. Cài đặt GlusterFS

Trên mỗi node trong Swarm:

```bash
sudo apt update
sudo apt install glusterfs-server
```

## 2. Tạo cụm GlusterFS

Kết nối các node với nhau (Peer Probe):

```bash
sudo gluster peer probe <IP_node_B>
```

Kiểm tra trạng thái:

```bash
sudo gluster peer status
```

## 3. Tạo và cấu hình Volume

Trên một node (ví dụ Node A):

```bash
sudo gluster volume create nfs replica 2 transport tcp ns-4-1.softty.net:/nfs/data/docker/volumes ns-4-2.softty.net:/nfs/data/docker/volumes force
sudo gluster volume start nfs
```

Kiểm tra thông tin volume:

```bash
sudo gluster volume info
```

## 4. Mount Volume (Client)

Trên node cần sử dụng volume (cài đặt client trước):

```bash
sudo apt-get install glusterfs-client
mount -t glusterfs ns-4-1.softty.net:nfs /volumes
```
