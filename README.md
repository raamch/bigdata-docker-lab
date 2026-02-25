# 🐘 BigData Cluster Setup using Bigtop 3.2.1 with Ambari 2.7.5

> A fully containerised 4-node Hadoop cluster for learning and experimenting with BigData technologies.
> No bare-metal drama. No "it works on my machine". Just Docker and good vibes. 🎉

**Maintainer:** Ram CH | **Stack:** Apache Ambari 2.7.5 · Bigtop 3.2.1 · Rocky Linux 8

---

## 🏗️ Cluster Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Machine                             │
│                      (Docker Host)                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  ambari-net (10.10.0.0/24)               │  │
│  │                                                          │  │
│  │  ┌─────────────────────────┐                            │  │
│  │  │  ambari-server          │  10.10.0.10  (4GB RAM)     │  │
│  │  │  ─────────────────────  │                            │  │
│  │  │  • Ambari Server        │◄──────────────────────┐   │  │
│  │  │  • NameNode             │                       │   │  │
│  │  │  • ResourceManager      │                       │   │  │
│  │  │  • HistoryServer        │                       │   │  │
│  │  └─────────────────────────┘                       │   │  │
│  │                                                    │   │  │
│  │  ┌─────────────────────────┐                       │   │  │
│  │  │  ambari-s1              │  10.10.0.11  (2GB RAM) │   │  │
│  │  │  ─────────────────────  │                       │   │  │
│  │  │  • SecondaryNameNode    │◄──── Ambari Agent ────┤   │  │
│  │  │  • DataNode             │       Heartbeat ♥     │   │  │
│  │  │  • NodeManager          │                       │   │  │
│  │  │  • ZooKeeper            │                       │   │  │
│  │  └─────────────────────────┘                       │   │  │
│  │                                                    │   │  │
│  │  ┌─────────────────────────┐                       │   │  │
│  │  │  ambari-s2              │  10.10.0.12  (2GB RAM) │   │  │
│  │  │  ─────────────────────  │                       │   │  │
│  │  │  • DataNode             │◄──── Ambari Agent ────┤   │  │
│  │  │  • NodeManager          │       Heartbeat ♥     │   │  │
│  │  │  • ZooKeeper            │                       │   │  │
│  │  └─────────────────────────┘                       │   │  │
│  │                                                    │   │  │
│  │  ┌─────────────────────────┐                       │   │  │
│  │  │  ambari-s3              │  10.10.0.13  (2GB RAM) │   │  │
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

### Docker

Docker is a platform that packages applications into lightweight, portable containers — think of it as a mini virtual machine, but faster and far less painful to set up. We use it here to run all 4 cluster nodes on your single machine without needing 4 physical servers. Your laptop is basically a data centre now. You're welcome. 😄

**Install Docker Desktop:**

| OS | Download Link |
|---|---|
| Windows | https://docs.docker.com/desktop/install/windows-install/ |
| Mac | https://docs.docker.com/desktop/install/mac-install/ |
| Linux | https://docs.docker.com/desktop/install/linux-install/ |

**Install Steps:**
1. Download Docker Desktop from the link for your OS above
2. Run the installer and follow the on-screen instructions
3. Launch Docker Desktop and wait for it to start (look for the whale icon 🐳 in your taskbar/menu bar)
4. Open a terminal and verify everything is working:
```bash
docker --version
docker-compose --version
```

---

## 🐳 Launching Your Containers

### Step 1 — Download docker-compose.yml

Download the `docker-compose.yml` file and save it into a folder on your machine (e.g. `bigdata-docker-lab`):

```
https://raw.githubusercontent.com/raamch/bigdata-docker-lab/refs/heads/main/docker-compose.yml
```

Right-click the link → Save As → choose your folder.

### Step 2 — Tune RAM (Optional but Recommended for Laptops 💻)

Running 4 containers simultaneously is hungry work. If you're on a laptop or a machine with limited RAM, open `docker-compose.yml` in any text editor and reduce the memory limits:

| Container | Default | Laptop Friendly |
|---|---|---|
| ambari-server | `mem_limit: 4g` | `mem_limit: 2g` |
| ambari-s1 | `mem_limit: 2g` | `mem_limit: 1g` |
| ambari-s2 | `mem_limit: 2g` | `mem_limit: 1g` |
| ambari-s3 | `mem_limit: 2g` | `mem_limit: 1g` |

### Step 3 — Open a Terminal

Open a terminal (Command Prompt or PowerShell on Windows, Terminal on Mac/Linux) and navigate to the folder where you saved `docker-compose.yml`:

```bash
cd C:\bigdata-docker-lab        # Windows
cd ~/bigdata-docker-lab         # Mac / Linux
```

### Step 4 — Fire It Up 🔥

```bash
docker-compose up -d
```

Docker will pull the image from Docker Hub on first run (about 2GB — perfect time for a coffee ☕). All 4 containers will start automatically.

> ⏳ **Wait at least 30 seconds** after the containers start before touching anything. Ambari Server needs time to wake up and initialise. Yes, we know you're excited. Deep breaths. 30 seconds. Go.

### Useful Docker Commands

| Command | What it does |
|---|---|
| `docker-compose up -d` | Start all containers in background |
| `docker-compose down` | Stop and destroy all containers |
| `docker-compose start` | Start previously stopped containers |
| `docker-compose stop` | Stop all containers (keeps data) |
| `docker ps` | List all running containers |
| `docker stop ambari-s3` | Stop a single container |
| `docker start ambari-s3` | Start a single stopped container |
| `docker logs ambari-server` | View server logs |

---

## ⚙️ Creating Your Cluster

Once your containers are running and Ambari is ready, you have two ways to create the cluster:

