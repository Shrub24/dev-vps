{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
  ];

  boot.initrd.kernelModules = [ "nvme" ];

  services.cloud-init = {
    enable = true;
    settings = {
      datasource_list = [
        "ConfigDrive"
        "Digitalocean"
      ];
      datasource.ConfigDrive = { };
      datasource.Digitalocean = { };
      cloud_init_modules = [
        "seed_random"
        "bootcmd"
        "write_files"
        "growpart"
        "resizefs"
        "set_hostname"
        "update_hostname"
        "set_password"
      ];
      cloud_config_modules = [
        "ssh-import-id"
        "keyboard"
        "runcmd"
        "disable_ec2_metadata"
      ];
      cloud_final_modules = [
        "write_files_deferred"
        "puppet"
        "chef"
        "ansible"
        "mcollective"
        "salt_minion"
        "reset_rmc"
        "scripts_per_once"
        "scripts_per_boot"
        "scripts_user"
        "ssh_authkey_fingerprints"
        "keys_to_console"
        "install_hotplug"
        "phone_home"
        "final_message"
      ];
    };
  };
}
