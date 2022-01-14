---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Package defaults **(FREE SELF)**

Unless configuration is specified in the `/etc/gitlab/gitlab.rb` file,
the package will assume the defaults as noted below.

## Ports

See the table below for the list of ports that the Omnibus GitLab assigns
by default:

|      Component      | On by default | Communicates via | Alternative |              Connection port               |
|:-------------------:|:-------------:|:----------------:|:-----------:|:------------------------------------------:|
|    GitLab Rails     |      Yes      |       Port       |      X      |                 80 or 443                  |
|    GitLab Shell     |      Yes      |       Port       |      X      |                     22                     |
|     PostgreSQL      |      Yes      |      Socket      | Port (5432) |                     X                      |
|        Redis        |      Yes      |      Socket      | Port (6379) |                     X                      |
|        Puma         |      Yes      |      Socket      | Port (8080) |                     X                      |
|  GitLab Workhorse   |      Yes      |      Socket      | Port (8181) |                     X                      |
|    NGINX status     |      Yes      |       Port       |      X      |                    8060                    |
|     Prometheus      |      Yes      |       Port       |      X      |                    9090                    |
|    Node exporter    |      Yes      |       Port       |      X      |                    9100                    |
|   Redis exporter    |      Yes      |       Port       |      X      |                    9121                    |
| PostgreSQL exporter |      Yes      |       Port       |      X      |                    9187                    |
| PgBouncer exporter  |      No       |       Port       |      X      |                    9188                    |
|   GitLab Exporter   |      Yes      |       Port       |      X      |                    9168                    |
|  Sidekiq exporter   |      Yes      |       Port       |      X      |                    8082                    |
|    Puma exporter    |      No       |       Port       |      X      |                    8083                    |
|   Geo PostgreSQL    |      No       |      Socket      | Port (5431) |                     X                      |
|   Redis Sentinel    |      No       |       Port       |      X      |                   26379                    |
|   Incoming email    |      No       |       Port       |      X      |                    143                     |
|   Elastic search    |      No       |       Port       |      X      |                    9200                    |
|    GitLab Pages     |      No       |       Port       |      X      |                 80 or 443                  |
|   GitLab Registry   |      No*      |       Port       |      X      |              80, 443 or 5050               |
|   GitLab Registry   |      No       |       Port       |      X      |                    5000                    |
|        LDAP         |      No       |       Port       |      X      |   Depends on the component configuration   |
|      Kerberos       |      No       |       Port       |      X      |                8443 or 8088                |
|      OmniAuth       |      Yes      |       Port       |      X      |   Depends on the component configuration   |
|        SMTP         |      No       |       Port       |      X      |                    465                     |
|    Remote syslog    |      No       |       Port       |      X      |                    514                     |
|     Mattermost      |      No       |       Port       |      X      |                    8065                    |
|     Mattermost      |      No       |       Port       |      X      |                 80 or 443                  |
|      PgBouncer      |      No       |       Port       |      X      |                    6432                    |
|       Consul        |      No       |       Port       |      X      | 8300, 8301(UDP), 8500, 8600[^Consul-notes] |
|       Patroni       |      No       |       Port       |      X      |                    8008                    |
|     GitLab KAS      |      No       |       Port       |      X      |                    8150                    |
|       Gitaly        |      No       |       Port       |      X      |                    8075                    |

Legend:

- `Component` - Name of the component.
- `On by default` - Is the component running by default.
- `Communicates via` - How the component talks with the other components.
- `Alternative` - If it is possible to configure the component to use different type of communication. The type is listed with default port used in that case.
- `Connection port` - Port on which the component communicates.

GitLab also expects a file system to be ready for the storage of Git repositories
and various other files.

Note that if you are using NFS (Network File System), files will be carried
over a network which will require, based on implementation, ports `111` and
`2049` to be open.

NOTE:
In some cases, the GitLab Registry will be automatically enabled by default. Please see [our documentation](../packages/container_registry.md) for more details

 [^Consul-notes]: If using additional Consul functionality, more ports may need to be opened. See the [official documentation](https://www.consul.io/docs/install/ports#ports-table) for the list.
