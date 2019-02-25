job "ethereum" {
  datacenters = ["[[env "DC"]]"
  type = "service"
  group "ethereum" {
    update {
      stagger = "10s"
      max_parallel = 1
    }
    count = "[[.ethereum.count]]"
    restart {
      attempts = 5
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    task "ethereum" {
      kill_timeout = "180s"
      logs {
        max_files     = 5
        max_file_size = 10
      }
      driver = "docker"
      config {
        args = [
          "--datadir=[[.ethereum.datadir]]",
          "--rpc",
          "--rpcaddr=[[.ethereum.rpcaddr]]",
          "--syncmode=[[.ethereum.syncmode]]",
          "--rpcvhosts=[[.ethereum.rpcvhosts]]",
          "--cache=[[.ethereum.cache]]",
	  "--maxpeers=[[.ethereum.maxpeers]]"
        ]
        volume_driver = "rexray"
        volumes            = [
          "${attr.consul.datacenter}-ethereum-${NOMAD_ALLOC_INDEX}:[[.ethereum.datadir]]"
        ]
        logging {
            type = "syslog"
            config {
              tag = "${NOMAD_JOB_NAME}${NOMAD_ALLOC_INDEX}"
            }   
        }
	network_mode       = "host"
        force_pull = true
        image = "ethereum/client-go:[[.ethereum.version]]"
        hostname = "${attr.unique.hostname}"
	dns_servers        = ["${attr.unique.network.ip-address}"]
        dns_search_domains = ["consul","service.consul","node.consul"]
      }
      resources {
        memory  = [[.ethereum.ram]]
        network {
          mbits = 10
          port "healthcheck" { static = "[[.ethereum.port]]" }
        } #network
      } #resources
      service {
        name = "ethereum"
        tags = ["[[.ethereum.version]]"]
        port = "healthcheck"
        check {
          name     = "ethereum-internal-port-check"
          port     = "healthcheck"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        } #check
      } #service
    } #task
  } #group
} #job
