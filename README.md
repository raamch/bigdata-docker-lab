# 🐘 BigData Cluster Setup — Bigtop 3.2.1 + Ambari 2.7.5

A 4-node Hadoop cluster running in Docker containers. No bare-metal, no drama. 🎉

**Stack:** Apache Ambari 2.7.5 · Bigtop 3.2.1 · Rocky Linux 8 | **Maintainer:** Ram CH

---

## 🖧 Cluster Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Machine (Docker Host)               │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  ambari-net (10.10.0.0/24)               │  │
│  │                                                          │  │
│  │  ┌─────────────────────────┐                            │  │
│  │  │  ambari-server          │  10.10.0.10  (8GB RAM)     │  │
│  │  │  ─────────────────────  │                            │  │
│  │  │  • Ambari Server        │◄──────────────────────┐   │  │
│  │  │  • NameNode             │                       │   │  │
│  │  │  • ResourceManager      │                       │   │  │
│  │  │  • HistoryServer        │                       │   │  │
│  │  └─────────────────────────┘                       │   │  │
│  │                                                    │   │  │
│  │  ┌─────────────────────────┐                       │   │  │
│  │  │  ambari-s1              │  10.10.0.11  (4GB RAM) │   │  │
│  │  │  ─────────────────────  │                       │   │  │
│  │  │  • SecondaryNameNode    │◄──── Ambari Agent ────┤   │  │
│  │  │  • DataNode             │       Heartbeat ♥     │   │  │
│  │  │  • NodeManager          │                       │   │  │
│  │  │  • ZooKeeper            │                       │   │  │
│  │  └─────────────────────────┘                       │   │  │
│  │                                                    │   │  │
│  │  ┌─────────────────────────┐                       │   │  │
│  │  │  ambari-s2              │  10.10.0.12  (4GB RAM) │   │  │
│  │  │  ─────────────────────  │                       │   │  │
│  │  │  • DataNode             │◄──── Ambari Agent ────┤   │  │
│  │  │  • NodeManager          │       Heartbeat ♥     │   │  │
│  │  │  • ZooKeeper            │                       │   │  │
│  │  └─────────────────────────┘                       │   │  │
│  │                                                    │   │  │
│  │  ┌─────────────────────────┐                       │   │  │
│  │  │  ambari-s3              │  10.10.0.13  (4GB RAM) │   │  │
│  │  │  ─────────────────────  │                       │   │  │
│  │  │  • DataNode             │◄──── Ambari Agent ────┘   │  │
│  │  │  • NodeManager          │       Heartbeat ♥         │  │
│  │  │  • ZooKeeper            │                            │  │
│  │  └─────────────────────────┘                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧰 Pre-requisites

Docker Desktop is required to run the cluster. It packages all 4 nodes as lightweight containers on your machine — no need for 4 physical servers.

Download and install Docker Desktop for your OS:

| OS | Download |
|---|---|
| Windows | https://docs.docker.com/desktop/install/windows-install/ |
| Mac | https://docs.docker.com/desktop/install/mac-install/ |
| Linux | https://docs.docker.com/desktop/install/linux-install/ |

After installing, launch Docker Desktop and verify it's running:
```bash
docker --version && docker-compose --version
```

---

## 🐳 Launching Containers

All you need is the `docker-compose.yml` file. No cloning, no building — Docker pulls everything automatically.

**1. Create a project folder and download the file into it:**

> 💡 **Windows users:** Open PowerShell as Administrator (right-click PowerShell → Run as Administrator)

```bash
# Create folder and navigate into it
mkdir bigdata-docker-lab
cd bigdata-docker-lab

# Download docker-compose.yml
# Windows (PowerShell)
curl -o docker-compose.yml https://raw.githubusercontent.com/raamch/bigdata-docker-lab/refs/heads/main/docker-compose.yml

# Mac / Linux
wget -O docker-compose.yml https://raw.githubusercontent.com/raamch/bigdata-docker-lab/refs/heads/main/docker-compose.yml
```

Or download directly from your browser and save into the folder:
```
https://raw.githubusercontent.com/raamch/bigdata-docker-lab/refs/heads/main/docker-compose.yml
```

**2. Fire up the containers:**

```bash
docker-compose up -d
```

Docker pulls the image on first run (~2GB — perfect time for a coffee ☕). All 4 containers start automatically.

> ⏳ Wait at least 30 seconds before proceeding — Ambari Server needs time to initialise.

**Handy Docker commands:**

| Command | Description |
|---|---|
| `docker-compose up -d` | Start all containers in the background |
| `docker-compose down` | Stop and destroy all containers |
| `docker-compose start/stop` | Start/stop without destroying containers |
| `docker stop ambari-s3` | Stop a single container |
| `docker start ambari-s3` | Start a single container |

---

## ⚙️ Creating the Cluster

Once containers are running, set up your Hadoop cluster in one of two ways:

### 🖱️ Manual — Learn by Doing
Open Ambari UI, login and follow the cluster creation wizard step by step. Great for understanding what goes where.
```
http://ambari-server:8080
```
Login: `admin / admin`

