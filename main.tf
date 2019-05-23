data "azurerm_resource_group" "test" {
  name = "groupe-terrafome"
}

data "azurerm_virtual_network" "test" {
  name                = "vent-ter"
  resource_group_name = "groupe-terrafome"
}

data "azurerm_subnet" "test" {
  name                 = "subnet-ter"
  resource_group_name  = "groupe-terrafome"
  virtual_network_name = "vent-ter"
}

resource "azurerm_public_ip" "test" {
  count                        = 3
  name                         = "ip${count.index}"
  location                     = "${data.azurerm_resource_group.test.location}"
  resource_group_name          = "${data.azurerm_resource_group.test.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "test" {
  count               = 3
  name                = "acctni${count.index}"
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "ip_conf${count.index}"
    subnet_id                     = "${data.azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"

    #load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.test.id}"]
  }
}

resource "azurerm_managed_disk" "test" {
  count                = 3
  name                 = "datadisk_existing_${count.index}"
  location             = "${data.azurerm_resource_group.test.location}"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "test" {
  count    = 3
  name     = "acctvm${count.index}"
  location = "${data.azurerm_resource_group.test.location}"

  #availability_set_id   = "${azurerm_availability_set.avset.id}"
  resource_group_name   = "${data.azurerm_resource_group.test.name}"
  network_interface_ids = ["${element(azurerm_network_interface.test.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmLTbm3lO5+VdKCeXp7xj/NMr11J+b8pRUTNulqXALHKuG0lKfbChjTuhef+0wZvZ6PHQgRI4uX9rkwjFfwnMM7MyGd8za6NuOmf9jSMEtut+eVMSsq+xxRXw8kAlGX4tiYYGQhX4Hyq/hvatFE8YrcGrZbQVneJWJqstOP3bczTEVhviCRYKU0ZHAxmMCvlALzP/o0migLzQpjn0B7QfIDhFX+HBN5UL0E6L76F2VC/Uo64x/YpWsyq8+nqHTKFwlyVrgXhUJEvTT2s/4A6JHPAoOHW+tsEHaYUsERwh4ehyoPgxcAKss/E5yZbqyvydgRt4zHai7ZND55iwuJgIf"
    }
  }
  tags {
    environment = "staging"
  }
}