### 🖱️ The Manual Way

For those who enjoy clicking through wizards and want to understand every step of the cluster setup process. Open Ambari UI at `http://ambari-server:8080`, login with `admin / admin` and follow the cluster creation wizard — it will guide you through selecting services, assigning components to hosts, and configuring settings.

### ⚡ The Smart Way (Auto Script)

Why click through 15 wizard screens when a script can do it in seconds? This uses the Ambari Blueprint API to provision the entire cluster automatically.

```bash
docker exec ambari-server /usr/local/bin/setup-cluster.sh
```

> ⏳ The script submits the cluster creation request and exits immediately. The actual installation runs in the background and takes **10-15 minutes**. Monitor the progress at `http://ambari-server:8080` → click **Background Operations** button in the top right corner.

> ⚠️ If you need to reinstall from scratch, delete the existing cluster via the Ambari UI first, then run the script again.

---

## 🗺️ Hosts File Setup

To use `ambari-server` as a hostname in your browser (instead of typing IP addresses), add the following entries to your machine's hosts file.

### Windows
1. Search for **Notepad** → Right-click → **Run as Administrator** (this step is important — don't skip it!)
2. Open the file: `C:\Windows\System32\drivers\etc\hosts`
3. Add the following lines at the bottom:

```
10.10.0.10  ambari-server.ambari.local  ambari-server
10.10.0.11  ambari-s1.ambari.local      ambari-s1
10.10.0.12  ambari-s2.ambari.local      ambari-s2
10.10.0.13  ambari-s3.ambari.local      ambari-s3
```

4. Save the file

### Linux / Mac
1. Open a terminal and edit the hosts file:
```bash
sudo nano /etc/hosts
```
2. Add the following lines at the bottom:
```
10.10.0.10  ambari-server.ambari.local  ambari-server
10.10.0.11  ambari-s1.ambari.local      ambari-s1
10.10.0.12  ambari-s2.ambari.local      ambari-s2
10.10.0.13  ambari-s3.ambari.local      ambari-s3
```
3. Save and exit: `Ctrl+X` → `Y` → `Enter`

---

## 🔗 All the Links You'll Ever Need

| Service | URL | Credentials |
|---|---|---|
| **Ambari Web UI** | http://ambari-server:8080 | admin / admin |
| **HDFS NameNode UI** | http://ambari-server:50070 | — |
| **YARN Resource Manager** | http://ambari-server:8088 | — |
| **MapReduce Job History** | http://ambari-server:19888 | — |
| **HBase Master UI** | http://ambari-server:16010 | — |
| **Spark History Server** | http://ambari-server:18080 | — |
| **Spark Active Job UI** | http://ambari-server:4040 | — (only visible when a job is running) |
| **Oozie Web UI** | http://ambari-server:11000 | — |
| **Zeppelin Notebook** | http://ambari-server:9995 | — |
| **HiveServer2 Web UI** | http://ambari-server:10002 | — |

> 💡 Links only work after the respective service has been installed and started via Ambari. Don't panic if they don't load straight away — the service just isn't installed yet.

---

## 🔑 Credentials Cheat Sheet

Keep this handy. You'll be referring to it more than you'd like to admit.

| What | Username | Password |
|---|---|---|
| Ambari Web UI | `admin` | `admin` |
| OS Root User | `root` | `ambariroot` |
| OS Ambari User | `ambari` | `bigdatalab` |

---

## 🖥️ Connecting to Containers

**Using Docker exec (quickest way):**
```bash
# Connect to the server
docker exec -it ambari-server bash

# Connect to a slave node
docker exec -it ambari-s1 bash
docker exec -it ambari-s2 bash
docker exec -it ambari-s3 bash
```

Once inside a container, you can switch to the ambari user:
```bash
su - ambari
# Password: bigdatalab
```

**Using SSH** (make sure hosts file is configured first):

| Container | SSH Command | Port |
|---|---|---|
| ambari-server | `ssh ambari@ambari-server -p 2221` | 2221 |
| ambari-s1 | `ssh ambari@ambari-s1 -p 2222` | 2222 |
| ambari-s2 | `ssh ambari@ambari-s2 -p 2223` | 2223 |
| ambari-s3 | `ssh ambari@ambari-s3 -p 2224` | 2224 |

Password for all: `bigdatalab`

---

## 🐛 Known Issues & Quirks

**Blank Dashboard in Ambari UI**
The metrics/graphs area on the Ambari dashboard appears blank. This is because Ambari Metrics packages (`ambari-metrics-monitor`, `ambari-metrics-collector`) are not available in the Bigtop 3.2.1 repository and need to be built separately from source (see JIRA: AMBARI-25918). Everything else works perfectly fine — the blank area is purely cosmetic. Think of it as minimalist design. 🎨

**Heartbeat Delay**
If you stop a container (`docker stop ambari-s3`), Ambari will still show it as alive for about 5 minutes. This is normal — Ambari waits for several missed heartbeats before marking a host as down. No need to raise the alarm just yet.

**Services Show Red/Orange After Auto Setup**
After running `setup-cluster.sh`, services may appear red or orange in the Ambari UI. The installation is still running in the background — give it 10-15 minutes and they will turn green. Patience is a virtue, especially in BigData. 😅

**docker-compose down Wipes the Cluster**
Since the PostgreSQL database lives inside the container (not in an external volume), running `docker-compose down` will delete all cluster configuration. You will need to run `setup-cluster.sh` again after `docker-compose up -d`. Think of it as a fresh start every time. 🧹

---

*Happy clustering! May your DataNodes always be live, your jobs never fail, and your YARN queues never fill up. 🚀*
