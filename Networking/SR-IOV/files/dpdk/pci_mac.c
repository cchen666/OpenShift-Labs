#include <stdio.h>
#include <rte_ether.h>
#include <rte_eal.h>
#include <rte_ethdev.h>

int main(int argc, char **argv) {
    int ret;
    uint8_t nb_ports;
    struct rte_eth_dev_info dev_info;
    struct rte_ether_addr addr;
    char pci_addr_str[RTE_ETH_NAME_MAX_LEN];

    // Initialize DPDK Environment Abstraction Layer (EAL)
    ret = rte_eal_init(argc, argv);
    if (ret < 0) {
        rte_exit(EXIT_FAILURE, "Error with EAL initialization\n");
    }

    // Get the number of Ethernet devices
    nb_ports = rte_eth_dev_count_avail();
    printf("Number of available Ethernet devices: %u\n", nb_ports);

    // Loop through all available Ethernet devices
    for (uint8_t port = 0; port < nb_ports; port++) {
        // Retrieve the Ethernet device information
        rte_eth_dev_info_get(port, &dev_info);

        // Get and display PCI address
        if (rte_eth_dev_get_name_by_port(port, pci_addr_str) == 0) {
            printf("Device PCI: %s\n", pci_addr_str);
        } else {
            printf("Device PCI: Not Available\n");
        }

        // Get and display MAC address
        rte_eth_macaddr_get(port, &addr);
        printf("MAC Address: %02X:%02X:%02X:%02X:%02X:%02X\n",
                addr.addr_bytes[0], addr.addr_bytes[1],
                addr.addr_bytes[2], addr.addr_bytes[3],
                addr.addr_bytes[4], addr.addr_bytes[5]);
    }

    return 0;
}
