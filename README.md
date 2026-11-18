# Zero-Trust Virtualized SIEM/XDR & Storage Reference Architecture

Reference blueprint demonstrating a segmented, defense-in-depth infrastructure for centralized security telemetry, active intrusion prevention, and immutable network storage. 

> **OPSEC & Sanitization Notice:** This repository documents a generalized virtualized lab architecture. All network segments use RFC 5737 documentation ranges, and no production hostnames, internal ports, public endpoints, or hardware identifiers are disclosed.

---

## Logical Architecture & Data Flow

```mermaid
graph TD
    subgraph RemoteAccess["Zero-Trust Control Plane"]
        Operator["Admin Workstation"] -->|Encrypted Mesh Tunnel| MeshVPN["Zero-Trust Mesh VPN (Identity-Based ACLs)"]
    end

    subgraph VirtualizationCluster["Hypervisor Cluster (Proxmox VE)"]
        MeshVPN --> ReverseProxy["Internal Reverse Proxy (TLS Termination)"]
        ReverseProxy --> SIEM["Wazuh SIEM / XDR Manager"]
        ReverseProxy --> Dashboard["Monitoring & Telemetry UI"]
        
        MeshVPN --> IPS["CrowdSec IPS & Firewall Bouncer"]
        
        subgraph WorkloadVLAN["Isolated Workload Segment (RFC 5737: 192.0.2.0/24)"]
            AppContainers["Containerized Services (Docker / LXC)"]
            InternalDNS["Recursive DNS Sinkhole (Primary)"]
        end
    end

    subgraph FailoverTier["Redundancy & Out-of-Band Node"]
        SecondaryDNS["Recursive DNS Sinkhole (Secondary)"]
        HealthMonitor["Availability & Heartbeat Monitor"]
        InternalDNS <-->|State Sync| SecondaryDNS
    end

    subgraph StorageTier["Dedicated Storage & Backup Tier (NAS)"]
        NAS["Enterprise NAS (ZFS / RAID Array)"]
        HypervisorStorage["VM Disks & Container Volumes"]
        BackupVault["Immutable Snapshot & Backup Repository"]
        
        NAS --- HypervisorStorage
        NAS --- BackupVault
    end

    subgraph MonitoredAssets["Monitored Endpoints"]
        WinEndpoint["Windows Endpoint (EDR + Sysmon + Host Firewall)"] -->|Encrypted Agent Telemetry| SIEM
        LinuxEndpoint["Linux Servers (Auditd + FIM)"] -->|Encrypted Agent Telemetry| SIEM
    end

    VirtualizationCluster <-->|Dedicated Storage VLAN / NFS| StorageTier
    IPS -.->|Dynamic Blocklists| ReverseProxy