### ⚡ Auto Script — For the Creatively Lazy 🛋️
Ain't nobody got time for 15 wizard screens. One command, one coffee, one fully provisioned cluster.

```bash
docker exec ambari-server /usr/local/bin/setup-cluster.sh
```

The script submits the request and exits — installation continues in the background. Monitor progress here:
```
http://ambari-server:8080/#/main/background-operations
```
> ⏳ Installation takes 10-30 minutes depending on your machine spec. Services will appear red until complete — that's normal, not a fire. 🔥

> ⚠️ **To reinstall from scratch**, run these commands first to delete the existing cluster and blueprint, then rerun the script:
> ```bash
> # Stop all services first
> curl -s -u admin:admin -H "X-Requested-By: ambari" \
>      -X PUT http://localhost:8080/api/v1/clusters/ambari_cluster/services \
>      -d '{"RequestInfo":{"context":"Stop All Services"},"Body":{"ServiceInfo":{"state":"INSTALLED"}}}'
>
> # Wait a few minutes, then delete cluster and blueprint
> curl -s -u admin:admin -H "X-Requested-By: ambari" \
>      -X DELETE http://localhost:8080/api/v1/clusters/ambari_cluster
>
> curl -s -u admin:admin -H "X-Requested-By: ambari" \
>      -X DELETE http://localhost:8080/api/v1/blueprints/ambari_cluster
> ```

---

## 🗺️ Hosts File

Your system's hosts file acts as a personal phonebook — it maps hostnames to IP addresses so your browser knows where to find `ambari-server` without you having to remember or type IP addresses. Add the entries below once and forget about IPs forever.

**Windows** — Open Notepad as Administrator, then open:
`C:\Windows\System32\drivers\etc\hosts`

**Linux / Mac:**
```bash
sudo nano /etc/hosts
```

Add these lines:
```
# Ambari container hostnames
10.10.0.10  ambari-server.ambari.local  ambari-server
10.10.0.11  ambari-s1.ambari.local      ambari-s1
10.10.0.12  ambari-s2.ambari.local      ambari-s2
10.10.0.13  ambari-s3.ambari.local      ambari-s3
```

---

## 🌐 BigData Service Links & Credentials

All services run on `ambari-server`. Links become active once the service is installed and started via Ambari.

| Service | URL | Credentials |
|---|---|---|
| Ambari UI | http://ambari-server:8080 | admin / admin |
| HDFS NameNode | http://ambari-server:50070 | — |
| YARN Resource Manager | http://ambari-server:8088 | — |
| MapReduce Job History | http://ambari-server:19888 | — |
| HBase Master | http://ambari-server:16010 | — |
| Spark History Server | http://ambari-server:18080 | — |
| Spark Active Job | http://ambari-server:4040 | — (only when a job is running) |
| Oozie | http://ambari-server:11000 | — |
| Zeppelin | http://ambari-server:9995 | — |
| HiveServer2 | http://ambari-server:10002 | — |

**OS Credentials:**

| User | Password | Notes |
|---|---|---|
| `ambari` | `bigdatalab` | Standard user with sudo |
| `root` | `ambariroot` | Root access |

---

## 💻 Connecting to Containers in Command Mode

Connect to any container directly using Docker or SSH to run commands, explore the filesystem, or troubleshoot.

**Docker exec — quickest way:**
```bash
docker exec -it ambari-server bash
docker exec -it ambari-s1 bash
```

**SSH — when you need a proper terminal session:**

| Container | Command | Port |
|---|---|---|
| ambari-server | `ssh ambari@ambari-server -p 2221` | 2221 |
| ambari-s1 | `ssh ambari@ambari-s1 -p 2222` | 2222 |
| ambari-s2 | `ssh ambari@ambari-s2 -p 2223` | 2223 |
| ambari-s3 | `ssh ambari@ambari-s3 -p 2224` | 2224 |

Password for all: `bigdatalab`

---

## 💡 Tuning for Laptop

Running on a laptop with limited RAM? Edit the `mem_limit` values in `docker-compose.yml` before starting the containers. Two suggested options:

| Container | Option 1 | Option 2 |
|---|---|---|
| ambari-server | `4g` | `2g` |
| ambari-s1/s2/s3 | `2g` | `1g` |

---

## 🔧 Heads Up — Things You Should Know

**Blank Ambari Dashboard**
The metrics/graphs area on the dashboard appears blank. Ambari Metrics packages (`ambari-metrics-monitor` etc.) are not available in the Bigtop 3.2.1 repo and require a separate build (AMBARI-25918). All services work perfectly — the blank area is cosmetic only.

**Heartbeat Delay**
After stopping a container, Ambari continues showing it as alive for ~5 minutes while it waits for missed heartbeats. No cause for alarm.

**Cluster Wiped on docker-compose down**
PostgreSQL lives inside the container, not in an external volume. Running `docker-compose down` destroys the cluster config. Simply run `setup-cluster.sh` again after bringing containers back up.

---
"Every great engineer started as a confused beginner with a broken cluster and a browser full of Stack Overflow tabs. Welcome to the journey." 🚀
